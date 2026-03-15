//
//  RPCWebSocketManager.swift
//  AtollRPC
//
//  Manages WebSocket connection to Atoll's JSON-RPC server.
//

import Foundation

/// Manages the WebSocket connection and JSON-RPC message transport.
final class RPCWebSocketManager: NSObject, @unchecked Sendable {
    private let host: String
    private let port: Int
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private let queue = DispatchQueue(label: "com.atoll.rpc.websocket")
    
    private var pendingRequests: [String: CheckedContinuation<JSONRPCResponse, Error>] = [:]
    private let pendingLock = NSLock()
    
    var onNotification: ((String, AnyCodable?) -> Void)?
    var onDisconnect: (() -> Void)?
    
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0
    private var shouldReconnect = true
    
    init(host: String = AtollRPCDefaultHost, port: Int = AtollRPCDefaultPort) {
        self.host = host
        self.port = port
        self.session = URLSession(configuration: .default)
        super.init()
    }
    
    // MARK: - Connection Lifecycle
    
    func connect() async throws {
        guard !isConnected else { return }
        
        guard let url = URL(string: "ws://\(host):\(port)") else {
            throw AtollRPCError.connectionFailed(underlying: "Invalid URL")
        }
        
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()
        
        // Wait briefly to verify connection
        do {
            try await ping()
            isConnected = true
            reconnectAttempts = 0
            startReceiveLoop()
        } catch {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            throw AtollRPCError.atollNotReachable
        }
    }
    
    func disconnect() {
        shouldReconnect = false
        isConnected = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        // Fail all pending requests
        pendingLock.lock()
        let pending = pendingRequests
        pendingRequests.removeAll()
        pendingLock.unlock()
        
        for (_, continuation) in pending {
            continuation.resume(throwing: AtollRPCError.serviceUnavailable)
        }
    }
    
    var connectionState: Bool { isConnected }
    
    // MARK: - JSON-RPC Transport
    
    func sendRequest(method: String, params: AnyCodable? = nil) async throws -> JSONRPCResponse {
        guard isConnected, let task = webSocketTask else {
            throw AtollRPCError.atollNotReachable
        }
        
        let requestId = UUID().uuidString
        let request = JSONRPCRequest(method: method, params: params, id: requestId)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let message = URLSessionWebSocketTask.Message.data(data)
        try await task.send(message)
        
        return try await withCheckedThrowingContinuation { continuation in
            pendingLock.lock()
            pendingRequests[requestId] = continuation
            pendingLock.unlock()
            
            // Timeout after 15 seconds
            queue.asyncAfter(deadline: .now() + 15) { [weak self] in
                self?.pendingLock.lock()
                if let cont = self?.pendingRequests.removeValue(forKey: requestId) {
                    self?.pendingLock.unlock()
                    cont.resume(throwing: AtollRPCError.timeout)
                } else {
                    self?.pendingLock.unlock()
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func ping() async throws {
        guard let task = webSocketTask else {
            throw AtollRPCError.atollNotReachable
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func startReceiveLoop() {
        guard let task = webSocketTask, isConnected else { return }
        
        task.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.startReceiveLoop()
                
            case .failure(let error):
                self.handleDisconnection(error: error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .data(let d):
            data = d
        case .string(let s):
            data = Data(s.utf8)
        @unknown default:
            return
        }
        
        let decoder = JSONDecoder()
        
        // Try to decode as a response (has id)
        if let response = try? decoder.decode(JSONRPCResponse.self, from: data),
           let responseId = response.id {
            pendingLock.lock()
            let continuation = pendingRequests.removeValue(forKey: responseId)
            pendingLock.unlock()
            continuation?.resume(returning: response)
            return
        }
        
        // Try to decode as a notification (no id)
        if let notification = try? decoder.decode(JSONRPCNotification.self, from: data) {
            onNotification?(notification.method, notification.params)
            return
        }
    }
    
    private func handleDisconnection(error: Error) {
        isConnected = false
        webSocketTask = nil
        
        // Fail all pending requests
        pendingLock.lock()
        let pending = pendingRequests
        pendingRequests.removeAll()
        pendingLock.unlock()
        
        for (_, continuation) in pending {
            continuation.resume(throwing: AtollRPCError.connectionFailed(underlying: error.localizedDescription))
        }
        
        onDisconnect?()
        
        // Auto-reconnect
        if shouldReconnect && reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                Task {
                    try? await self?.connect()
                }
            }
        }
    }
    
    deinit {
        disconnect()
    }
}

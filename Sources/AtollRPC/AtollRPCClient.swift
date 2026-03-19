//
//  AtollRPCClient.swift
//  AtollRPC
//
//  Main client interface for third-party apps to communicate with Atoll via JSON-RPC WebSocket.
//

import Foundation

/// Main client class for interacting with Atoll via JSON-RPC over WebSocket.
///
/// Usage mirrors `AtollClient` from AtollExtensionKit but communicates over WebSocket
/// instead of XPC, allowing any third-party app to connect regardless of bundle ID.
@MainActor
public final class AtollRPCClient: @unchecked Sendable {
    /// Shared singleton instance (connects to localhost:9020)
    public static let shared = AtollRPCClient()
    
    private let connectionManager: RPCWebSocketManager
    private var authorizationCallbacks: [(Bool) -> Void] = []
    private var activityDismissalHandlers: [String: () -> Void] = [:]
    private var widgetDismissalHandlers: [String: () -> Void] = [:]
    private var notchDismissalHandlers: [String: () -> Void] = [:]
    private let encoder = JSONEncoder()
    
    /// Enable debug logging of requests and responses to stderr.
    public var debugLogging = false
    
    /// The bundle identifier used for authorization. Defaults to `Bundle.main.bundleIdentifier`.
    public var bundleIdentifier: String
    
    /// Initialize a new AtollRPCClient instance.
    /// - Parameters:
    ///   - host: WebSocket server host (default: localhost)
    ///   - port: WebSocket server port (default: 9020)
    ///   - bundleIdentifier: App bundle identifier for authorization
    public init(
        host: String = AtollRPCDefaultHost,
        port: Int = AtollRPCDefaultPort,
        bundleIdentifier: String? = nil
    ) {
        self.connectionManager = RPCWebSocketManager(host: host, port: port)
        self.bundleIdentifier = bundleIdentifier ?? Bundle.main.bundleIdentifier ?? "unknown"
        setupNotificationHandlers()
    }
    
    // MARK: - Connection
    
    /// Connect to the Atoll RPC server.
    /// Call this before making any requests. The client will auto-reconnect on disconnection.
    public func connect() async throws {
        try await connectionManager.connect()
    }
    
    /// Disconnect from the Atoll RPC server.
    public func disconnect() {
        connectionManager.disconnect()
    }
    
    /// Whether the client is currently connected to Atoll.
    public var isConnected: Bool {
        connectionManager.connectionState
    }
    
    // MARK: - Version Checks
    
    /// Get the installed Atoll version.
    public func getAtollVersion() async throws -> String {
        try await ensureConnected()
        let response = try await connectionManager.sendRequest(
            method: "atoll.getVersion",
            params: AnyCodable([:] as [String: Any])
        )
        try checkError(response)
        guard let result = response.result?.dictionary,
              let version = result["version"] as? String else {
            throw AtollRPCError.unknown("Invalid version response")
        }
        return version
    }
    
    /// Check version compatibility.
    public func checkCompatibility(minimumVersion: String = "1.0.0") async throws {
        let installedVersion = try await getAtollVersion()
        if !isVersionCompatible(installed: installedVersion, required: minimumVersion) {
            throw AtollRPCError.incompatibleVersion(required: minimumVersion, found: installedVersion)
        }
    }
    
    // MARK: - Authorization
    
    /// Request authorization to display live activities.
    public func requestAuthorization() async throws -> Bool {
        try await ensureConnected()
        let params = AnyCodable(["bundleIdentifier": bundleIdentifier])
        let response = try await connectionManager.sendRequest(
            method: "atoll.requestAuthorization",
            params: params
        )
        try checkError(response)
        guard let result = response.result?.dictionary,
              let authorized = result["authorized"] as? Bool else {
            throw AtollRPCError.unknown("Invalid authorization response")
        }
        return authorized
    }
    
    /// Check if the app is currently authorized.
    public func checkAuthorization() async throws -> Bool {
        try await ensureConnected()
        let params = AnyCodable(["bundleIdentifier": bundleIdentifier])
        let response = try await connectionManager.sendRequest(
            method: "atoll.checkAuthorization",
            params: params
        )
        try checkError(response)
        guard let result = response.result?.dictionary,
              let authorized = result["authorized"] as? Bool else {
            throw AtollRPCError.unknown("Invalid authorization response")
        }
        return authorized
    }
    
    /// Register a callback for authorization status changes.
    public func onAuthorizationChange(_ callback: @escaping (Bool) -> Void) {
        authorizationCallbacks.append(callback)
    }
    
    // MARK: - Live Activities
    
    /// Present a live activity.
    public func presentLiveActivity(_ descriptor: AtollLiveActivityDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Descriptor validation failed")
        }
        
        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw AtollRPCError.notAuthorized
        }
        
        try await sendDescriptor(method: "atoll.presentLiveActivity", descriptor: descriptor)
    }
    
    /// Update an existing live activity.
    public func updateLiveActivity(_ descriptor: AtollLiveActivityDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Descriptor validation failed")
        }
        try await sendDescriptor(method: "atoll.updateLiveActivity", descriptor: descriptor)
    }
    
    /// Dismiss a live activity.
    public func dismissLiveActivity(activityID: String) async throws {
        try await ensureConnected()
        let params = AnyCodable([
            "activityID": activityID,
            "bundleIdentifier": bundleIdentifier
        ])
        let response = try await connectionManager.sendRequest(
            method: "atoll.dismissLiveActivity",
            params: params
        )
        try checkError(response)
    }
    
    /// Register a callback for when an activity is dismissed.
    public func onActivityDismiss(activityID: String, callback: @escaping () -> Void) {
        activityDismissalHandlers[activityID] = callback
    }
    
    // MARK: - Lock Screen Widgets
    
    /// Present a lock screen widget.
    public func presentLockScreenWidget(_ descriptor: AtollLockScreenWidgetDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Widget descriptor validation failed")
        }
        
        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw AtollRPCError.notAuthorized
        }
        
        try await sendDescriptor(method: "atoll.presentLockScreenWidget", descriptor: descriptor)
    }
    
    /// Update an existing lock screen widget.
    public func updateLockScreenWidget(_ descriptor: AtollLockScreenWidgetDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Widget descriptor validation failed")
        }
        try await sendDescriptor(method: "atoll.updateLockScreenWidget", descriptor: descriptor)
    }
    
    /// Dismiss a lock screen widget.
    public func dismissLockScreenWidget(widgetID: String) async throws {
        try await ensureConnected()
        let params = AnyCodable([
            "widgetID": widgetID,
            "bundleIdentifier": bundleIdentifier
        ])
        let response = try await connectionManager.sendRequest(
            method: "atoll.dismissLockScreenWidget",
            params: params
        )
        try checkError(response)
    }
    
    /// Register a callback for when a widget is dismissed.
    public func onWidgetDismiss(widgetID: String, callback: @escaping () -> Void) {
        widgetDismissalHandlers[widgetID] = callback
    }
    
    // MARK: - Notch Experiences
    
    /// Present a notch experience.
    public func presentNotchExperience(_ descriptor: AtollNotchExperienceDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Notch descriptor validation failed")
        }
        
        let isAuthorized = try await checkAuthorization()
        guard isAuthorized else {
            throw AtollRPCError.notAuthorized
        }
        
        try await sendDescriptor(method: "atoll.presentNotchExperience", descriptor: descriptor)
    }
    
    /// Update a notch experience.
    public func updateNotchExperience(_ descriptor: AtollNotchExperienceDescriptor) async throws {
        guard descriptor.isValid else {
            throw AtollRPCError.invalidDescriptor(reason: "Notch descriptor validation failed")
        }
        try await sendDescriptor(method: "atoll.updateNotchExperience", descriptor: descriptor)
    }
    
    /// Dismiss a notch experience.
    public func dismissNotchExperience(experienceID: String) async throws {
        try await ensureConnected()
        let params = AnyCodable([
            "experienceID": experienceID,
            "bundleIdentifier": bundleIdentifier
        ])
        let response = try await connectionManager.sendRequest(
            method: "atoll.dismissNotchExperience",
            params: params
        )
        try checkError(response)
    }
    
    /// Register a callback for notch experience dismissal events.
    public func onNotchExperienceDismiss(experienceID: String, callback: @escaping () -> Void) {
        notchDismissalHandlers[experienceID] = callback
    }
    
    // MARK: - Private Helpers
    
    private func setupNotificationHandlers() {
        connectionManager.onNotification = { [weak self] method, params in
            Task { @MainActor [weak self] in
                self?.handleNotification(method: method, params: params)
            }
        }
    }
    
    private func handleNotification(method: String, params: AnyCodable?) {
        guard let dict = params?.dictionary else { return }
        
        switch method {
        case "atoll.authorizationDidChange":
            if let isAuthorized = dict["isAuthorized"] as? Bool {
                authorizationCallbacks.forEach { $0(isAuthorized) }
            }
            
        case "atoll.activityDidDismiss":
            if let activityID = dict["activityID"] as? String {
                activityDismissalHandlers[activityID]?()
                activityDismissalHandlers.removeValue(forKey: activityID)
            }
            
        case "atoll.widgetDidDismiss":
            if let widgetID = dict["widgetID"] as? String {
                widgetDismissalHandlers[widgetID]?()
                widgetDismissalHandlers.removeValue(forKey: widgetID)
            }
            
        case "atoll.notchExperienceDidDismiss":
            if let experienceID = dict["experienceID"] as? String {
                notchDismissalHandlers[experienceID]?()
                notchDismissalHandlers.removeValue(forKey: experienceID)
            }
            
        default:
            break
        }
    }
    
    private func ensureConnected() async throws {
        if !isConnected {
            try await connect()
        }
    }
    
    private func sendDescriptor<T: Codable>(method: String, descriptor: T) async throws {
        try await ensureConnected()
        let descriptorData = try encoder.encode(descriptor)
        guard let descriptorJSON = try JSONSerialization.jsonObject(with: descriptorData) as? [String: Any] else {
            throw AtollRPCError.invalidDescriptor(reason: "Failed to serialize descriptor")
        }
        let normalizedDescriptor = RPCPayloadNormalizer.normalizeDescriptor(descriptorJSON)
        if debugLogging {
            let jsonStr = String(data: descriptorData, encoding: .utf8) ?? "<binary>"
            print("[AtollRPC] \(method) → \(jsonStr.prefix(500))")
        }
        let params = AnyCodable(["descriptor": normalizedDescriptor])
        let response = try await connectionManager.sendRequest(method: method, params: params)
        try checkError(response)
    }
    
    private func checkError(_ response: JSONRPCResponse) throws {
        if let error = response.error {
            if debugLogging {
                print("[AtollRPC] Error: code=\(error.code) message=\(error.message)")
            }
            throw AtollRPCError.rpcError(
                code: error.code,
                message: error.message,
                data: error.data?.string
            )
        }
    }
    
    private func isVersionCompatible(installed: String, required: String) -> Bool {
        let installedParts = installed.split(separator: ".").compactMap { Int($0) }
        let requiredParts = required.split(separator: ".").compactMap { Int($0) }
        
        for (index, requiredPart) in requiredParts.enumerated() {
            guard index < installedParts.count else { return false }
            if installedParts[index] < requiredPart {
                return false
            } else if installedParts[index] > requiredPart {
                return true
            }
        }
        return true
    }
}

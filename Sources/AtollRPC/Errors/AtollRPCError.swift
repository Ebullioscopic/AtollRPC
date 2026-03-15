//
//  AtollRPCError.swift
//  AtollRPC
//
//  Error types for AtollRPC.
//

import Foundation

/// Errors that can occur when using AtollRPC.
public enum AtollRPCError: LocalizedError, Sendable {
    /// Atoll is not running or the WebSocket server is unreachable
    case atollNotReachable
    
    /// Atoll version is incompatible with this SDK version
    case incompatibleVersion(required: String, found: String)
    
    /// App is not authorized to use Atoll
    case notAuthorized
    
    /// Invalid descriptor data
    case invalidDescriptor(reason: String)
    
    /// WebSocket connection failed
    case connectionFailed(underlying: String)
    
    /// RPC service is unavailable
    case serviceUnavailable
    
    /// Activity limit exceeded
    case limitExceeded(limit: Int)
    
    /// RPC request timed out
    case timeout
    
    /// JSON-RPC error from server
    case rpcError(code: Int, message: String, data: String?)
    
    /// Unknown error
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .atollNotReachable:
            return "Atoll is not reachable. Ensure Atoll is running and the RPC server is enabled."
        case .incompatibleVersion(let required, let found):
            return "Atoll version \(found) is incompatible. Required version: \(required) or later."
        case .notAuthorized:
            return "App is not authorized to display live activities. User must grant permission in Atoll Settings."
        case .invalidDescriptor(let reason):
            return "Invalid descriptor: \(reason)"
        case .connectionFailed(let underlying):
            return "Failed to connect to Atoll: \(underlying)"
        case .serviceUnavailable:
            return "Atoll RPC service is temporarily unavailable. Please try again later."
        case .limitExceeded(let limit):
            return "Activity limit exceeded. Maximum \(limit) concurrent activities allowed."
        case .timeout:
            return "RPC request timed out."
        case .rpcError(_, let message, let data):
            if let data {
                return "RPC error: \(message) (\(data))"
            }
            return "RPC error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

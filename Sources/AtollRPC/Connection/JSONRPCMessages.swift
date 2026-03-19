//
//  JSONRPCMessages.swift
//  AtollRPC
//
//  JSON-RPC 2.0 message types for communication with Atoll.
//

import Foundation

/// JSON-RPC 2.0 request message.
struct JSONRPCRequest: Codable, Sendable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?
    let id: String
    
    init(method: String, params: AnyCodable? = nil, id: String) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }
}

/// JSON-RPC 2.0 response message.
struct JSONRPCResponse: Codable, Sendable {
    let jsonrpc: String
    let result: AnyCodable?
    let error: JSONRPCErrorObject?
    let id: String?
}

/// JSON-RPC 2.0 error object.
struct JSONRPCErrorObject: Codable, Sendable {
    let code: Int
    let message: String
    let data: AnyCodable?
}

/// JSON-RPC 2.0 notification (no id, no response expected).
struct JSONRPCNotification: Codable, Sendable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?
}

// MARK: - AnyCodable Wrapper

/// Type-erased Codable wrapper for JSON-RPC params/results.
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let number as NSNumber:
            // JSONSerialization surfaces numeric values as NSNumber.
            // Preserve numeric channels (e.g. color 0/1) as numbers, not booleans.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                try container.encode(number.boolValue)
            } else {
                try container.encode(number.doubleValue)
            }
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, .init(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    // MARK: - Convenience accessors
    
    var dictionary: [String: Any]? { value as? [String: Any] }
    var array: [Any]? { value as? [Any] }
    var string: String? { value as? String }
    var bool: Bool? { value as? Bool }
    var int: Int? { value as? Int }
    var double: Double? { value as? Double }
}

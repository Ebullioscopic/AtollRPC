//
//  RPCPayloadNormalizer.swift
//  AtollRPC
//
//  Normalizes descriptor payloads to stay compatible with Atoll RPC decoding.
//

import Foundation

enum RPCPayloadNormalizer {
    static func normalizeDescriptor(_ descriptor: [String: Any]) -> [String: Any] {
        var normalized = normalizeAny(descriptor) as? [String: Any] ?? descriptor

        // Keep parity with atoll-js behavior where metadata is always present.
        if normalized["metadata"] == nil {
            normalized["metadata"] = [String: String]()
        }

        return normalized
    }

    private static func normalizeAny(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            let normalizedDict = dict.mapValues { normalizeAny($0) }

            // CGSize-compatible conversion expected by Swift Codable on the host side.
            if normalizedDict.count == 2,
               let width = asFiniteDouble(normalizedDict["width"]),
               let height = asFiniteDouble(normalizedDict["height"]) {
                return [width, height]
            }

            return normalizedDict
        }

        if let array = value as? [Any] {
            return array.map { normalizeAny($0) }
        }

        return value
    }

    private static func asFiniteDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            let d = number.doubleValue
            return d.isFinite ? d : nil
        case let double as Double:
            return double.isFinite ? double : nil
        case let float as Float:
            let d = Double(float)
            return d.isFinite ? d : nil
        case let int as Int:
            return Double(int)
        default:
            return nil
        }
    }
}

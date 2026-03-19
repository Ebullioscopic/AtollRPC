//
//  AtollLiveActivityPriority.swift
//  AtollRPC
//
//  Priority levels for live activities.
//

import Foundation

/// Priority level for live activities.
public enum AtollLiveActivityPriority: String, Codable, Sendable, Hashable, Comparable {
    case low
    case normal
    case high
    case critical
    
    public static func < (lhs: AtollLiveActivityPriority, rhs: AtollLiveActivityPriority) -> Bool {
        lhs.rawPriority < rhs.rawPriority
    }

    private var rawPriority: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
}

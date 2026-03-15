//
//  AtollLiveActivityPriority.swift
//  AtollRPC
//
//  Priority levels for live activities.
//

import Foundation

/// Priority level for live activities.
public enum AtollLiveActivityPriority: Int, Codable, Sendable, Hashable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: AtollLiveActivityPriority, rhs: AtollLiveActivityPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

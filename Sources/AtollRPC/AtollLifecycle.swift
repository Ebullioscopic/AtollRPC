import Foundation

/// Atoll runtime lifecycle state.
public enum AtollLifecycleState: String, Sendable {
    case active
    case idle
}

/// Distributed notification names emitted by Atoll for lifecycle transitions.
public enum AtollLifecycleNotification {
    /// Emitted when Atoll has launched and is active.
    public static let didBecomeActive = Notification.Name("com.ebullioscopic.Atoll.lifecycle.didBecomeActive")

    /// Emitted when Atoll is terminating and transitioning to idle.
    public static let didBecomeIdle = Notification.Name("com.ebullioscopic.Atoll.lifecycle.didBecomeIdle")
}

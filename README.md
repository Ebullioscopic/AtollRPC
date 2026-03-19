# AtollRPC

A Swift SDK for third-party macOS apps to display **live activities**, **lock screen widgets**, and **notch experiences** in [Atoll](https://github.com/Ebullioscopic/Atoll) via JSON-RPC over WebSocket.

Unlike [AtollExtensionKit](https://github.com/Ebullioscopic/AtollExtensionKit) (which uses XPC and requires matching bundle IDs), AtollRPC allows **any** application to communicate with Atoll.

## Requirements

- macOS 13.0+
- Swift 6.0+
- Atoll with RPC server enabled (v1.0.0+)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Ebullioscopic/AtollRPC.git", from: "1.0.0")
]
```

## Quick Start

```swift
import AtollRPC

let client = AtollRPCClient.shared

// Connect to Atoll
try await client.connect()

// Request authorization
let authorized = try await client.requestAuthorization()

if authorized {
    // Present a live activity
    let activity = AtollLiveActivityDescriptor(
        id: "my-timer",
        title: "Timer",
        subtitle: "25:00",
        leadingIcon: .symbol(name: "timer"),
        accentColor: .blue,
        centerTextStyle: .inheritUser,
        sneakPeekConfig: .standard(duration: 3.0),
        sneakPeekTitle: "Timer",
        sneakPeekSubtitle: "25 min"
    )
    try await client.presentLiveActivity(activity)
}
```

## API Reference

### Connection

| Method | Description |
|--------|-------------|
| `connect()` | Connect to Atoll RPC server (auto-reconnects) |
| `disconnect()` | Disconnect from Atoll |
| `isConnected` | Check connection status |

### Authorization

| Method | Description |
|--------|-------------|
| `requestAuthorization()` | Request user authorization |
| `checkAuthorization()` | Check current authorization status |
| `onAuthorizationChange(_:)` | Register callback for authorization changes |

### Live Activities

| Method | Description |
|--------|-------------|
| `presentLiveActivity(_:)` | Show a live activity in the notch |
| `updateLiveActivity(_:)` | Update an existing live activity |
| `dismissLiveActivity(activityID:)` | Remove a live activity |
| `onActivityDismiss(activityID:callback:)` | Register dismissal callback |

### Lock Screen Widgets

| Method | Description |
|--------|-------------|
| `presentLockScreenWidget(_:)` | Show a lock screen widget |
| `updateLockScreenWidget(_:)` | Update an existing widget |
| `dismissLockScreenWidget(widgetID:)` | Remove a widget |
| `onWidgetDismiss(widgetID:callback:)` | Register dismissal callback |

### Notch Experiences

| Method | Description |
|--------|-------------|
| `presentNotchExperience(_:)` | Show rich notch content |
| `updateNotchExperience(_:)` | Update an existing experience |
| `dismissNotchExperience(experienceID:)` | Remove an experience |
| `onNotchExperienceDismiss(experienceID:callback:)` | Register dismissal callback |

## Architecture

AtollRPC communicates with Atoll over **JSON-RPC 2.0** on a **WebSocket** connection (`ws://localhost:9020`). The connection auto-reconnects with exponential backoff.

```
┌──────────────┐   JSON-RPC/WS   ┌─────────────┐
│  Your App    │◄───────────────►│    Atoll     │
│  (AtollRPC)  │  localhost:9020 │  (RPC Server)│
└──────────────┘                 └─────────────┘
```

## Wire Compatibility Notes

AtollRPC normalizes descriptor payloads before sending JSON-RPC requests to match
Atoll's Codable decoding expectations.

- `AtollLiveActivityPriority` is serialized as string values: `low`, `normal`, `high`, `critical`.
- Color channels (`red`, `green`, `blue`, `alpha`) are serialized as numeric values.
- Size dictionaries (`{ "width": ..., "height": ... }`) are normalized for host compatibility.
- Missing top-level descriptor metadata is normalized to `{}`.

These guarantees are applied automatically by the SDK.

## Error Handling

```swift
do {
    try await client.presentLiveActivity(descriptor)
} catch let error as AtollRPCError {
    switch error {
    case .atollNotReachable:
        print("Atoll is not running")
    case .notAuthorized:
        print("Please authorize in Atoll Settings")
    case .invalidDescriptor(let reason):
        print("Invalid descriptor: \(reason)")
    default:
        print(error.localizedDescription)
    }
}
```

## License

MIT License — see [LICENSE](LICENSE) for details.

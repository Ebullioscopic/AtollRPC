# Getting Started

## Installation

### Swift Package Manager

Add AtollRPC to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Ebullioscopic/AtollRPC.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

### Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 13.0+ |
| Swift | 6.0+ |
| Atoll | 1.0.0+ (with RPC server enabled) |

> **Note:** AtollRPC has **zero external dependencies** — it uses Foundation's `URLSessionWebSocketTask` for WebSocket communication.

## Your First Live Activity

```swift
import AtollRPC

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var status = "Ready"
    
    var body: some View {
        VStack(spacing: 16) {
            Text(status)
            
            Button("Show Timer") {
                Task { await showTimer() }
            }
        }
        .padding()
    }
    
    func showTimer() async {
        let client = AtollRPCClient.shared
        
        do {
            // 1. Connect to Atoll
            try await client.connect()
            
            // 2. Request authorization
            let authorized = try await client.requestAuthorization()
            guard authorized else {
                status = "Not authorized"
                return
            }
            
            // 3. Create a descriptor
            let activity = AtollLiveActivityDescriptor(
                id: "my-timer",
                title: "Timer",
                subtitle: "25:00 remaining",
                leadingIcon: .symbol(name: "timer"),
                accentColor: .blue
            )
            
            // 4. Present it
            try await client.presentLiveActivity(activity)
            status = "Timer shown!"
            
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
}
```

## Key Concepts

### Descriptors

All visual elements in Atoll are described using **descriptor** structs. Each descriptor is a complete snapshot of the UI:

| Descriptor | Use Case |
|------------|----------|
| `AtollLiveActivityDescriptor` | Compact activity in the Dynamic Island notch |
| `AtollLockScreenWidgetDescriptor` | Widget shown on the lock screen |
| `AtollNotchExperienceDescriptor` | Rich content surface inside the expanded notch |

### Workflow

```
Connect → Authorize → Present → Update → Dismiss
```

1. **Connect** — establish the WebSocket connection
2. **Authorize** — request permission from the user
3. **Present** — send a descriptor to display content
4. **Update** — send an updated descriptor with the same `id`
5. **Dismiss** — remove the content by `id`

### Singleton vs Custom Instance

```swift
// Singleton (connects to localhost:9020)
let client = AtollRPCClient.shared

// Custom instance (different port or host)
let client = AtollRPCClient(host: "localhost", port: 9021)
```

## Next Steps

- [Connection & Authorization](Connection-And-Authorization.md) — connection lifecycle and authorization flow
- [Live Activities](Live-Activities.md) — learn about all live activity options
- [Lock Screen Widgets](Lock-Screen-Widgets.md) — widget layouts and content
- [Notch Experiences](Notch-Experiences.md) — rich notch content surfaces

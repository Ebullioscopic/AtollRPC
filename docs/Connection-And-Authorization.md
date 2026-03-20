# Connection & Authorization

## Connection Lifecycle

AtollRPC communicates with Atoll over a WebSocket connection to `ws://localhost:9020`.

### Connecting

```swift
let client = AtollRPCClient.shared

// Connect to Atoll (throws if unreachable)
try await client.connect()

// Check connection status
if client.isConnected {
    print("Connected to Atoll")
}
```

> **Tip:** If you call any API method without connecting first, the client will auto-connect.

### Disconnecting

```swift
client.disconnect()
```

### Atoll Lifecycle Callbacks

Atoll emits distributed notifications when it launches and when it quits.
Use `onAtollLifecycleChange` to react to active/idle transitions:

```swift
client.onAtollLifecycleChange { state in
    switch state {
    case .active:
        print("Atoll became active")
    case .idle:
        print("Atoll became idle")
    }
}
```

### Auto-Reconnect

The client automatically reconnects with **exponential backoff** if the connection drops:

| Attempt | Delay |
|---------|-------|
| 1 | 1 second |
| 2 | 2 seconds |
| 3 | 4 seconds |
| 4 | 8 seconds |
| 5 | 16 seconds |

After 5 failed attempts, reconnection stops. Call `connect()` manually to retry.

### Version Checks

```swift
// Get Atoll version
let version = try await client.getAtollVersion()
print("Atoll v\(version)")

// Check compatibility
try await client.checkCompatibility(minimumVersion: "1.0.0")
```

## Authorization Flow

Third-party apps must be authorized by the user before displaying content in Atoll.

### Requesting Authorization

```swift
let authorized = try await client.requestAuthorization()
if authorized {
    // App is authorized — present content
} else {
    // User denied — show a message
}
```

When `requestAuthorization()` is called:
1. Atoll checks if the app is already authorized
2. If not, Atoll shows a prompt to the user
3. The result (`true`/`false`) is returned

### Checking Authorization

```swift
let isAuthorized = try await client.checkAuthorization()
```

This is a non-interactive check — it doesn't prompt the user.

### Authorization Change Callbacks

```swift
client.onAuthorizationChange { isAuthorized in
    if isAuthorized {
        print("App authorized!")
    } else {
        print("Authorization revoked")
    }
}
```

The callback fires when:
- The user grants or revokes authorization in Atoll Settings
- The feature toggle for third-party extensions changes

### Bundle Identifier

The `bundleIdentifier` is used to identify your app for authorization purposes:

```swift
// Default: uses Bundle.main.bundleIdentifier
let client = AtollRPCClient.shared

// Custom: specify explicitly
let client = AtollRPCClient(bundleIdentifier: "com.mycompany.myapp")
```

> **Important:** The bundle identifier is sent with every request. If your app doesn't have a valid bundle identifier (e.g., running from a script), set it explicitly.

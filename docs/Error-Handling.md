# Error Handling

## Error Types

All AtollRPC errors are instances of `AtollRPCError`:

```swift
public enum AtollRPCError: LocalizedError {
    case atollNotReachable
    case incompatibleVersion(required: String, found: String)
    case notAuthorized
    case invalidDescriptor(reason: String)
    case connectionFailed(underlying: String)
    case serviceUnavailable
    case limitExceeded(limit: Int)
    case timeout
    case rpcError(code: Int, message: String, data: String?)
    case unknown(String)
}
```

## Error Reference

| Error | When It Occurs | Recovery |
|-------|---------------|----------|
| `atollNotReachable` | Atoll is not running or the RPC server is disabled | Prompt user to launch Atoll |
| `incompatibleVersion` | Atoll version doesn't meet the minimum requirement | Prompt user to update Atoll |
| `notAuthorized` | The app hasn't been authorized by the user | Call `requestAuthorization()` |
| `invalidDescriptor` | Descriptor fails validation | Check descriptor properties |
| `connectionFailed` | WebSocket connection dropped | Will auto-reconnect; retry later |
| `serviceUnavailable` | Atoll is busy or restarting | Retry after a delay |
| `limitExceeded` | Too many concurrent activities/widgets | Dismiss some before presenting new ones |
| `timeout` | Request didn't receive a response within 15s | Check if Atoll is responsive |
| `rpcError` | Server returned a JSON-RPC error | Inspect `code` and `message` |

## Pattern: Error Handling

```swift
do {
    try await client.presentLiveActivity(descriptor)
} catch let error as AtollRPCError {
    switch error {
    case .atollNotReachable:
        showAlert("Please launch Atoll first")
    case .notAuthorized:
        let authorized = try? await client.requestAuthorization()
        if authorized == true {
            try? await client.presentLiveActivity(descriptor)
        }
    case .invalidDescriptor(let reason):
        print("Fix your descriptor: \(reason)")
    case .timeout:
        // Retry once
        try? await client.presentLiveActivity(descriptor)
    default:
        print(error.localizedDescription)
    }
}
```

## JSON-RPC Error Codes

When the server returns a `rpcError`, the `code` field follows JSON-RPC 2.0:

| Code | Meaning |
|------|---------|
| -32700 | Parse error (invalid JSON) |
| -32600 | Invalid request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |
| -32001 | Unauthorized |
| -32002 | Feature disabled |
| -32003 | Capacity exceeded |
| -32004 | Invalid descriptor |
| -32005 | Unsupported content |

## Debugging Tips

1. **Enable diagnostics logging in Atoll** — Settings → Extensions → Enable Diagnostics Logging
2. **Check Console.app** for `com.ebullioscopic.Atoll` log entries
3. **Verify Atoll is running** before connecting
4. **Validate descriptors** using the `.isValid` property before sending

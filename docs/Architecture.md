# Architecture

## Overview

```
┌─────────────────────────────────────────────┐
│                  Your App                    │
│  ┌────────────────────────────────────────┐  │
│  │          AtollRPCClient                │  │
│  │  ┌────────────────────────────────┐    │  │
│  │  │    RPCWebSocketManager         │    │  │
│  │  │  (URLSessionWebSocketTask)     │    │  │
│  │  └──────────────┬─────────────────┘    │  │
│  └─────────────────┼──────────────────────┘  │
└────────────────────┼─────────────────────────┘
                     │ WebSocket (ws://localhost:9020)
                     │ JSON-RPC 2.0
┌────────────────────┼─────────────────────────┐
│                Atoll App                      │
│  ┌─────────────────▼──────────────────────┐  │
│  │      ExtensionRPCServer               │  │
│  │  (Network.framework NWListener)       │  │
│  │  ┌──────────────────────────────────┐ │  │
│  │  │    ExtensionRPCService           │ │  │
│  │  │    (JSON-RPC method routing)     │ │  │
│  │  └──────────────┬───────────────────┘ │  │
│  └─────────────────┼─────────────────────┘  │
│                    │                         │
│   ┌────────────────┼──────────────────────┐  │
│   │        Extension Managers             │  │
│   │  • ExtensionLiveActivityManager      │  │
│   │  • ExtensionLockScreenWidgetManager  │  │
│   │  • ExtensionNotchExperienceManager   │  │
│   │  • ExtensionAuthorizationManager     │  │
│   └───────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

## JSON-RPC 2.0 Protocol

All communication uses [JSON-RPC 2.0](https://www.jsonrpc.org/specification):

### Request (Client → Server)

```json
{
    "jsonrpc": "2.0",
    "method": "atoll.presentLiveActivity",
    "params": {
        "descriptor": { ... }
    },
    "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Response (Server → Client)

**Success:**
```json
{
    "jsonrpc": "2.0",
    "result": { "success": true },
    "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Error:**
```json
{
    "jsonrpc": "2.0",
    "error": {
        "code": -32001,
        "message": "Not authorized"
    },
    "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Notification (Server → Client, no `id`)

```json
{
    "jsonrpc": "2.0",
    "method": "atoll.activityDidDismiss",
    "params": {
        "bundleIdentifier": "com.example.myapp",
        "activityID": "my-timer"
    }
}
```

## Available Methods

### System

| Method | Direction | Description |
|--------|-----------|-------------|
| `atoll.getVersion` | Client → Server | Get Atoll version |

### Authorization

| Method | Direction | Description |
|--------|-----------|-------------|
| `atoll.requestAuthorization` | Client → Server | Request user authorization |
| `atoll.checkAuthorization` | Client → Server | Check current authorization |
| `atoll.authorizationDidChange` | Server → Client | Authorization status changed |

### Live Activities

| Method | Direction | Description |
|--------|-----------|-------------|
| `atoll.presentLiveActivity` | Client → Server | Show a live activity |
| `atoll.updateLiveActivity` | Client → Server | Update a live activity |
| `atoll.dismissLiveActivity` | Client → Server | Dismiss a live activity |
| `atoll.activityDidDismiss` | Server → Client | Activity was dismissed |

### Lock Screen Widgets

| Method | Direction | Description |
|--------|-----------|-------------|
| `atoll.presentLockScreenWidget` | Client → Server | Show a widget |
| `atoll.updateLockScreenWidget` | Client → Server | Update a widget |
| `atoll.dismissLockScreenWidget` | Client → Server | Dismiss a widget |
| `atoll.widgetDidDismiss` | Server → Client | Widget was dismissed |

### Notch Experiences

| Method | Direction | Description |
|--------|-----------|-------------|
| `atoll.presentNotchExperience` | Client → Server | Show a notch experience |
| `atoll.updateNotchExperience` | Client → Server | Update a notch experience |
| `atoll.dismissNotchExperience` | Client → Server | Dismiss a notch experience |
| `atoll.notchExperienceDidDismiss` | Server → Client | Experience was dismissed |

## Transport Details

| Property | Value |
|----------|-------|
| Protocol | WebSocket (RFC 6455) |
| Default URL | `ws://localhost:9020` |
| Message format | JSON-RPC 2.0 over text frames |
| Ping/Pong | Auto-reply enabled |
| Request timeout | 15 seconds |
| Max reconnect attempts | 5 |
| Reconnect strategy | Exponential backoff (1s, 2s, 4s, 8s, 16s) |

## Payload Normalization

Before sending a descriptor, AtollRPC applies compatibility normalization to align
Swift model encoding with Atoll's decoder expectations:

- Priority is emitted as string enum values (`low`, `normal`, `high`, `critical`).
- Numeric color channels remain numeric (not boolean-coerced).
- Size dictionaries are normalized for host-side Codable compatibility.
- Missing descriptor metadata is emitted as an empty object.

This is automatic and does not require app-side configuration.

## Comparison with AtollExtensionKit (XPC)

| Feature | AtollExtensionKit | AtollRPC |
|---------|-------------------|----------|
| Transport | XPC | WebSocket |
| Bundle ID requirement | Must match | Any app |
| API surface | Identical | Identical |
| Dependencies | None | None |
| Latency | ~1ms | ~5ms |
| Cross-language | Swift only | Swift, JS/TS, any WebSocket client |
| Server notifications | XPC callbacks | JSON-RPC notifications |

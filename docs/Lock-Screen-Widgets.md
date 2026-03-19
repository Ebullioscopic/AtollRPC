# Lock Screen Widgets

Lock screen widgets appear as floating UI elements when the screen is locked.

## Basic Usage

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "my-widget",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    content: [
        .text("Hello", font: .system(size: 14, weight: .semibold), color: .white)
    ]
)
try await client.presentLockScreenWidget(widget)
```

## Layout Styles

| Style | Default Size | Description |
|-------|-------------|-------------|
| `.inline` | 200 × 48 | Horizontal strip |
| `.circular` | 100 × 100 | Round widget |
| `.card` | 220 × 120 | Rectangular card |
| `.custom` | 150 × 80 | Freeform dimensions |

```swift
layoutStyle: .card,
size: CGSize(width: 270, height: 160)
```

## Position

```swift
position: AtollWidgetPosition(
    alignment: .center,         // .leading, .center, .trailing
    verticalOffset: 110,        // -400 to 400
    horizontalOffset: 0,        // -600 to 600
    clampMode: .safeRegion      // .safeRegion, .relaxed, .unconstrained
)
```

## Materials

| Material | Description |
|----------|-------------|
| `.frosted` | Blurred frosted glass |
| `.liquid` | Liquid glass effect (use with `liquidGlassVariant`) |
| `.solid` | Opaque background |
| `.semiTransparent` | Semi-transparent |
| `.clear` | Fully transparent |

## Content Elements

### Text

```swift
.text("CPU Usage", font: .system(size: 14, weight: .semibold), color: .white, alignment: .leading)
```

### Icon

```swift
.icon(.symbol(name: "bolt.fill"), tint: .yellow)
```

### Progress

```swift
.progress(.bar(width: 190, height: 4), value: 0.76, color: .green)
```

### Gauge

```swift
.gauge(value: 0.55, minValue: 0, maxValue: 1, style: .circular, color: .accent)
```

### Graph

```swift
.graph(data: [0.2, 0.5, 0.8, 0.3, 0.6], color: .blue, size: CGSize(width: 150, height: 40))
```

### Spacer & Divider

```swift
.spacer(height: 8)
.divider(color: .white, thickness: 1)
```

### Web View

```swift
.webView(AtollWidgetWebContentDescriptor(
    html: "<html>...</html>",
    preferredHeight: 140,
    isTransparent: true,
    allowLocalhostRequests: false,
    allowRemoteRequests: false
))
```

Use `allowLocalhostRequests` only for localhost/127.0.0.1 development servers and
`allowRemoteRequests` only when external hosts (for example CDN assets) are required.

## Appearance Options

```swift
appearance: AtollWidgetAppearanceOptions(
    tintColor: .white,
    tintOpacity: 0.06,
    enableGlassHighlight: true,
    contentInsets: AtollWidgetContentInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
    border: AtollWidgetBorderStyle(color: .white, opacity: 0.35, width: 1),
    shadow: AtollWidgetShadowStyle(color: .black, opacity: 0.45, radius: 18),
    liquidGlassVariant: AtollLiquidGlassVariant(12)  // 0–19
)
```

## Full Example: Card Widget with Liquid Glass

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "charging-widget",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    layoutStyle: .card,
    position: .init(alignment: .leading, verticalOffset: -40, horizontalOffset: 50),
    size: CGSize(width: 270, height: 160),
    material: .liquid,
    appearance: .init(
        tintColor: .white,
        tintOpacity: 0.06,
        enableGlassHighlight: true,
        liquidGlassVariant: AtollLiquidGlassVariant(12)
    ),
    cornerRadius: 24,
    content: [
        .text("Charging", font: .system(size: 14, weight: .semibold), color: .white),
        .spacer(height: 6),
        .progress(.bar(width: 190, height: 4), value: 0.76, color: .green),
        .spacer(height: 8),
        .gauge(value: 0.76, style: .circular, color: .green),
    ],
    accentColor: .accent,
    dismissOnUnlock: true,
    priority: .normal
)
```

## Update & Dismiss

```swift
// Update
try await client.updateLockScreenWidget(updatedWidget)

// Dismiss
try await client.dismissLockScreenWidget(widgetID: "charging-widget")

// Callback
client.onWidgetDismiss(widgetID: "charging-widget") {
    print("Widget dismissed")
}
```

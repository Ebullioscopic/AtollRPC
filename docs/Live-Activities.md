# Live Activities

Live activities appear as compact content inside Atoll's Dynamic Island notch — the area around the camera notch on supported MacBooks.

## Basic Structure

```swift
let activity = AtollLiveActivityDescriptor(
    id: "unique-id",               // Must be unique per app
    title: "Title",                // Shown in the center
    subtitle: "Subtitle",          // Optional, below the title
    leadingIcon: .symbol(name: "timer"),  // Left-side icon
    accentColor: .blue             // Tint color
)
try await client.presentLiveActivity(activity)
```

## Priority Levels

| Priority | Value | Behavior |
|----------|-------|----------|
| `.low` | 0 | Yields to other activities |
| `.normal` | 1 | Default priority |
| `.high` | 2 | Takes precedence over normal activities |
| `.critical` | 3 | Always shown, even over high-priority content |

## Leading Icons

```swift
// SF Symbol
.symbol(name: "timer", size: 16, weight: .regular)

// Image data (PNG/JPEG)
.image(data: imageData, size: CGSize(width: 20, height: 20), cornerRadius: 4)

// App icon from bundle identifier
.appIcon(bundleIdentifier: "com.apple.Safari", size: CGSize(width: 20, height: 20))

// Lottie animation
.lottie(animationData: lottieData, size: CGSize(width: 24, height: 24))

// No icon
.none
```

## Trailing Content

The right side of the activity supports various content types. **Mutually exclusive with `progressIndicator`** when the indicator is renderable.

### Text

```swift
trailingContent: .text("LIVE", font: .system(size: 12, weight: .medium))
```

### Marquee (scrolling text)

```swift
trailingContent: .marquee(
    "Breaking news • Markets rally • Weather clears…",
    font: .system(size: 12, weight: .semibold),
    minDuration: 0.6
)
```

### Countdown

```swift
trailingContent: .countdownText(
    targetDate: Date().addingTimeInterval(25 * 60),
    font: .monospacedDigit(size: 13, weight: .semibold)
)
```

### Icon

```swift
trailingContent: .icon(.symbol(name: "checkmark.circle.fill"))
```

### Spectrum (music visualizer)

```swift
trailingContent: .spectrum(color: .accent)
```

### None

```swift
trailingContent: .none  // Use with progressIndicator
```

## Progress Indicators

When `trailingContent` is `.none`, you can show a progress indicator:

```swift
// Circular ring
progressIndicator: .ring(diameter: 24, strokeWidth: 3, color: .blue)

// Horizontal bar
progressIndicator: .bar(width: 90, height: 4, cornerRadius: 2)

// Percentage text (e.g., "47%")
progressIndicator: .percentage()

// Countdown timer (mm:ss)
progressIndicator: .countdown()
```

Set progress value (0.0 to 1.0):

```swift
progress: 0.47
```

## Sneak Peek Configuration

Controls how the activity previews when it first appears or updates:

```swift
// Default (enabled, respects user preferences)
sneakPeekConfig: .default

// Disabled
sneakPeekConfig: .disabled

// Custom
sneakPeekConfig: AtollSneakPeekConfig(
    enabled: true,
    duration: 3.0,           // seconds
    style: .standard,        // .standard or .inline
    showOnUpdate: true       // trigger on updates, not just presentation
)
```

Override the sneak peek text:

```swift
sneakPeekTitle: "Download",
sneakPeekSubtitle: "47% complete"
```

## Center Text Style

```swift
// Follow user's Atoll preference
centerTextStyle: .inheritUser

// Force standard stacked layout
centerTextStyle: .standard

// Force inline marquee layout
centerTextStyle: .inline
```

## Music Coexistence

```swift
// Allow alongside music playback
allowsMusicCoexistence: true

// Replace music display (exclusive)
allowsMusicCoexistence: false
```

## Full Example: Download Progress

```swift
let activity = AtollLiveActivityDescriptor(
    id: "download-v2",
    priority: .low,
    title: "Downloading",
    subtitle: "update-pkg-v2.dmg",
    leadingIcon: .symbol(name: "arrow.down.circle.fill"),
    trailingContent: .none,
    progressIndicator: .percentage(),
    progress: 0.47,
    accentColor: .blue,
    allowsMusicCoexistence: true,
    centerTextStyle: .inheritUser,
    sneakPeekConfig: .standard(duration: 3.0),
    sneakPeekTitle: "Download",
    sneakPeekSubtitle: "47% complete"
)

try await client.presentLiveActivity(activity)
```

## Update & Dismiss

```swift
// Update: send same id with new values
activity.progress = 0.75
try await client.updateLiveActivity(activity)

// Dismiss
try await client.dismissLiveActivity(activityID: "download-v2")

// Dismissal callback
client.onActivityDismiss(activityID: "download-v2") {
    print("Activity was dismissed")
}
```

# Notch Experiences

Notch experiences provide rich content surfaces inside the Dynamic Island. They support two configurations: **Tab** (shown when the notch is open) and **Minimalistic** (shown as a compact overlay).

## Tab Configuration

A tab appears as a named section inside the expanded notch:

```swift
let experience = AtollNotchExperienceDescriptor(
    id: "my-dashboard",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    tab: .init(
        title: "Dashboard",
        iconSymbolName: "gauge.with.dots.needle.33percent",
        preferredHeight: 200,
        sections: [
            AtollNotchContentSection(
                id: "metrics",
                title: "System",
                layout: .metrics,
                elements: [
                    .text("CPU", font: .system(size: 12), color: .white),
                    .text("21%", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                    .text("RAM", font: .system(size: 12), color: .white),
                    .text("8.3 GB", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                ]
            )
        ],
        allowWebInteraction: false
    )
)
try await client.presentNotchExperience(experience)
```

### Tab Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | `String` | Tab title (required) |
| `iconSymbolName` | `String?` | SF Symbol for the tab icon |
| `badgeIcon` | `AtollIconDescriptor?` | Badge overlay on the tab icon |
| `preferredHeight` | `CGFloat?` | Height (160–420 points) |
| `sections` | `[AtollNotchContentSection]` | Content sections (max 6) |
| `webContent` | `AtollWidgetWebContentDescriptor?` | HTML/CSS/JS content |
| `allowWebInteraction` | `Bool` | Enable mouse/keyboard in web content |
| `footnote` | `String?` | Footer text (max 140 chars) |
| `appearance` | `AtollWidgetAppearanceOptions?` | Visual customization |

## Minimalistic Configuration

A minimalistic experience replaces the default notch content with a compact overlay:

```swift
let experience = AtollNotchExperienceDescriptor(
    id: "mini-status",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    minimalistic: .init(
        headline: "Focus Mode",
        subtitle: "Deep work session",
        sections: [
            AtollNotchContentSection(
                layout: .metrics,
                elements: [
                    .text("Time", font: .system(size: 12), color: .white),
                    .text("1:42", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                ]
            )
        ],
        layout: .metrics,
        hidesMusicControls: false
    )
)
```

### Minimalistic Properties

| Property | Type | Description |
|----------|------|-------------|
| `headline` | `String?` | Header text (max 80 chars) |
| `subtitle` | `String?` | Subtitle (max 120 chars) |
| `sections` | `[AtollNotchContentSection]` | Content sections (max 3) |
| `webContent` | `AtollWidgetWebContentDescriptor?` | HTML/CSS/JS content |
| `layout` | `.stack` / `.metrics` / `.custom` | Section arrangement |
| `hidesMusicControls` | `Bool` | Whether to hide music controls |

## Combined (Tab + Minimalistic)

You can provide both a tab and minimalistic configuration. The tab appears when the notch is expanded, and the minimalistic view replaces the default closed-notch content:

```swift
let experience = AtollNotchExperienceDescriptor(
    id: "flight-tracker",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    tab: .init(
        title: "Flight",
        iconSymbolName: "airplane.circle.fill",
        preferredHeight: 220,
        sections: [],
        webContent: .init(html: flightHTML, preferredHeight: 230, isTransparent: true),
        allowWebInteraction: false
    ),
    minimalistic: .init(
        headline: "SFO → JFK",
        subtitle: "In flight",
        sections: [],
        layout: .stack,
        hidesMusicControls: false
    )
)
```

## Content Sections

Sections organize content within tabs and minimalistic views:

```swift
AtollNotchContentSection(
    id: "section-1",                    // Optional unique ID
    title: "System Metrics",            // Optional section title
    subtitle: "Real-time monitoring",   // Optional subtitle
    layout: .metrics,                   // .stack, .columns, .metrics
    elements: [
        // Same element types as Lock Screen Widgets
        .text("CPU", font: .system(size: 12), color: .white),
        .gauge(value: 0.45, style: .linear, color: .green),
    ]
)
```

### Section Limits

| Constraint | Limit |
|------------|-------|
| Sections per tab | 6 |
| Sections per minimalistic | 3 |
| Elements per section | 6 |
| Title length | 80 characters |
| Subtitle length | 160 characters |

## Web Content

Both tab and minimalistic configs support HTML/CSS/JS content for rich visualizations:

```swift
webContent: AtollWidgetWebContentDescriptor(
    html: """
    <html>
    <body style="margin:0; background:transparent; color:white;">
        <canvas id="chart"></canvas>
        <script>/* your chart code */</script>
    </body>
    </html>
    """,
    preferredHeight: 200,       // 40–420
    isTransparent: true,
    allowLocalhostRequests: false,
    maximumContentWidth: 400    // optional, 40–640
)
```

> **Security:** `allowLocalhostRequests` defaults to `false` (for localhost/127.0.0.1 only) and `allowRemoteRequests` defaults to `false` (for external hosts/CDNs). Enable either one only when required.

## Update & Dismiss

```swift
// Update
try await client.updateNotchExperience(updatedExperience)

// Dismiss
try await client.dismissNotchExperience(experienceID: "flight-tracker")

// Callback
client.onNotchExperienceDismiss(experienceID: "flight-tracker") {
    print("Experience dismissed")
}
```

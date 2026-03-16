import SwiftUI
import AtollRPC

struct ContentView: View {

    // MARK: - State

    @State private var isConnected = false
    @State private var isAuthorized = false
    @State private var status = "Idle"

    @State private var demoProgress: Double = 0.35
    @State private var flightProgress: Double = 0.12

    private let client = AtollRPCClient.shared

    // IDs
    private let downloadID   = "rpc-sample-download"
    private let pomodoroID   = "rpc-sample-pomodoro"
    private let newsID       = "rpc-sample-news"
    private let flightID     = "rpc-sample-flight"
    private let spectrumID   = "rpc-sample-spectrum"
    private let indicatorID  = "rpc-sample-indicator"
    private let widgetInline = "rpc-sample-widget-inline"
    private let widgetCard   = "rpc-sample-widget-card"
    private let widgetCircle = "rpc-sample-widget-circular"
    private let widgetWeb    = "rpc-sample-widget-web"
    private let widgetWebLocalhost = "rpc-sample-widget-web-localhost"
    private let notchTab     = "rpc-sample-notch-tab"
    private let notchMini    = "rpc-sample-notch-mini"
    private let notchCombo   = "rpc-sample-notch-combo"
    private let notchFlightSimple = "rpc-sample-notch-flight-simple"
    private let localhostWidgetURL = "http://localhost:5173"

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                Text("AtollRPC — Full API Playground")
                    .font(.title2)
                    .bold()

                Text("Status: \(status)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                connectionSection

                Divider()

                liveActivitiesSection

                Divider()

                widgetsSection

                Divider()

                notchExperiencesSection
            }
            .padding()
        }
        .onAppear {
            registerCallbacks()
        }
    }

    // MARK: - Callbacks

    private func registerCallbacks() {
        client.onAuthorizationChange { authorized in
            Task { @MainActor in
                self.isAuthorized = authorized
                self.status = authorized ? "Authorization changed ✅" : "Authorization revoked ❌"
            }
        }

        client.onActivityDismiss(activityID: flightID) {
            Task { @MainActor in
                self.status = "Flight live activity dismissed by user"
            }
        }

        client.onNotchExperienceDismiss(experienceID: notchCombo) {
            Task { @MainActor in
                self.status = "Notch experience dismissed: Combined"
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        GroupBox("Connection & Authorization") {
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                }

                Button("Connect to Atoll") {
                    Task { await connectToAtoll() }
                }

                Button("Request Authorization") {
                    Task { await requestAuthorization() }
                }
                .disabled(!isConnected)

                Button("Check Authorization") {
                    Task { await checkAuthorization() }
                }
                .disabled(!isConnected)

                Text(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")
                    .font(.caption)
                    .foregroundColor(isAuthorized ? .green : .red)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Live Activities Section

    private var liveActivitiesSection: some View {
        GroupBox("Live Activities") {
            VStack(spacing: 10) {
                Text("Demo progress: \(Int(demoProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Present • Download (percentage)") {
                    Task { await presentDownload() }
                }

                Button("Update • Download (+10%)") {
                    Task { await updateDownload() }
                }

                Button("Present • Pomodoro (countdown trailing)") {
                    Task { await presentPomodoro() }
                }

                Button("Present • News Marquee") {
                    Task { await presentNewsMarquee() }
                }

                Button("Present • Spectrum Trailing") {
                    Task { await presentSpectrum() }
                }

                Divider().padding(.vertical, 6)

                Text("Flight progress: \(Int(flightProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Present • Flight (text trailing)") {
                    Task { await presentFlight() }
                }

                Button("Update • Flight (+10%)") {
                    Task { await updateFlight() }
                }

                Divider().padding(.vertical, 6)

                Button("Present • Indicator Ring") {
                    Task { await presentIndicatorRing() }
                }

                Button("Present • Indicator Bar") {
                    Task { await presentIndicatorBar() }
                }

                Divider().padding(.vertical, 6)

                Button("Dismiss All Live Activities") {
                    Task { await dismissAllActivities() }
                }
                .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    // MARK: - Widgets Section

    private var widgetsSection: some View {
        GroupBox("Lock Screen Widgets") {
            VStack(spacing: 10) {
                Button("Present Widget • Inline") {
                    Task { await presentInlineWidget() }
                }

                Button("Present Widget • Card") {
                    Task { await presentCardWidget() }
                }

                Button("Present Widget • Circular Gauge") {
                    Task { await presentCircularWidget() }
                }

                Button("Present Widget • Custom WebView") {
                    Task { await presentWebWidget() }
                }

                Button("Present Widget • Localhost URL") {
                    Task { await presentLocalhostWebWidget() }
                }

                Divider().padding(.vertical, 6)

                Button("Dismiss All Widgets") {
                    Task { await dismissAllWidgets() }
                }
                .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    // MARK: - Notch Experiences Section

    private var notchExperiencesSection: some View {
        GroupBox("Notch Experiences") {
            VStack(spacing: 10) {
                Button("Present • Simple Tab") {
                    Task { await presentSimpleTab() }
                }

                Button("Present • Minimalistic") {
                    Task { await presentMinimalistic() }
                }

                Button("Present • Combined (Tab + Minimalistic)") {
                    Task { await presentCombined() }
                }

                Button("Present • Flight Animation Simple (Canvas)") {
                    Task { await presentFlightSimpleNotch() }
                }

                Button("Update • Flight Animation Simple (+10%)") {
                    Task { await updateFlightSimpleNotch() }
                }

                Divider().padding(.vertical, 6)

                Button("Dismiss • Simple Tab") {
                    Task { await dismissNotch(id: notchTab) }
                }
                Button("Dismiss • Minimalistic") {
                    Task { await dismissNotch(id: notchMini) }
                }
                Button("Dismiss • Combined") {
                    Task { await dismissNotch(id: notchCombo) }
                }
                Button("Dismiss • Flight Simple") {
                    Task { await dismissNotch(id: notchFlightSimple) }
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(!isAuthorized)
        }
    }

    // MARK: - Connection

    private func connectToAtoll() async {
        do {
            try await client.connect()
            isConnected = client.isConnected
            status = "Connected to Atoll ✅"
        } catch {
            status = "Connection failed: \(error.localizedDescription)"
        }
    }

    private func requestAuthorization() async {
        do {
            isAuthorized = try await client.requestAuthorization()
            status = isAuthorized ? "Authorization granted ✅" : "Authorization denied ❌"
        } catch {
            status = "Authorization failed: \(error.localizedDescription)"
        }
    }

    private func checkAuthorization() async {
        do {
            isAuthorized = try await client.checkAuthorization()
            status = isAuthorized ? "Authorized ✅" : "Not authorized ❌"
        } catch {
            status = "Check failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Live Activities: Present / Update / Dismiss

    private func presentDownload() async {
        demoProgress = 0.35
        let descriptor = AtollLiveActivityDescriptor(
            id: downloadID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .low,
            title: "Downloading",
            subtitle: "update-pkg-v2.dmg",
            leadingIcon: .symbol(name: "arrow.down.circle.fill"),
            trailingContent: .none,
            progressIndicator: .percentage(),
            progress: demoProgress,
            accentColor: .blue,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Download",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))% complete"
        )
        await presentActivity(descriptor)
    }

    private func updateDownload() async {
        demoProgress = min(demoProgress + 0.10, 1.0)
        let descriptor = AtollLiveActivityDescriptor(
            id: downloadID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .low,
            title: "Downloading",
            subtitle: "update-pkg-v2.dmg",
            leadingIcon: .symbol(name: "arrow.down.circle.fill"),
            trailingContent: .none,
            progressIndicator: .percentage(),
            progress: demoProgress,
            accentColor: .blue,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: AtollSneakPeekConfig(
                enabled: true, duration: 3.0,
                style: .standard, showOnUpdate: true
            ),
            sneakPeekTitle: "Download",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))% complete"
        )
        await updateActivity(descriptor)
    }

    private func presentPomodoro() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: pomodoroID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Focus",
            subtitle: "Pomodoro",
            leadingIcon: .symbol(name: "brain.head.profile"),
            trailingContent: .countdownText(
                targetDate: Date().addingTimeInterval(25 * 60),
                font: .monospacedDigit(size: 13, weight: .semibold)
            ),
            accentColor: .purple,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Focus session",
            sneakPeekSubtitle: "25 min"
        )
        await presentActivity(descriptor)
    }

    private func presentNewsMarquee() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: newsID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "News",
            subtitle: "Top headlines",
            leadingIcon: .symbol(name: "newspaper.fill"),
            trailingContent: .marquee(
                "Markets rally • New release ships today • Weather clears…",
                font: .system(size: 12, weight: .semibold),
                minDuration: 0.6
            ),
            accentColor: .white,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Headlines",
            sneakPeekSubtitle: "Latest updates"
        )
        await presentActivity(descriptor)
    }

    private func presentSpectrum() async {
        let descriptor = AtollLiveActivityDescriptor(
            id: spectrumID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Audio",
            subtitle: "Spectrum",
            leadingIcon: .symbol(name: "music.note"),
            trailingContent: .spectrum(color: .accent),
            accentColor: .white,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Audio",
            sneakPeekSubtitle: "Monitoring"
        )
        await presentActivity(descriptor)
    }

    private func presentFlight() async {
        flightProgress = 0.12
        let percent = Int(flightProgress * 100)
        let descriptor = AtollLiveActivityDescriptor(
            id: flightID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Flight",
            subtitle: "SFO → JFK",
            leadingIcon: .symbol(name: "airplane"),
            trailingContent: .text("\(percent)%"),
            accentColor: .white,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "SFO → JFK",
            sneakPeekSubtitle: "In flight • \(percent)%"
        )
        await presentActivity(descriptor)
    }

    private func updateFlight() async {
        flightProgress = min(flightProgress + 0.10, 1.0)
        let percent = Int(flightProgress * 100)
        let descriptor = AtollLiveActivityDescriptor(
            id: flightID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Flight",
            subtitle: "SFO → JFK",
            leadingIcon: .symbol(name: "airplane"),
            trailingContent: .text("\(percent)%"),
            accentColor: .white,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: AtollSneakPeekConfig(
                enabled: true, duration: 3.0,
                style: .standard, showOnUpdate: true
            ),
            sneakPeekTitle: "SFO → JFK",
            sneakPeekSubtitle: "\(percent)% complete"
        )
        await updateActivity(descriptor)
    }

    private func presentIndicatorRing() async {
        demoProgress = 0.62
        let descriptor = AtollLiveActivityDescriptor(
            id: indicatorID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Backup",
            subtitle: "Ring indicator",
            leadingIcon: .symbol(name: "externaldrive.fill"),
            trailingContent: .none,
            progressIndicator: .ring(diameter: 26, strokeWidth: 3),
            progress: demoProgress,
            accentColor: .white,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Backup",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))%"
        )
        await presentActivity(descriptor)
    }

    private func presentIndicatorBar() async {
        demoProgress = 0.47
        let descriptor = AtollLiveActivityDescriptor(
            id: indicatorID,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            title: "Export",
            subtitle: "Bar indicator",
            leadingIcon: .symbol(name: "film.fill"),
            trailingContent: .none,
            progressIndicator: .bar(width: 90, height: 4),
            progress: demoProgress,
            accentColor: .orange,
            allowsMusicCoexistence: true,
            centerTextStyle: .inheritUser,
            sneakPeekConfig: .standard(duration: 3.0),
            sneakPeekTitle: "Export",
            sneakPeekSubtitle: "\(Int(demoProgress * 100))%"
        )
        await presentActivity(descriptor)
    }

    private func dismissAllActivities() async {
        let ids = [downloadID, pomodoroID, newsID, spectrumID, flightID, indicatorID]
        for id in ids {
            try? await client.dismissLiveActivity(activityID: id)
        }
        status = "Dismissed all live activities"
    }

    // MARK: - Widgets

    private func presentInlineWidget() async {
        let widget = AtollLockScreenWidgetDescriptor(
            id: widgetInline,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .inline,
            position: .init(alignment: .center, verticalOffset: 110),
            material: .frosted,
            content: [
                .icon(.symbol(name: "airplane.departure")),
                .spacer(height: 4),
                .text("Flight", font: .system(size: 15, weight: .semibold), color: .white),
                .spacer(height: 2),
                .text("SFO → JFK", font: .system(size: 13, weight: .regular), color: .white),
            ],
            accentColor: .accent,
            dismissOnUnlock: true,
            priority: .normal
        )
        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: inline"
        } catch {
            status = "Widget failed: \(error.localizedDescription)"
        }
    }

    private func presentCardWidget() async {
        let widget = AtollLockScreenWidgetDescriptor(
            id: widgetCard,
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
                .divider(color: .white, thickness: 1),
                .spacer(height: 8),
                .gauge(value: 0.76, minValue: 0, maxValue: 1, style: .circular, color: .green),
            ],
            accentColor: .accent,
            dismissOnUnlock: true,
            priority: .normal
        )
        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: card (liquid glass)"
        } catch {
            status = "Widget failed: \(error.localizedDescription)"
        }
    }

    private func presentCircularWidget() async {
        let widget = AtollLockScreenWidgetDescriptor(
            id: widgetCircle,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .circular,
            position: .init(alignment: .trailing, verticalOffset: 140, horizontalOffset: -70),
            material: .frosted,
            content: [
                .gauge(value: 0.55, minValue: 0, maxValue: 1, style: .circular, color: .accent),
            ],
            accentColor: .white,
            dismissOnUnlock: true,
            priority: .normal
        )
        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: circular"
        } catch {
            status = "Widget failed: \(error.localizedDescription)"
        }
    }

    private func presentWebWidget() async {
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <style>
            body { margin:0; background:transparent; font-family:-apple-system; color:white; }
            .row { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
            .dot { width:10px; height:10px; border-radius:999px; background:rgba(0,200,255,0.95); }
            .title { font-size:13px; font-weight:600; opacity:0.85; }
            canvas { width:100%; height:70px; display:block; }
          </style>
        </head>
        <body>
          <div class="row">
            <div class="dot"></div>
            <div class="title">Realtime Sparkline</div>
          </div>
          <canvas id="c"></canvas>
          <script>
            const canvas = document.getElementById("c");
            const ctx = canvas.getContext("2d");
            let pts = Array.from({length: 20}, () => Math.random());

            function resize() {
              canvas.width = canvas.clientWidth * devicePixelRatio;
              canvas.height = canvas.clientHeight * devicePixelRatio;
            }
            resize();
            window.addEventListener("resize", resize);

            function tick() {
              pts.shift();
              pts.push(Math.random());
              ctx.clearRect(0,0,canvas.width,canvas.height);
              ctx.beginPath();
              ctx.lineWidth = 3 * devicePixelRatio;
              for (let i=0; i<pts.length; i++) {
                const x = (i/(pts.length-1)) * canvas.width;
                const y = canvas.height - pts[i] * canvas.height;
                if (i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
              }
              ctx.strokeStyle = "rgba(0,200,255,0.95)";
              ctx.stroke();
            }
            setInterval(tick, 450);
            tick();
          </script>
        </body>
        </html>
        """

        let widget = AtollLockScreenWidgetDescriptor(
            id: widgetWeb,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .custom,
            position: .init(alignment: .center, verticalOffset: -140),
            size: CGSize(width: 320, height: 160),
            material: .clear,
            cornerRadius: 24,
            content: [
                .webView(.init(
                    html: html,
                    preferredHeight: 140,
                    isTransparent: true,
                    allowLocalhostRequests: false
                )),
            ],
            accentColor: .white,
            dismissOnUnlock: true,
            priority: .normal
        )
        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: custom web sparkline"
        } catch {
            status = "Widget failed: \(error.localizedDescription)"
        }
    }

    private func dismissAllWidgets() async {
        let ids = [widgetInline, widgetCard, widgetCircle, widgetWeb, widgetWebLocalhost]
        for id in ids {
            try? await client.dismissLockScreenWidget(widgetID: id)
        }
        status = "Dismissed all widgets"
    }

    private func presentLocalhostWebWidget() async {
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"/>
          <style>
            body { margin:0; background:transparent; color:white; font-family:-apple-system; }
            .status { padding:8px; font-size:12px; opacity:0.85; }
          </style>
        </head>
        <body>
          <div class=\"status\">Loading localhost content…</div>
          <script>
            window.location.replace(\"
        \(localhostWidgetURL)
        \" );
          </script>
        </body>
        </html>
        """

        let widget = AtollLockScreenWidgetDescriptor(
            id: widgetWebLocalhost,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            layoutStyle: .custom,
            position: .init(alignment: .center, verticalOffset: -140),
            size: CGSize(width: 320, height: 190),
            material: .clear,
            cornerRadius: 24,
            content: [
                .webView(.init(
                    html: html,
                    preferredHeight: 180,
                    isTransparent: true,
                    allowLocalhostRequests: true
                )),
            ],
            accentColor: .white,
            dismissOnUnlock: true,
            priority: .normal
        )
        do {
            try await client.presentLockScreenWidget(widget)
            status = "Presented widget: localhost web (\(localhostWidgetURL))"
        } catch {
            status = "Widget failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Notch Experiences

    private func presentSimpleTab() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: notchTab,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            accentColor: .white,
            tab: .init(
                title: "Demo",
                iconSymbolName: "sparkles",
                preferredHeight: 190,
                sections: [
                    .init(
                        id: "one",
                        title: "Hello",
                        layout: .stack,
                        elements: [
                            .text("Notch tab demo", font: .system(size: 16, weight: .semibold), color: .white),
                            .text("Small, clean, valid.", font: .system(size: 12, weight: .regular), color: .white),
                        ]
                    ),
                ],
                allowWebInteraction: false
            )
        )
        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented notch tab: simple"
        } catch {
            status = "Notch failed: \(error.localizedDescription)"
        }
    }

    private func presentMinimalistic() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: notchMini,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .normal,
            accentColor: .white,
            minimalistic: .init(
                headline: "Minimalistic",
                subtitle: "Override demo",
                sections: [
                    .init(
                        id: "m",
                        layout: .metrics,
                        elements: [
                            .text("Mode", font: .system(size: 12, weight: .regular), color: .white),
                            .text("Active", font: .system(size: 14, weight: .semibold), color: .white),
                        ]
                    ),
                ],
                layout: .metrics,
                hidesMusicControls: false
            )
        )
        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented minimalistic notch"
        } catch {
            status = "Notch failed: \(error.localizedDescription)"
        }
    }

    private func presentCombined() async {
        let descriptor = AtollNotchExperienceDescriptor(
            id: notchCombo,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            tab: .init(
                title: "Combined",
                iconSymbolName: "square.stack.3d.up.fill",
                preferredHeight: 210,
                sections: [
                    .init(
                        id: "a",
                        title: "Metrics",
                        layout: .metrics,
                        elements: [
                            .text("CPU", font: .system(size: 12, weight: .regular), color: .white),
                            .text("21%", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                            .text("RAM", font: .system(size: 12, weight: .regular), color: .white),
                            .text("8.3 GB", font: .monospacedDigit(size: 14, weight: .semibold), color: .white),
                        ]
                    ),
                ],
                allowWebInteraction: false
            ),
            minimalistic: .init(
                headline: "Combined Demo",
                subtitle: "Tab + minimalistic",
                sections: [
                    .init(
                        id: "b",
                        layout: .stack,
                        elements: [
                            .text("Everything works.", font: .system(size: 13, weight: .semibold), color: .white),
                        ]
                    ),
                ],
                layout: .stack,
                hidesMusicControls: false
            )
        )
        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented combined notch experience"
        } catch {
            status = "Notch failed: \(error.localizedDescription)"
        }
    }

    private func presentFlightSimpleNotch() async {
        flightProgress = max(0.05, min(flightProgress, 0.95))
        let html = flightAnimationSimpleHTML(progress01: flightProgress)

        let descriptor = AtollNotchExperienceDescriptor(
            id: notchFlightSimple,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            metadata: ["progress": "\(flightProgress)", "renderer": "canvas2d"],
            tab: .init(
                title: "Flight (Simple)",
                iconSymbolName: "airplane.circle.fill",
                preferredHeight: 220,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 200,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                allowWebInteraction: false,
                footnote: "No external scripts"
            ),
            minimalistic: .init(
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 155,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                layout: .custom,
                hidesMusicControls: false
            )
        )
        do {
            try await client.presentNotchExperience(descriptor)
            status = "Presented notch: flight simple"
        } catch {
            status = "Notch failed: \(error.localizedDescription)"
        }
    }

    private func updateFlightSimpleNotch() async {
        flightProgress = min(flightProgress + 0.10, 1.0)
        let html = flightAnimationSimpleHTML(progress01: flightProgress)

        let descriptor = AtollNotchExperienceDescriptor(
            id: notchFlightSimple,
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            accentColor: .white,
            metadata: ["progress": "\(flightProgress)", "renderer": "canvas2d"],
            tab: .init(
                title: "Flight (Simple)",
                iconSymbolName: "airplane.circle.fill",
                preferredHeight: 220,
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 200,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                allowWebInteraction: false,
                footnote: "No external scripts"
            ),
            minimalistic: .init(
                sections: [],
                webContent: .init(
                    html: html,
                    preferredHeight: 155,
                    isTransparent: true,
                    allowLocalhostRequests: false
                ),
                layout: .custom,
                hidesMusicControls: false
            )
        )
        do {
            try await client.updateNotchExperience(descriptor)
            status = "Updated notch: flight simple"
        } catch {
            status = "Notch update failed: \(error.localizedDescription)"
        }
    }

    private func flightAnimationSimpleHTML(progress01: Double) -> String {
        let p = max(0.0, min(progress01, 1.0))
        return """
        <!doctype html>
        <html>
        <head>
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"/>
          <style>
            body { margin:0; background:transparent; overflow:hidden; }
            canvas { width:100%; height:100%; display:block; }
          </style>
        </head>
        <body>
          <canvas id=\"c\"></canvas>
          <script>
            const canvas = document.getElementById(\"c\");
            const ctx = canvas.getContext(\"2d\");

            function resize() {
              canvas.width = Math.max(10, canvas.clientWidth) * devicePixelRatio;
              canvas.height = Math.max(10, canvas.clientHeight) * devicePixelRatio;
            }
            resize();
            window.addEventListener(\"resize\", resize);

            const planeSvg = `<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"64\" height=\"64\" viewBox=\"0 0 64 64\"><path fill=\"white\" d=\"M62 30c0-1.1-.9-2-2-2H39.7L26.9 9.8c-.4-.6-1.1-1-1.9-1H21c-1.1 0-2 .9-2 2v17.2L9.4 28l-3.1-7.2c-.3-.8-1.1-1.3-1.9-1.3H2c-1.1 0-2 .9-2 2v3l8 8-8 8v3c0 1.1.9 2 2 2h2.4c.8 0 1.6-.5 1.9-1.3L9.4 36l9.6 0v17.2c0 1.1.9 2 2 2h4c.8 0 1.5-.4 1.9-1L39.7 36H60c1.1 0 2-.9 2-2z\"/></svg>`;
            const planeImg = new Image();
            planeImg.src = \"data:image/svg+xml;charset=utf-8,\" + encodeURIComponent(planeSvg);

            let progress = \(p);
            let t = 0;

            function bezier(p0, p1, p2, tt) {
              return {
                x: (1-tt)*(1-tt)*p0.x + 2*(1-tt)*tt*p1.x + tt*tt*p2.x,
                y: (1-tt)*(1-tt)*p0.y + 2*(1-tt)*tt*p1.y + tt*tt*p2.y,
              };
            }

            function draw() {
              ctx.clearRect(0, 0, canvas.width, canvas.height);
              const w = canvas.width;
              const h = canvas.height;
              const left = { x: 26 * devicePixelRatio, y: h - 42 * devicePixelRatio };
              const right = { x: w - 26 * devicePixelRatio, y: h - 42 * devicePixelRatio };
              const control = { x: w * 0.5, y: h * 0.16 };

              ctx.beginPath();
              ctx.moveTo(left.x, left.y);
              ctx.quadraticCurveTo(control.x, control.y, right.x, right.y);
              ctx.strokeStyle = \"rgba(255,255,255,0.20)\";
              ctx.lineWidth = 3 * devicePixelRatio;
              ctx.stroke();

              const drift = 0.012 * Math.sin(t * 0.9);
              const pp = Math.max(0, Math.min(1, progress + drift));
              const pos = bezier(left, control, right, pp);
              const ahead = bezier(left, control, right, Math.min(1, pp + 0.01));
              const angle = Math.atan2(ahead.y - pos.y, ahead.x - pos.x);

              if (planeImg.complete) {
                const size = 24 * devicePixelRatio;
                ctx.save();
                ctx.translate(pos.x, pos.y);
                ctx.rotate(angle);
                ctx.drawImage(planeImg, -size * 0.6, -size * 0.45, size * 1.2, size * 0.9);
                ctx.restore();
              }

              t += 0.02;
              requestAnimationFrame(draw);
            }

            planeImg.onload = () => requestAnimationFrame(draw);
            if (planeImg.complete) requestAnimationFrame(draw);
          </script>
        </body>
        </html>
        """
    }

    private func dismissNotch(id: String) async {
        do {
            try await client.dismissNotchExperience(experienceID: id)
            status = "Dismissed notch: \(id)"
        } catch {
            status = "Dismiss failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Transport Helpers

    private func presentActivity(_ descriptor: AtollLiveActivityDescriptor) async {
        do {
            try await client.presentLiveActivity(descriptor)
            status = "Presented: \(descriptor.id)"
        } catch {
            status = "Present failed: \(error.localizedDescription)"
        }
    }

    private func updateActivity(_ descriptor: AtollLiveActivityDescriptor) async {
        do {
            try await client.updateLiveActivity(descriptor)
            status = "Updated: \(descriptor.id)"
        } catch {
            status = "Update failed: \(error.localizedDescription)"
        }
    }
}

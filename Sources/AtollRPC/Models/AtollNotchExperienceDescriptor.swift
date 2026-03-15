//
//  AtollNotchExperienceDescriptor.swift
//  AtollRPC
//
//  Describes third-party notch content rendered inside the Dynamic Island.
//

import Foundation
import CoreGraphics

/// Declarative descriptor for rich notch content surfaces.
public struct AtollNotchExperienceDescriptor: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let bundleIdentifier: String
    public let priority: AtollLiveActivityPriority
    public let accentColor: AtollColorDescriptor
    public let metadata: [String: String]
    public let tab: TabConfiguration?
    public let minimalistic: MinimalisticConfiguration?
    public let durationHint: TimeInterval?

    public var isValid: Bool {
        guard !id.isEmpty,
              !bundleIdentifier.isEmpty,
              tab != nil || minimalistic != nil else {
            return false
        }
        if let tab, !tab.isValid { return false }
        if let minimalistic, !minimalistic.isValid { return false }
        return metadata.count <= 32 && metadata.keys.allSatisfy { !$0.isEmpty }
    }

    private enum CodingKeys: String, CodingKey {
        case id, bundleIdentifier, priority, accentColor, metadata, tab, minimalistic, durationHint
    }

    public init(
        id: String,
        bundleIdentifier: String,
        priority: AtollLiveActivityPriority = .normal,
        accentColor: AtollColorDescriptor = .accent,
        metadata: [String: String] = [:],
        tab: TabConfiguration? = nil,
        minimalistic: MinimalisticConfiguration? = nil,
        durationHint: TimeInterval? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.priority = priority
        self.accentColor = accentColor
        self.metadata = metadata
        self.tab = tab
        self.minimalistic = minimalistic
        self.durationHint = durationHint
    }

    /// Convenience initializer that uses `Bundle.main.bundleIdentifier`.
    public init(
        id: String,
        priority: AtollLiveActivityPriority = .normal,
        accentColor: AtollColorDescriptor = .accent,
        metadata: [String: String] = [:],
        tab: TabConfiguration? = nil,
        minimalistic: MinimalisticConfiguration? = nil,
        durationHint: TimeInterval? = nil
    ) {
        self.init(
            id: id,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            priority: priority,
            accentColor: accentColor,
            metadata: metadata,
            tab: tab,
            minimalistic: minimalistic,
            durationHint: durationHint
        )
    }
}

// MARK: - Tab Configuration

public extension AtollNotchExperienceDescriptor {
    struct TabConfiguration: Codable, Sendable, Hashable {
        public let title: String
        public let iconSymbolName: String?
        public let badgeIcon: AtollIconDescriptor?
        public let preferredHeight: CGFloat?
        public let appearance: AtollWidgetAppearanceOptions?
        public let sections: [AtollNotchContentSection]
        public let webContent: AtollWidgetWebContentDescriptor?
        public let allowWebInteraction: Bool
        public let footnote: String?

        public init(
            title: String,
            iconSymbolName: String? = nil,
            badgeIcon: AtollIconDescriptor? = nil,
            preferredHeight: CGFloat? = nil,
            appearance: AtollWidgetAppearanceOptions? = nil,
            sections: [AtollNotchContentSection] = [],
            webContent: AtollWidgetWebContentDescriptor? = nil,
            allowWebInteraction: Bool = false,
            footnote: String? = nil
        ) {
            self.title = title
            self.iconSymbolName = iconSymbolName
            self.badgeIcon = badgeIcon
            self.preferredHeight = preferredHeight
            self.appearance = appearance
            self.sections = sections
            self.webContent = webContent
            self.allowWebInteraction = allowWebInteraction
            self.footnote = footnote
        }

        var isValid: Bool {
            guard !title.isEmpty,
                  sections.count <= 6,
                  sections.allSatisfy({ $0.isValid }) else {
                return false
            }
            if let preferredHeight {
                if preferredHeight < 160 || preferredHeight > 420 { return false }
            }
            if let footnote, footnote.count > 140 { return false }
            if let webContent, !webContent.isValid { return false }
            if let badgeIcon, !badgeIcon.isValid { return false }
            return appearance?.isValid ?? true
        }
    }
}

// MARK: - Minimalistic Configuration

public extension AtollNotchExperienceDescriptor {
    struct MinimalisticConfiguration: Codable, Sendable, Hashable {
        public let headline: String?
        public let subtitle: String?
        public let sections: [AtollNotchContentSection]
        public let webContent: AtollWidgetWebContentDescriptor?
        public let layout: MinimalisticLayout
        public let hidesMusicControls: Bool

        public init(
            headline: String? = nil,
            subtitle: String? = nil,
            sections: [AtollNotchContentSection] = [],
            webContent: AtollWidgetWebContentDescriptor? = nil,
            layout: MinimalisticLayout = .stack,
            hidesMusicControls: Bool = true
        ) {
            self.headline = headline
            self.subtitle = subtitle
            self.sections = sections
            self.webContent = webContent
            self.layout = layout
            self.hidesMusicControls = hidesMusicControls
        }

        var isValid: Bool {
            let headlineLength = headline?.count ?? 0
            let subtitleLength = subtitle?.count ?? 0
            guard headlineLength <= 80,
                  subtitleLength <= 120,
                  sections.count <= 3,
                  sections.allSatisfy({ $0.isValid }) else {
                return false
            }
            if let webContent, !webContent.isValid { return false }
            return true
        }
    }

    enum MinimalisticLayout: String, Codable, Sendable, Hashable {
        case stack, metrics, custom
    }
}

// MARK: - Content Sections

public struct AtollNotchContentSection: Codable, Sendable, Hashable {
    public enum Layout: String, Codable, Sendable, Hashable {
        case stack, columns, metrics
    }

    public let id: String?
    public let title: String?
    public let subtitle: String?
    public let layout: Layout
    public let elements: [AtollWidgetContentElement]

    public init(
        id: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        layout: Layout = .stack,
        elements: [AtollWidgetContentElement]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.layout = layout
        self.elements = elements
    }

    var isValid: Bool {
        guard !elements.isEmpty,
              elements.count <= 6,
              elements.allSatisfy({ $0.isValid }) else {
            return false
        }
        if let title, title.count > 80 { return false }
        if let subtitle, subtitle.count > 160 { return false }
        return true
    }
}

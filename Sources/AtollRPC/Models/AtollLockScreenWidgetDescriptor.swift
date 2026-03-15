//
//  AtollLockScreenWidgetDescriptor.swift
//  AtollRPC
//
//  Complete descriptor for lock screen widgets.
//

import Foundation
import CoreGraphics

/// Describes a lock screen widget to be displayed when the device is locked.
public struct AtollLockScreenWidgetDescriptor: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let bundleIdentifier: String
    public let layoutStyle: AtollWidgetLayoutStyle
    public let position: AtollWidgetPosition
    public let size: CGSize
    public let material: AtollWidgetMaterial
    public let appearance: AtollWidgetAppearanceOptions?
    public let cornerRadius: CGFloat
    public let content: [AtollWidgetContentElement]
    public let accentColor: AtollColorDescriptor
    public let dismissOnUnlock: Bool
    public let priority: AtollLiveActivityPriority
    public let metadata: [String: String]
    
    public init(
        id: String,
        bundleIdentifier: String,
        layoutStyle: AtollWidgetLayoutStyle = .inline,
        position: AtollWidgetPosition = .default,
        size: CGSize? = nil,
        material: AtollWidgetMaterial = .frosted,
        appearance: AtollWidgetAppearanceOptions? = nil,
        cornerRadius: CGFloat = 16,
        content: [AtollWidgetContentElement],
        accentColor: AtollColorDescriptor = .accent,
        dismissOnUnlock: Bool = true,
        priority: AtollLiveActivityPriority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.layoutStyle = layoutStyle
        self.position = position
        self.size = size ?? layoutStyle.defaultSize
        self.material = material
        self.appearance = appearance
        self.cornerRadius = min(max(cornerRadius, 0), 32)
        self.content = content
        self.accentColor = accentColor
        self.dismissOnUnlock = dismissOnUnlock
        self.priority = priority
        self.metadata = metadata
    }
    
    public var isValid: Bool {
        !id.isEmpty &&
        !bundleIdentifier.isEmpty &&
        !content.isEmpty &&
        size.width > 0 && size.height > 0 &&
        size.width <= 640 && size.height <= 360 &&
        (appearance?.isValid ?? true) &&
        content.allSatisfy(\.isValid)
    }
}

public enum AtollWidgetLayoutStyle: String, Codable, Sendable, Hashable {
    case inline
    case circular
    case card
    case custom
    
    var defaultSize: CGSize {
        switch self {
        case .inline: return CGSize(width: 200, height: 48)
        case .circular: return CGSize(width: 100, height: 100)
        case .card: return CGSize(width: 220, height: 120)
        case .custom: return CGSize(width: 150, height: 80)
        }
    }
}

public struct AtollWidgetPosition: Codable, Sendable, Hashable {
    public let alignment: Alignment
    public let verticalOffset: CGFloat
    public let horizontalOffset: CGFloat
    public let clampMode: ClampMode

    public init(
        alignment: Alignment = .center,
        verticalOffset: CGFloat = 0,
        horizontalOffset: CGFloat = 0,
        clampMode: ClampMode = .safeRegion
    ) {
        self.alignment = alignment
        self.verticalOffset = min(max(verticalOffset, -400), 400)
        self.horizontalOffset = min(max(horizontalOffset, -600), 600)
        self.clampMode = clampMode
    }
    
    public static let `default` = AtollWidgetPosition(
        alignment: .center,
        verticalOffset: 0,
        horizontalOffset: 0,
        clampMode: .safeRegion
    )
    
    public enum Alignment: String, Codable, Sendable, Hashable {
        case leading, center, trailing
    }

    public enum ClampMode: String, Codable, Sendable, Hashable {
        case safeRegion
        case relaxed
        case unconstrained
    }

    private enum CodingKeys: String, CodingKey {
        case alignment, verticalOffset, horizontalOffset, clampMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let alignment = try container.decodeIfPresent(Alignment.self, forKey: .alignment) ?? .center
        let vertical = try container.decodeIfPresent(CGFloat.self, forKey: .verticalOffset) ?? 0
        let horizontal = try container.decodeIfPresent(CGFloat.self, forKey: .horizontalOffset) ?? 0
        let clampMode = try container.decodeIfPresent(ClampMode.self, forKey: .clampMode) ?? .safeRegion
        self.alignment = alignment
        self.verticalOffset = min(max(vertical, -400), 400)
        self.horizontalOffset = min(max(horizontal, -600), 600)
        self.clampMode = clampMode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alignment, forKey: .alignment)
        try container.encode(verticalOffset, forKey: .verticalOffset)
        try container.encode(horizontalOffset, forKey: .horizontalOffset)
        try container.encode(clampMode, forKey: .clampMode)
    }
}

public enum AtollWidgetMaterial: String, Codable, Sendable, Hashable {
    case frosted, liquid, solid, semiTransparent, clear
}

public struct AtollLiquidGlassVariant: Codable, Sendable, Hashable {
    public static let supportedRange = 0...19
    public let rawValue: Int

    public init(_ value: Int) {
        if value < Self.supportedRange.lowerBound {
            self.rawValue = Self.supportedRange.lowerBound
        } else if value > Self.supportedRange.upperBound {
            self.rawValue = Self.supportedRange.upperBound
        } else {
            self.rawValue = value
        }
    }

    var isValid: Bool { Self.supportedRange.contains(rawValue) }
}

public enum AtollWidgetContentElement: Codable, Sendable, Hashable {
    case text(String, font: AtollFontDescriptor, color: AtollColorDescriptor? = nil, alignment: TextAlignment = .leading)
    case icon(AtollIconDescriptor, tint: AtollColorDescriptor? = nil)
    case progress(AtollProgressIndicator, value: Double, color: AtollColorDescriptor? = nil)
    case graph(data: [Double], color: AtollColorDescriptor, size: CGSize)
    case gauge(value: Double, minValue: Double = 0, maxValue: Double = 1, style: GaugeStyle = .circular, color: AtollColorDescriptor? = nil)
    case spacer(height: CGFloat)
    case divider(color: AtollColorDescriptor = .gray, thickness: CGFloat = 1)
    case webView(AtollWidgetWebContentDescriptor)
    
    public enum TextAlignment: String, Codable, Sendable, Hashable {
        case leading, center, trailing
    }
    
    public enum GaugeStyle: String, Codable, Sendable, Hashable {
        case circular, linear
    }
    
    var isValid: Bool {
        switch self {
        case .icon(let descriptor, _):
            return descriptor.isValid
        case .graph(let data, _, let size):
            return !data.isEmpty && data.count <= 100 && size.width > 0 && size.height > 0
        case .gauge(let value, let min, let max, _, _):
            return value >= min && value <= max
        case .webView(let descriptor):
            return descriptor.isValid
        default:
            return true
        }
    }
}

// MARK: - Appearance Controls

public struct AtollWidgetAppearanceOptions: Codable, Sendable, Hashable {
    public let tintColor: AtollColorDescriptor?
    public let tintOpacity: Double
    public let enableGlassHighlight: Bool
    public let contentInsets: AtollWidgetContentInsets?
    public let border: AtollWidgetBorderStyle?
    public let shadow: AtollWidgetShadowStyle?
    public let liquidGlassVariant: AtollLiquidGlassVariant?

    public init(
        tintColor: AtollColorDescriptor? = nil,
        tintOpacity: Double = 0.85,
        enableGlassHighlight: Bool = false,
        contentInsets: AtollWidgetContentInsets? = nil,
        border: AtollWidgetBorderStyle? = nil,
        shadow: AtollWidgetShadowStyle? = nil,
        liquidGlassVariant: AtollLiquidGlassVariant? = nil
    ) {
        self.tintColor = tintColor
        self.tintOpacity = min(max(tintOpacity, 0), 1)
        self.enableGlassHighlight = enableGlassHighlight
        self.contentInsets = contentInsets
        self.border = border
        self.shadow = shadow
        self.liquidGlassVariant = liquidGlassVariant
    }

    var isValid: Bool {
        (border?.isValid ?? true) && (shadow?.isValid ?? true) && (liquidGlassVariant?.isValid ?? true)
    }
}

public struct AtollWidgetBorderStyle: Codable, Sendable, Hashable {
    public let color: AtollColorDescriptor
    public let opacity: Double
    public let width: CGFloat

    public init(color: AtollColorDescriptor, opacity: Double = 0.35, width: CGFloat = 1) {
        self.color = color
        self.opacity = min(max(opacity, 0), 1)
        self.width = min(max(width, 0), 6)
    }

    var isValid: Bool { width <= 6 && width >= 0 }
}

public struct AtollWidgetShadowStyle: Codable, Sendable, Hashable {
    public let color: AtollColorDescriptor
    public let opacity: Double
    public let radius: CGFloat
    public let offset: CGSize

    public init(
        color: AtollColorDescriptor,
        opacity: Double = 0.45,
        radius: CGFloat = 18,
        offset: CGSize = .zero
    ) {
        self.color = color
        self.opacity = min(max(opacity, 0), 1)
        self.radius = min(max(radius, 0), 60)
        let clampedX = min(max(offset.width, -80), 80)
        let clampedY = min(max(offset.height, -80), 80)
        self.offset = CGSize(width: clampedX, height: clampedY)
    }

    var isValid: Bool { radius >= 0 }
}

public struct AtollWidgetContentInsets: Codable, Sendable, Hashable {
    public let top: CGFloat
    public let leading: CGFloat
    public let bottom: CGFloat
    public let trailing: CGFloat

    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        let clamp: (CGFloat) -> CGFloat = { value in
            min(max(value, 0), 96)
        }
        self.top = clamp(top)
        self.leading = clamp(leading)
        self.bottom = clamp(bottom)
        self.trailing = clamp(trailing)
    }
}

// MARK: - Web Content

public struct AtollWidgetWebContentDescriptor: Codable, Sendable, Hashable {
    public let html: String
    public let preferredHeight: CGFloat
    public let isTransparent: Bool
    public let allowLocalhostRequests: Bool
    public let backgroundColor: AtollColorDescriptor?
    public let maximumContentWidth: CGFloat?

    public init(
        html: String,
        preferredHeight: CGFloat = 140,
        isTransparent: Bool = true,
        allowLocalhostRequests: Bool = false,
        backgroundColor: AtollColorDescriptor? = nil,
        maximumContentWidth: CGFloat? = nil
    ) {
        self.html = html
        self.preferredHeight = min(max(preferredHeight, 40), 420)
        self.isTransparent = isTransparent
        self.allowLocalhostRequests = allowLocalhostRequests
        self.backgroundColor = backgroundColor
        if let width = maximumContentWidth {
            self.maximumContentWidth = max(40, min(width, 640))
        } else {
            self.maximumContentWidth = nil
        }
    }

    var isValid: Bool {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && html.utf8.count <= 20000
    }
}

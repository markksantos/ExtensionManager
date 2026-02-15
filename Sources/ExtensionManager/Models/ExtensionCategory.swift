import SwiftUI

/// Categories of macOS extensions based on their SDK/extension point
enum ExtensionCategory: String, CaseIterable, Identifiable, Hashable {
    case finderSync = "Finder Sync"
    case shareServices = "Share Extensions"
    case quickLookPreview = "Quick Look Preview"
    case quickLookThumbnail = "Quick Look Thumbnail"
    case widgetKit = "Widgets"
    case appIntents = "App Intents"
    case intentsService = "Intents / Shortcuts"
    case safariWebExtension = "Safari Extensions"
    case notificationService = "Notifications"
    case networkExtension = "Network Extensions"
    case driverExtension = "Driver Extensions"
    case cameraExtension = "Camera Extensions"
    case spotlightIndex = "Spotlight Index"
    case credentialProvider = "Credential Provider"
    case contentFilter = "Content Filter"
    case other = "Other"

    var id: String { rawValue }

    /// Map raw SDK string to a category
    static func from(sdk: String) -> ExtensionCategory {
        let lower = sdk.lowercased()
        if lower.contains("findersync") { return .finderSync }
        if lower.contains("share-services") || lower.contains("share.") { return .shareServices }
        if lower.contains("quicklook.preview") { return .quickLookPreview }
        if lower.contains("quicklook.thumbnail") { return .quickLookThumbnail }
        if lower.contains("widgetkit") { return .widgetKit }
        if lower.contains("appintents") { return .appIntents }
        if lower.contains("intents-service") { return .intentsService }
        if lower.contains("safari") || lower.contains("web-extension") { return .safariWebExtension }
        if lower.contains("usernotifications") { return .notificationService }
        if lower.contains("network_extension") || lower.contains("networkextension") { return .networkExtension }
        if lower.contains("driver_extension") || lower.contains("driverkit") { return .driverExtension }
        if lower.contains("cmio") || lower.contains("camera") { return .cameraExtension }
        if lower.contains("spotlight.index") { return .spotlightIndex }
        if lower.contains("credential") { return .credentialProvider }
        if lower.contains("content-filter") { return .contentFilter }
        return .other
    }

    /// Map system extension type string to a category
    static func fromSystemExtension(type: String) -> ExtensionCategory {
        let lower = type.lowercased()
        if lower.contains("network") { return .networkExtension }
        if lower.contains("driver") { return .driverExtension }
        if lower.contains("cmio") || lower.contains("camera") { return .cameraExtension }
        return .other
    }

    /// SF Symbol name for the category
    var iconName: String {
        switch self {
        case .finderSync: return "folder.badge.gearshape"
        case .shareServices: return "square.and.arrow.up"
        case .quickLookPreview: return "eye"
        case .quickLookThumbnail: return "photo"
        case .widgetKit: return "widget.small"
        case .appIntents: return "app.badge"
        case .intentsService: return "wand.and.stars"
        case .safariWebExtension: return "safari"
        case .notificationService: return "bell"
        case .networkExtension: return "network"
        case .driverExtension: return "cpu"
        case .cameraExtension: return "camera"
        case .spotlightIndex: return "magnifyingglass"
        case .credentialProvider: return "key"
        case .contentFilter: return "line.3.horizontal.decrease.circle"
        case .other: return "puzzlepiece.extension"
        }
    }

    /// Color for the category badge
    var color: Color {
        switch self {
        case .finderSync: return .blue
        case .shareServices: return .green
        case .quickLookPreview: return .purple
        case .quickLookThumbnail: return .pink
        case .widgetKit: return .orange
        case .appIntents: return .cyan
        case .intentsService: return .mint
        case .safariWebExtension: return .indigo
        case .notificationService: return .red
        case .networkExtension: return .teal
        case .driverExtension: return .gray
        case .cameraExtension: return .brown
        case .spotlightIndex: return .yellow
        case .credentialProvider: return .secondary
        case .contentFilter: return .primary
        case .other: return .secondary
        }
    }

    /// Human-readable description of what this extension type does
    var description: String {
        switch self {
        case .finderSync: return "Integrates with Finder to show file sync status badges and context menus"
        case .shareServices: return "Adds sharing options to the system share menu"
        case .quickLookPreview: return "Provides file previews in Finder's Quick Look (spacebar preview)"
        case .quickLookThumbnail: return "Generates thumbnail images for files in Finder"
        case .widgetKit: return "Provides widgets for Notification Center and Desktop"
        case .appIntents: return "Exposes app actions for Shortcuts and Spotlight"
        case .intentsService: return "Handles Siri and Shortcuts automation requests"
        case .safariWebExtension: return "Extends Safari browser functionality"
        case .notificationService: return "Processes and customizes push notifications"
        case .networkExtension: return "Provides VPN, content filtering, or DNS proxy services"
        case .driverExtension: return "Hardware driver running in user space (DriverKit)"
        case .cameraExtension: return "Provides a virtual camera source to the system"
        case .spotlightIndex: return "Indexes content for Spotlight search"
        case .credentialProvider: return "Provides password autofill functionality"
        case .contentFilter: return "Filters network content at the system level"
        case .other: return "Other system extension or plugin"
        }
    }
}

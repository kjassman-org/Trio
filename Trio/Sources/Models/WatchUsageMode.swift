import Foundation

/// Controls which actions can be started from the Apple Watch app.
/// Shared between the iPhone app (enforcement) and the Watch app (UI).
enum WatchUsageMode: String, CaseIterable, Identifiable, Codable, Hashable {
    var id: String { rawValue }
    case companion
    case adjustments
    case view

    var displayName: String {
        switch self {
        case .companion:
            return String(localized: "Companion")
        case .adjustments:
            return String(localized: "Adjustments")
        case .view:
            return String(localized: "View")
        }
    }

    /// Bolus, carb and meal entries
    var allowsTreatments: Bool {
        self == .companion
    }

    /// Overrides and temp targets
    var allowsAdjustments: Bool {
        self != .view
    }
}

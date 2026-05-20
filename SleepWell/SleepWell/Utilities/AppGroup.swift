import Foundation

extension UserDefaults {
    /// Shared UserDefaults suite for the SleepWell App Group.
    /// Falls back to .standard if the suite cannot be created (e.g. in unit tests without entitlement).
    static let appGroup: UserDefaults =
        UserDefaults(suiteName: "group.com.highland.SleepWell") ?? .standard
}

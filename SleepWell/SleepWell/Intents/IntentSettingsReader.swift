import Foundation

struct IntentSettingsReader {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
    }

    var fallAsleepMinutes: Int {
        int(forKey: "fallAsleepMinutes", default: 14)
    }

    var alarmLabel: String {
        defaults.string(forKey: "alarmLabel") ?? "Wake Up"
    }

    func effectiveWakeDate(referenceDate: Date = Date()) -> Date {
        let scheduleEnabled = defaults.bool(forKey: "scheduleEnabled")
        let hour: Int
        let minute: Int
        if scheduleEnabled && Calendar.current.isDateInWeekend(referenceDate) {
            hour   = int(forKey: "weekendWakeHour",   default: 8)
            minute = int(forKey: "weekendWakeMinute", default: 0)
        } else if scheduleEnabled {
            hour   = int(forKey: "weekdayWakeHour",   default: 7)
            minute = int(forKey: "weekdayWakeMinute", default: 0)
        } else {
            hour   = int(forKey: "defaultWakeHour",   default: 7)
            minute = int(forKey: "defaultWakeMinute", default: 0)
        }
        return makeWakeDate(hour: hour, minute: minute)
    }

    // MARK: - Private

    private func int(forKey key: String, default defaultValue: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.integer(forKey: key)
    }

    private func makeWakeDate(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour   = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }
}

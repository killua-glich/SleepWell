import Foundation

/// Reads the user's wake schedule from shared UserDefaults and computes bedtime options.
/// Has no WidgetKit dependency — safe to use in both the app and widget extension.
struct WidgetScheduleReader {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
    }

    /// Returns 4 bedtime options for tonight based on the user's saved schedule.
    func bedtimes(for date: Date = Date()) -> [BedtimeOption] {
        let wakeTime = effectiveWakeTime(for: date)
        let fallAsleepMinutes = defaults.object(forKey: "fallAsleepMinutes") as? Int ?? 14
        return SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
    }

    /// Returns the effective wake time for a given reference date, respecting weekday/weekend schedule.
    func effectiveWakeTime(for date: Date = Date()) -> Date {
        let scheduleEnabled = defaults.bool(forKey: "scheduleEnabled")
        let isWeekend = Calendar.current.isDateInWeekend(date)

        let hour: Int
        let minute: Int
        if scheduleEnabled && isWeekend {
            hour   = defaults.object(forKey: "weekendWakeHour")   as? Int ?? 8
            minute = defaults.object(forKey: "weekendWakeMinute") as? Int ?? 0
        } else if scheduleEnabled {
            hour   = defaults.object(forKey: "weekdayWakeHour")   as? Int ?? 7
            minute = defaults.object(forKey: "weekdayWakeMinute") as? Int ?? 0
        } else {
            hour   = defaults.object(forKey: "defaultWakeHour")   as? Int ?? 7
            minute = defaults.object(forKey: "defaultWakeMinute") as? Int ?? 0
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? date
    }
}

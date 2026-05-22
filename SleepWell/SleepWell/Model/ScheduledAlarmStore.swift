import Foundation

struct ScheduledAlarm: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let label: String
}

final class ScheduledAlarmStore: @unchecked Sendable {
    private static let key = "com.highland.SleepWell.scheduledAlarms"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
    }

    func all() -> [ScheduledAlarm] {
        guard let data = defaults.data(forKey: Self.key),
              let alarms = try? JSONDecoder().decode([ScheduledAlarm].self, from: data)
        else { return [] }
        return alarms
    }

    func add(_ alarm: ScheduledAlarm) {
        var alarms = all()
        alarms.append(alarm)
        save(alarms)
    }

    func remove(id: UUID) {
        save(all().filter { $0.id != id })
    }

    func removeAll() {
        save([])
    }

    private func save(_ alarms: [ScheduledAlarm]) {
        defaults.set(try? JSONEncoder().encode(alarms), forKey: Self.key)
    }
}

import Foundation

struct BedtimeOption: Identifiable {
    let id = UUID()
    let bedtime: Date
    let totalSleepMinutes: Int
    let cycles: Int
    let isRecommended: Bool
    let napLabel: String?

    init(
        bedtime: Date,
        totalSleepMinutes: Int,
        cycles: Int,
        isRecommended: Bool,
        napLabel: String? = nil
    ) {
        self.bedtime = bedtime
        self.totalSleepMinutes = totalSleepMinutes
        self.cycles = cycles
        self.isRecommended = isRecommended
        self.napLabel = napLabel
    }

    var totalSleepFormatted: String {
        let hours = totalSleepMinutes / 60
        let minutes = totalSleepMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }
}

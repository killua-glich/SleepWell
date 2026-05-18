import Foundation

struct BedtimeOption: Identifiable {
    let id = UUID()
    let bedtime: Date
    let totalSleepMinutes: Int
    let cycles: Int
    let isRecommended: Bool

    var totalSleepFormatted: String {
        let hours = totalSleepMinutes / 60
        let minutes = totalSleepMinutes % 60
        if minutes == 0 {
            return "\(hours) hrs"
        }
        return "\(hours)h \(minutes)m"
    }
}

import Foundation

struct SleepCalculator {
    static let cycleDuration: TimeInterval = 90 * 60      // 90 min in seconds
    static let fallAsleepLatency: TimeInterval = 14 * 60  // 14 min in seconds

    static func calculate(wakeTime: Date) -> [BedtimeOption] {
        [6, 5, 4, 3].map { cycles in
            let sleepDuration = TimeInterval(cycles) * cycleDuration
            let bedtime = wakeTime - sleepDuration - fallAsleepLatency
            return BedtimeOption(
                bedtime: bedtime,
                totalSleepMinutes: cycles * 90,
                cycles: cycles,
                isRecommended: cycles == 5
            )
        }
    }
}

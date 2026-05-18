import Foundation

struct SleepCalculator {
    static let cycleDuration: TimeInterval = 90 * 60

    static func calculate(wakeTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption] {
        let latency = TimeInterval(fallAsleepMinutes) * 60
        return [6, 5, 4, 3].map { cycles in
            let sleepDuration = TimeInterval(cycles) * cycleDuration
            let bedtime = wakeTime - sleepDuration - latency
            return BedtimeOption(
                bedtime: bedtime,
                totalSleepMinutes: cycles * 90,
                cycles: cycles,
                isRecommended: cycles == 5
            )
        }
    }
}

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

    static func calculateWakeTimes(sleepTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption] {
        let latency = TimeInterval(fallAsleepMinutes) * 60
        let sleepOnset = sleepTime + latency
        return [6, 5, 4, 3].map { cycles in
            let sleepDuration = TimeInterval(cycles) * cycleDuration
            let wakeTime = sleepOnset + sleepDuration
            // In reverse mode, BedtimeOption.bedtime holds the wake-up time
            return BedtimeOption(
                bedtime: wakeTime,
                totalSleepMinutes: cycles * 90,
                cycles: cycles,
                isRecommended: cycles == 5
            )
        }
    }

    static func calculateNapTimes(napTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption] {
        let latency = TimeInterval(fallAsleepMinutes) * 60
        let sleepOnset = napTime + latency
        // BedtimeOption.bedtime holds the nap alarm (wake-up time) in this mode
        return [
            BedtimeOption(
                bedtime: sleepOnset + 20 * 60,
                totalSleepMinutes: 20,
                cycles: 0,
                isRecommended: false,
                napLabel: "Refreshing"
            ),
            BedtimeOption(
                bedtime: sleepOnset + 90 * 60,
                totalSleepMinutes: 90,
                cycles: 1,
                isRecommended: false,
                napLabel: "Deep Rest"
            )
        ]
    }
}

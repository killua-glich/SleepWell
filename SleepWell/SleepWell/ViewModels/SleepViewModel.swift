import Foundation
import Observation

@Observable
final class SleepViewModel {
    var wakeTime: Date = defaultWakeTime()
    var fallAsleepMinutes: Int = 14
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil

    func calculate() {
        bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        showResults = true
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
    }
}

private func defaultWakeTime() -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 7
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}

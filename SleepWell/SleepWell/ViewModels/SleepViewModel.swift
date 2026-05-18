import Foundation
import Observation
import SwiftUI

enum SleepMode {
    case wakeUp, sleepNow
}

@Observable
final class SleepViewModel {
    var wakeTime: Date = defaultWakeTime()
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil
    var mode: SleepMode = .wakeUp

    @ObservationIgnored
    @AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14

    func calculate() {
        switch mode {
        case .wakeUp:
            bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        case .sleepNow:
            bedtimes = SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        }
        showResults = true
    }

    func calculateSleepNow() {
        mode = .sleepNow
        calculate()
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
        mode = .wakeUp
    }
}

private func defaultWakeTime() -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 7
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}

import Foundation
import Observation
import SwiftUI

enum SleepMode {
    case wakeUp, sleepNow, nap
}

@Observable
final class SleepViewModel {
    var wakeTime: Date = SleepViewModel.makeWakeDate(hour: 7, minute: 0)
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil
    var mode: SleepMode = .wakeUp

    @ObservationIgnored
    @AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14

    @ObservationIgnored
    @AppStorage("defaultWakeHour") var defaultWakeHour: Int = 7

    @ObservationIgnored
    @AppStorage("defaultWakeMinute") var defaultWakeMinute: Int = 0

    @ObservationIgnored
    @AppStorage("scheduleEnabled") var scheduleEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("weekdayWakeHour") var weekdayWakeHour: Int = 7

    @ObservationIgnored
    @AppStorage("weekdayWakeMinute") var weekdayWakeMinute: Int = 0

    @ObservationIgnored
    @AppStorage("weekendWakeHour") var weekendWakeHour: Int = 8

    @ObservationIgnored
    @AppStorage("weekendWakeMinute") var weekendWakeMinute: Int = 0

    @ObservationIgnored
    @AppStorage("alarmLabel") var alarmLabel: String = "Wake Up"

    var defaultWakeDate: Date {
        SleepViewModel.makeWakeDate(hour: defaultWakeHour, minute: defaultWakeMinute)
    }

    func effectiveWakeDate(referenceDate: Date = Date()) -> Date {
        guard scheduleEnabled else { return defaultWakeDate }
        if Calendar.current.isDateInWeekend(referenceDate) {
            return SleepViewModel.makeWakeDate(hour: weekendWakeHour, minute: weekendWakeMinute)
        } else {
            return SleepViewModel.makeWakeDate(hour: weekdayWakeHour, minute: weekdayWakeMinute)
        }
    }

    static func makeWakeDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    func calculate() {
        switch mode {
        case .wakeUp:
            bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        case .sleepNow:
            bedtimes = SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        case .nap:
            bedtimes = SleepCalculator.calculateNapTimes(napTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        }
        showResults = true
    }

    func calculateWakeUp() {
        mode = .wakeUp
        calculate()
    }

    func calculateSleepNow() {
        mode = .sleepNow
        calculate()
    }

    func calculateNapNow() {
        mode = .nap
        calculate()
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
        mode = .wakeUp
    }
}

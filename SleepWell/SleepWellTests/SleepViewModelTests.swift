import Testing
import Foundation
@testable import SleepWell

@Suite("SleepViewModel default wake date")
struct SleepViewModelTests {

    @Test("makeWakeDate builds date with correct hour and minute")
    func makeWakeDateComponents() {
        let date = SleepViewModel.makeWakeDate(hour: 7, minute: 30)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("makeWakeDate at midnight")
    func makeWakeDateMidnight() {
        let date = SleepViewModel.makeWakeDate(hour: 0, minute: 0)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    @Test("makeWakeDate at 23:59")
    func makeWakeDateLateNight() {
        let date = SleepViewModel.makeWakeDate(hour: 23, minute: 59)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
    }
}

@Suite("SleepViewModel effectiveWakeDate")
struct EffectiveWakeDateTests {

    // Monday 2026-05-18
    let monday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 18
        return Calendar.current.date(from: c)!
    }()

    // Sunday 2026-05-17
    let sunday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 17
        return Calendar.current.date(from: c)!
    }()

    @Test("returns defaultWakeDate when schedule disabled")
    func returnsDefaultWhenDisabled() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = false
        vm.defaultWakeHour = 7
        vm.defaultWakeMinute = 30
        let result = vm.effectiveWakeDate(referenceDate: monday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("returns weekday time on weekday when schedule enabled")
    func returnsWeekdayTimeOnWeekday() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = true
        vm.weekdayWakeHour = 6
        vm.weekdayWakeMinute = 15
        vm.weekendWakeHour = 9
        vm.weekendWakeMinute = 0
        let result = vm.effectiveWakeDate(referenceDate: monday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 6)
        #expect(components.minute == 15)
    }

    @Test("returns weekend time on weekend when schedule enabled")
    func returnsWeekendTimeOnWeekend() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = true
        vm.weekdayWakeHour = 6
        vm.weekdayWakeMinute = 15
        vm.weekendWakeHour = 9
        vm.weekendWakeMinute = 0
        let result = vm.effectiveWakeDate(referenceDate: sunday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }
}

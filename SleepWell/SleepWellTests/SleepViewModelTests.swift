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

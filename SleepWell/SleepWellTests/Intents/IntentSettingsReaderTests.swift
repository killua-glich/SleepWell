import Testing
import Foundation
@testable import SleepWell

@Suite("IntentSettingsReader")
struct IntentSettingsReaderTests {

    func makeDefaults() -> UserDefaults {
        let suite = "com.highland.SleepWell.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("fallAsleepMinutes defaults to 14 when key absent")
    func fallAsleepMinutesDefault() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        #expect(reader.fallAsleepMinutes == 14)
    }

    @Test("fallAsleepMinutes reads stored value")
    func fallAsleepMinutesStored() {
        let d = makeDefaults()
        d.set(20, forKey: "fallAsleepMinutes")
        let reader = IntentSettingsReader(defaults: d)
        #expect(reader.fallAsleepMinutes == 20)
    }

    @Test("alarmLabel defaults to 'Wake Up' when key absent")
    func alarmLabelDefault() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        #expect(reader.alarmLabel == "Wake Up")
    }

    @Test("alarmLabel reads stored value")
    func alarmLabelStored() {
        let d = makeDefaults()
        d.set("Guten Morgen", forKey: "alarmLabel")
        let reader = IntentSettingsReader(defaults: d)
        #expect(reader.alarmLabel == "Guten Morgen")
    }

    @Test("effectiveWakeDate uses defaultWake when scheduleEnabled is false")
    func effectiveWakeDateUsesDefault() {
        let d = makeDefaults()
        d.set(false, forKey: "scheduleEnabled")
        d.set(7, forKey: "defaultWakeHour")
        d.set(30, forKey: "defaultWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: Date())
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("effectiveWakeDate uses weekendWake on weekends when scheduleEnabled")
    func effectiveWakeDateWeekend() throws {
        // Find a Saturday
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 7 // Saturday
        let saturday = try #require(Calendar.current.date(from: components))

        let d = makeDefaults()
        d.set(true, forKey: "scheduleEnabled")
        d.set(8, forKey: "weekendWakeHour")
        d.set(0, forKey: "weekendWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: saturday)
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(c.hour == 8)
        #expect(c.minute == 0)
    }

    @Test("effectiveWakeDate uses weekdayWake on weekdays when scheduleEnabled")
    func effectiveWakeDateWeekday() throws {
        // Find a Monday
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let monday = try #require(Calendar.current.date(from: components))

        let d = makeDefaults()
        d.set(true, forKey: "scheduleEnabled")
        d.set(6, forKey: "weekdayWakeHour")
        d.set(45, forKey: "weekdayWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: monday)
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(c.hour == 6)
        #expect(c.minute == 45)
    }

    @Test("defaultWakeHour defaults to 7 when key absent")
    func defaultWakeHourFallback() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        let date = reader.effectiveWakeDate(referenceDate: Date())
        let hour = Calendar.current.component(.hour, from: date)
        #expect(hour == 7)
    }
}

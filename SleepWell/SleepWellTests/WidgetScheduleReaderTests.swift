import XCTest
@testable import SleepWell

final class WidgetScheduleReaderTests: XCTestCase {
    private var defaults: UserDefaults!
    private var reader: WidgetScheduleReader!
    private let suiteName = "com.test.WidgetScheduleReaderTests"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)!
        reader = WidgetScheduleReader(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - effectiveWakeTime

    func test_effectiveWakeTime_defaultsTo7AM_whenNothingSet() {
        let result = reader.effectiveWakeTime(for: weekday())
        let c = Calendar.current.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(c.hour, 7)
        XCTAssertEqual(c.minute, 0)
    }

    func test_effectiveWakeTime_usesDefaultWakeTime_whenScheduleDisabled() {
        defaults.set(6, forKey: "defaultWakeHour")
        defaults.set(30, forKey: "defaultWakeMinute")
        defaults.set(false, forKey: "scheduleEnabled")
        let result = reader.effectiveWakeTime(for: weekday())
        let c = Calendar.current.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(c.hour, 6)
        XCTAssertEqual(c.minute, 30)
    }

    func test_effectiveWakeTime_usesWeekdayTime_onWeekday_whenScheduleEnabled() {
        defaults.set(true, forKey: "scheduleEnabled")
        defaults.set(6, forKey: "weekdayWakeHour")
        defaults.set(15, forKey: "weekdayWakeMinute")
        defaults.set(9, forKey: "weekendWakeHour")
        defaults.set(0, forKey: "weekendWakeMinute")
        let result = reader.effectiveWakeTime(for: weekday())
        let c = Calendar.current.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(c.hour, 6)
        XCTAssertEqual(c.minute, 15)
    }

    func test_effectiveWakeTime_usesWeekendTime_onWeekend_whenScheduleEnabled() {
        defaults.set(true, forKey: "scheduleEnabled")
        defaults.set(6, forKey: "weekdayWakeHour")
        defaults.set(0, forKey: "weekdayWakeMinute")
        defaults.set(9, forKey: "weekendWakeHour")
        defaults.set(30, forKey: "weekendWakeMinute")
        let result = reader.effectiveWakeTime(for: weekend())
        let c = Calendar.current.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 30)
    }

    func test_effectiveWakeTime_ignoresSchedule_onWeekend_whenScheduleDisabled() {
        defaults.set(false, forKey: "scheduleEnabled")
        defaults.set(7, forKey: "defaultWakeHour")
        defaults.set(0, forKey: "defaultWakeMinute")
        defaults.set(9, forKey: "weekendWakeHour")
        defaults.set(0, forKey: "weekendWakeMinute")
        let result = reader.effectiveWakeTime(for: weekend())
        let c = Calendar.current.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(c.hour, 7) // uses default, not weekend
    }

    // MARK: - bedtimes

    func test_bedtimes_returnsFourOptions() {
        XCTAssertEqual(reader.bedtimes(for: weekday()).count, 4)
    }

    func test_bedtimes_recommendedIs5Cycles() {
        let recommended = reader.bedtimes(for: weekday()).first(where: { $0.isRecommended })
        XCTAssertNotNil(recommended)
        XCTAssertEqual(recommended?.cycles, 5)
    }

    func test_bedtimes_usesFallAsleepMinutes_fromDefaults() {
        // With 0 min latency and 7:00 wake, 5-cycle bedtime = 7:00 - 7.5h = 23:30 previous night
        defaults.set(0, forKey: "fallAsleepMinutes")
        defaults.set(7, forKey: "defaultWakeHour")
        defaults.set(0, forKey: "defaultWakeMinute")
        let recommended = reader.bedtimes(for: weekday()).first(where: { $0.isRecommended })!
        let c = Calendar.current.dateComponents([.hour, .minute], from: recommended.bedtime)
        XCTAssertEqual(c.hour, 23)
        XCTAssertEqual(c.minute, 30)
    }

    // MARK: - Helpers

    /// Returns 2026-05-18 22:00 — a known Monday
    private func weekday() -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 18; c.hour = 22
        return Calendar.current.date(from: c)!
    }

    /// Returns 2026-05-16 22:00 — a known Saturday
    private func weekend() -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 16; c.hour = 22
        return Calendar.current.date(from: c)!
    }
}

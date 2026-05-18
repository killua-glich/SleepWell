import Testing
import Foundation
@testable import SleepWell

@Suite("SleepCalculator")
struct SleepCalculatorTests {

    let wakeTime: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 8
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }()

    @Test("returns 4 options")
    func returnsExactlyFourOptions() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        #expect(results.count == 4)
    }

    @Test("sorted 6 cycles first")
    func sortedByDescendingCycles() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        #expect(results.map(\.cycles) == [6, 5, 4, 3])
    }

    @Test("only 5-cycle option is recommended")
    func onlyFiveCyclesRecommended() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let recommended = results.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.cycles == 5)
    }

    @Test("6-cycle bedtime is 9h14m before wake with 14min latency")
    func sixCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        // 6 × 90 + 14 = 554 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-554 * 60)
        #expect(sixCycle.bedtime == expectedBedtime)
    }

    @Test("5-cycle bedtime is 7h44m before wake with 14min latency")
    func fiveCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        // 5 × 90 + 14 = 464 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-464 * 60)
        #expect(fiveCycle.bedtime == expectedBedtime)
    }

    @Test("totalSleepMinutes equals cycles × 90")
    func totalSleepMinutes() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        for option in results {
            #expect(option.totalSleepMinutes == option.cycles * 90)
        }
    }

    @Test("totalSleepFormatted for 7.5h")
    func totalSleepFormatted() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        #expect(fiveCycle.totalSleepFormatted == "7h 30m")
    }

    @Test("custom latency shifts bedtimes correctly")
    func customLatencyShiftsBedtimes() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 30)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        // 6 × 90 + 30 = 570 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-570 * 60)
        #expect(sixCycle.bedtime == expectedBedtime)
    }

    @Test("totalSleepFormatted for 20 minutes returns '20m'")
    func totalSleepFormattedSubHour() {
        let option = BedtimeOption(
            bedtime: Date(),
            totalSleepMinutes: 20,
            cycles: 0,
            isRecommended: false,
            napLabel: "Power Nap"
        )
        #expect(option.totalSleepFormatted == "20m")
        #expect(option.napLabel == "Power Nap")
    }

    @Test("totalSleepFormatted for 90 minutes returns '1h 30m'")
    func totalSleepFormattedNinetyMin() {
        let option = BedtimeOption(
            bedtime: Date(),
            totalSleepMinutes: 90,
            cycles: 1,
            isRecommended: false,
            napLabel: "Recovery Nap"
        )
        #expect(option.totalSleepFormatted == "1h 30m")
    }

    @Test("totalSleepFormatted for 360 minutes returns '6h'")
    func totalSleepFormattedExactHours() {
        let option = BedtimeOption(
            bedtime: Date(),
            totalSleepMinutes: 360,
            cycles: 4,
            isRecommended: false
        )
        #expect(option.totalSleepFormatted == "6h")
    }
}

@Suite("SleepCalculator reverse mode")
struct SleepCalculatorReverseModeTests {

    let sleepTime: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 1
        c.day = 1
        c.hour = 23
        c.minute = 0
        c.second = 0
        return Calendar.current.date(from: c)!
    }()

    @Test("returns 4 options")
    func returnsExactlyFourOptions() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        #expect(results.count == 4)
    }

    @Test("sorted 6 cycles first")
    func sortedByDescendingCycles() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        #expect(results.map(\.cycles) == [6, 5, 4, 3])
    }

    @Test("only 5-cycle option is recommended")
    func onlyFiveCyclesRecommended() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let recommended = results.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.cycles == 5)
    }

    @Test("6-cycle wake time is 9h14m after sleep with 14min latency")
    func sixCycleWakeTime() throws {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let sixCycle = try #require(results.first(where: { $0.cycles == 6 }))
        let expected = sleepTime.addingTimeInterval(554 * 60)
        #expect(sixCycle.bedtime == expected)
    }

    @Test("5-cycle wake time is 7h44m after sleep with 14min latency")
    func fiveCycleWakeTime() throws {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let fiveCycle = try #require(results.first(where: { $0.cycles == 5 }))
        let expected = sleepTime.addingTimeInterval(464 * 60)
        #expect(fiveCycle.bedtime == expected)
    }

    @Test("totalSleepMinutes equals cycles × 90")
    func totalSleepMinutes() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        for option in results {
            #expect(option.totalSleepMinutes == option.cycles * 90)
        }
    }

    @Test("custom latency shifts wake times correctly")
    func customLatencyShiftsWakeTimes() {
        // 30min latency + 6×90min = 570 minutes after sleepTime
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 30)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        let expected = sleepTime.addingTimeInterval(570 * 60)
        #expect(sixCycle.bedtime == expected)
    }

    @Test("totalSleepFormatted for 7.5h")
    func totalSleepFormatted() throws {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let fiveCycle = try #require(results.first(where: { $0.cycles == 5 }))
        #expect(fiveCycle.totalSleepFormatted == "7h 30m")
    }
}

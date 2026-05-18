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

@Suite("SleepCalculator nap mode")
struct SleepCalculatorNapModeTests {

    let napTime: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 1
        c.day = 1
        c.hour = 14
        c.minute = 0
        c.second = 0
        return Calendar.current.date(from: c)!
    }()

    @Test("returns exactly 2 options")
    func returnsExactlyTwoOptions() {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        #expect(results.count == 2)
    }

    @Test("first option is power nap — 20 minutes")
    func firstOptionIsPowerNap() {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        #expect(results[0].totalSleepMinutes == 20)
        #expect(results[0].napLabel == "Refreshing")
        #expect(results[0].isRecommended == false)
        #expect(results[0].cycles == 0)
    }

    @Test("second option is recovery nap — 90 minutes")
    func secondOptionIsRecoveryNap() {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        #expect(results[1].totalSleepMinutes == 90)
        #expect(results[1].napLabel == "Deep Rest")
        #expect(results[1].isRecommended == false)
        #expect(results[1].cycles == 1)
    }

    @Test("power nap wake time is napTime + latency + 20 min")
    func powerNapWakeTime() throws {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        let powerNap = try #require(results.first(where: { $0.totalSleepMinutes == 20 }))
        // 14 min latency + 20 min nap = 34 minutes after napTime
        let expected = napTime.addingTimeInterval(34 * 60)
        #expect(powerNap.bedtime == expected)
    }

    @Test("recovery nap wake time is napTime + latency + 90 min")
    func recoveryNapWakeTime() throws {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        let recoveryNap = try #require(results.first(where: { $0.totalSleepMinutes == 90 }))
        // 14 min latency + 90 min nap = 104 minutes after napTime
        let expected = napTime.addingTimeInterval(104 * 60)
        #expect(recoveryNap.bedtime == expected)
    }

    @Test("totalSleepFormatted for power nap is '20m'")
    func powerNapFormatted() throws {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        let powerNap = try #require(results.first(where: { $0.totalSleepMinutes == 20 }))
        #expect(powerNap.totalSleepFormatted == "20m")
    }

    @Test("totalSleepFormatted for recovery nap is '1h 30m'")
    func recoveryNapFormatted() throws {
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 14)
        let recoveryNap = try #require(results.first(where: { $0.totalSleepMinutes == 90 }))
        #expect(recoveryNap.totalSleepFormatted == "1h 30m")
    }

    @Test("custom latency shifts nap wake times correctly")
    func customLatencyShiftsNapWakeTimes() throws {
        // 30min latency + 20min nap = 50 minutes after napTime
        let results = SleepCalculator.calculateNapTimes(napTime: napTime, fallAsleepMinutes: 30)
        let powerNap = try #require(results.first(where: { $0.totalSleepMinutes == 20 }))
        let expected = napTime.addingTimeInterval(50 * 60)
        #expect(powerNap.bedtime == expected)
    }
}

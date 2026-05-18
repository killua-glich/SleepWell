import Testing
import Foundation
@testable import SleepWell

@Suite("SleepCalculator")
struct SleepCalculatorTests {

    // Fixed wake time: 8:00 AM on a reference date
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
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        #expect(results.count == 4)
    }

    @Test("sorted 6 cycles first")
    func sortedByDescendingCycles() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        #expect(results.map(\.cycles) == [6, 5, 4, 3])
    }

    @Test("only 5-cycle option is recommended")
    func onlyFiveCyclesRecommended() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        let recommended = results.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.cycles == 5)
    }

    @Test("6-cycle bedtime is 9h14m before wake")
    func sixCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        // 6 × 90 + 14 = 554 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-554 * 60)
        #expect(sixCycle.bedtime == expectedBedtime)
    }

    @Test("5-cycle bedtime is 7h44m before wake")
    func fiveCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        // 5 × 90 + 14 = 464 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-464 * 60)
        #expect(fiveCycle.bedtime == expectedBedtime)
    }

    @Test("totalSleepMinutes equals cycles × 90")
    func totalSleepMinutes() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        for option in results {
            #expect(option.totalSleepMinutes == option.cycles * 90)
        }
    }

    @Test("totalSleepFormatted for 7.5h")
    func totalSleepFormatted() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        #expect(fiveCycle.totalSleepFormatted == "7h 30m")
    }
}

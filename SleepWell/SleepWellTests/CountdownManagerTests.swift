// SleepWell/SleepWellTests/CountdownManagerTests.swift
import Testing
import Foundation
@testable import SleepWell

@Suite("CountdownManager state")
@MainActor
struct CountdownManagerTests {

    @Test("starts inactive")
    func startsInactive() {
        let manager = CountdownManager()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }

    @Test("start sets isActive and targetBedtime")
    func startSetsState() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(3 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        #expect(manager.isActive)
        #expect(manager.targetBedtime == bedtime)
    }

    @Test("cancel clears state")
    func cancelClearsState() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(3 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        await manager.cancel()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }

    @Test("handleForeground with >1h remaining stays active")
    func handleForegroundMoreThanOneHour() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(2 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        await manager.handleForeground()
        #expect(manager.isActive)
    }

    @Test("handleForeground with past bedtime ends countdown")
    func handleForegroundPastBedtime() async {
        let manager = CountdownManager()
        let pastBedtime = Date().addingTimeInterval(-60) // 1 minute ago
        await manager.startForTesting(bedtime: pastBedtime)
        await manager.handleForeground()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }
}

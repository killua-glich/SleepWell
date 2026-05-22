import Testing
import Foundation
@testable import SleepWell

@Suite("ScheduledAlarmStore")
struct ScheduledAlarmStoreTests {

    // Use a fresh in-memory defaults for each test
    func makeStore() -> ScheduledAlarmStore {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return ScheduledAlarmStore(defaults: defaults)
    }

    @Test("starts empty")
    func startsEmpty() {
        #expect(makeStore().all().isEmpty)
    }

    @Test("add and retrieve alarm")
    func addAndRetrieve() throws {
        let store = makeStore()
        let alarm = ScheduledAlarm(id: UUID(), date: Date(), label: "Wake Up")
        store.add(alarm)
        let all = store.all()
        #expect(all.count == 1)
        #expect(all[0].id == alarm.id)
        #expect(all[0].label == "Wake Up")
    }

    @Test("remove by id")
    func removeById() {
        let store = makeStore()
        let a = ScheduledAlarm(id: UUID(), date: Date(), label: "A")
        let b = ScheduledAlarm(id: UUID(), date: Date(), label: "B")
        store.add(a)
        store.add(b)
        store.remove(id: a.id)
        let all = store.all()
        #expect(all.count == 1)
        #expect(all[0].id == b.id)
    }

    @Test("removeAll clears store")
    func removeAllClears() {
        let store = makeStore()
        store.add(ScheduledAlarm(id: UUID(), date: Date(), label: "A"))
        store.add(ScheduledAlarm(id: UUID(), date: Date(), label: "B"))
        store.removeAll()
        #expect(store.all().isEmpty)
    }
}

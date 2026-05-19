import EventKit

enum AlarmResult {
    case scheduled
    case denied
    case failed(Error)
}

@MainActor
final class AlarmScheduler {
    private let store = EKEventStore()

    func schedule(at date: Date, title: String = "Time to wake up") async -> AlarmResult {
        do {
            let granted = try await store.requestFullAccessToEvents()
            guard granted else { return .denied }
        } catch {
            return .failed(error)
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = date
        event.endDate = date.addingTimeInterval(3600)
        event.calendar = store.defaultCalendarForNewEvents
        event.addAlarm(EKAlarm(absoluteDate: date))

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return .scheduled
        } catch {
            return .failed(error)
        }
    }
}

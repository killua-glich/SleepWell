import AlarmKit
import SwiftUI

@available(iOS 26, *)
struct SleepAlarmMetadata: AlarmMetadata {}

enum AlarmResult {
    case scheduled
    case denied
    case unsupportedOS
    case failed(Error)
}

@MainActor
final class AlarmScheduler {
    func schedule(at date: Date, label: String = "Time to wake up") async -> AlarmResult {
        guard #available(iOS 26, *) else {
            return .unsupportedOS
        }

        let manager = AlarmManager.shared

        do {
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { return .denied }
        } catch {
            return .failed(error)
        }

        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: label))
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes<SleepAlarmMetadata>(
            presentation: presentation,
            tintColor: Color.accentColor
        )
        let config = AlarmManager.AlarmConfiguration<SleepAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes
        )

        do {
            _ = try await manager.schedule(id: UUID(), configuration: config)
            return .scheduled
        } catch {
            return .failed(error)
        }
    }
}

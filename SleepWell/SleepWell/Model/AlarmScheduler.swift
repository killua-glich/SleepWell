import AlarmKit
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.highland.SleepWell", category: "AlarmScheduler")

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
        logger.info("schedule() called for date: \(date)")

        guard #available(iOS 26, *) else {
            logger.warning("iOS version too old for AlarmKit")
            return .unsupportedOS
        }

        let manager = AlarmManager.shared

        do {
            logger.info("Calling requestAuthorization()")
            let state = try await manager.requestAuthorization()
            logger.info("requestAuthorization() returned: \(String(describing: state))")
            guard state == .authorized else {
                logger.warning("Not authorized — state: \(String(describing: state))")
                return .denied
            }
        } catch {
            logger.error("requestAuthorization() threw: \(error)")
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
            logger.info("Scheduling alarm at \(date)")
            _ = try await manager.schedule(id: UUID(), configuration: config)
            logger.info("Alarm scheduled successfully")
            return .scheduled
        } catch {
            logger.error("schedule() threw: \(error)")
            return .failed(error)
        }
    }
}

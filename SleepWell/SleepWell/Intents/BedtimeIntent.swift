import AppIntents
import Foundation

struct BedtimeIntent: AppIntent {
    static let title: LocalizedStringResource = "When should I go to sleep?"
    static let description = IntentDescription(
        "Returns your recommended bedtime based on your wake schedule."
    )

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reader = IntentSettingsReader()
        let wakeTime = reader.effectiveWakeDate()
        let options = SleepCalculator.calculate(
            wakeTime: wakeTime,
            fallAsleepMinutes: reader.fallAsleepMinutes
        )

        guard let recommended = options.first(where: { $0.isRecommended }) else {
            return .result(dialog: "I couldn't calculate a bedtime right now.")
        }

        let timeString = recommended.bedtime.formatted(date: .omitted, time: .shortened)

        try await requestConfirmation(
            result: .result(dialog: IntentDialog(
                "You should go to sleep at \(timeString) for \(recommended.totalSleepFormatted) of sleep. Want me to set the alarm?"
            ))
        )

        let alarmResult = await AlarmScheduler().schedule(
            at: recommended.bedtime,
            label: reader.alarmLabel
        )

        switch alarmResult {
        case .scheduled:
            return .result(dialog: "Alarm set for \(timeString). Sleep well!")
        case .denied:
            return .result(dialog: "I couldn't set the alarm — please open SleepWell to grant permission.")
        case .unsupportedOS:
            return .result(dialog: "Setting alarms requires iOS 26 or later.")
        case .failed(_):
            return .result(dialog: "Something went wrong setting the alarm.")
        }
    }
}

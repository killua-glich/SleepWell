import AppIntents
import Foundation

struct NapIntent: AppIntent {
    static let title: LocalizedStringResource = "Take a nap"
    static let description = IntentDescription(
        "Calculates your nap alarm time and optionally sets it."
    )

    @Parameter(
        title: "Nap type",
        requestValueDialog: "Power nap (20 minutes) or deep rest (90 minutes)?"
    )
    var napType: NapType

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reader = IntentSettingsReader()
        let options = SleepCalculator.calculateNapTimes(
            napTime: Date(),
            fallAsleepMinutes: reader.fallAsleepMinutes
        )

        let targetMinutes = napType == .power ? 20 : 90
        guard let option = options.first(where: { $0.totalSleepMinutes == targetMinutes }) else {
            return .result(dialog: "I couldn't calculate a nap time right now.")
        }

        let timeString = option.bedtime.formatted(date: .omitted, time: .shortened)
        let napLabel = napType == .power ? "power nap" : "deep rest"

        try await requestConfirmation(
            result: .result(dialog: IntentDialog(
                "Your \(napLabel) alarm is at \(timeString). Want me to set it?"
            ))
        )

        let alarmResult = await AlarmScheduler().schedule(
            at: option.bedtime,
            label: reader.alarmLabel
        )

        switch alarmResult {
        case .scheduled:
            return .result(dialog: "Nap alarm set for \(timeString). Enjoy your \(napLabel)!")
        case .denied:
            return .result(dialog: "I couldn't set the alarm — please open SleepWell to grant permission.")
        case .unsupportedOS:
            return .result(dialog: "Setting alarms requires iOS 26 or later.")
        case .failed(_):
            return .result(dialog: "Something went wrong setting the alarm.")
        }
    }
}

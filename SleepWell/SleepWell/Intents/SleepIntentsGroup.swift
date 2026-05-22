import AppIntents

struct SleepIntentsGroup: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BedtimeIntent(),
            phrases: [
                "When should I go to sleep in \(.applicationName)",
                "When should I go to bed in \(.applicationName)",
                "What time should I sleep in \(.applicationName)"
            ],
            shortTitle: "Bedtime",
            systemImageName: "moon.zzz"
        )
        AppShortcut(
            intent: SleepNowIntent(),
            phrases: [
                "When should I wake up if I sleep now in \(.applicationName)",
                "Sleep now wake time in \(.applicationName)"
            ],
            shortTitle: "Sleep Now",
            systemImageName: "bed.double"
        )
        AppShortcut(
            intent: NapIntent(),
            phrases: [
                "I'm taking a nap in \(.applicationName)",
                "Take a nap in \(.applicationName)",
                "Start a nap in \(.applicationName)"
            ],
            shortTitle: "Nap",
            systemImageName: "timer"
        )
    }
}

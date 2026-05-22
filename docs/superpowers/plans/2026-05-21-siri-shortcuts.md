# Siri Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three Siri Shortcuts to SleepWell — bedtime, sleep-now, and nap — each speaking the result and offering to set an alarm.

**Architecture:** Three `AppIntent` structs share a lightweight `IntentSettingsReader` helper that reads App Group `UserDefaults` and calls `SleepCalculator` directly (no ViewModel or UI dependency). A `NapType` `AppEnum` lets Siri ask "Power nap or deep rest?" when the user doesn't specify. An `AppShortcutsProvider` registers all three phrases for Siri and the Shortcuts app.

**Tech Stack:** App Intents (iOS 16+), Swift Testing, AlarmKit (iOS 26+), UserDefaults (App Group suite `group.com.highland.SleepWell`)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `SleepWell/Intents/IntentSettingsReader.swift` | Create | Read App Group defaults, compute effective wake date |
| `SleepWell/Intents/NapType.swift` | Create | `AppEnum` for power/deep nap choice |
| `SleepWell/Intents/BedtimeIntent.swift` | Create | "When should I go to sleep?" |
| `SleepWell/Intents/SleepNowIntent.swift` | Create | "When should I wake up if I sleep now?" |
| `SleepWell/Intents/NapIntent.swift` | Create | "I'm taking a nap now" |
| `SleepWell/Intents/SleepIntentsGroup.swift` | Create | `AppShortcutsProvider` — registers all Siri phrases |
| `SleepWellTests/Intents/IntentSettingsReaderTests.swift` | Create | Unit tests for settings reader |

> **Xcode note:** After creating each file, add it to the **SleepWell** target in Xcode (File → Add Files, or drag into the project navigator). The test file goes into **SleepWellTests**.

---

## Task 1: IntentSettingsReader

Reads App Group `UserDefaults` and computes the effective wake date. Mirrors `SleepViewModel.effectiveWakeDate()` but without `@Observable` or `@AppStorage` — safe to call from an App Intents context.

**Files:**
- Create: `SleepWell/Intents/IntentSettingsReader.swift`
- Create: `SleepWellTests/Intents/IntentSettingsReaderTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// SleepWellTests/Intents/IntentSettingsReaderTests.swift
import Testing
import Foundation
@testable import SleepWell

@Suite("IntentSettingsReader")
struct IntentSettingsReaderTests {

    func makeDefaults() -> UserDefaults {
        let suite = "com.highland.SleepWell.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("fallAsleepMinutes defaults to 14 when key absent")
    func fallAsleepMinutesDefault() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        #expect(reader.fallAsleepMinutes == 14)
    }

    @Test("fallAsleepMinutes reads stored value")
    func fallAsleepMinutesStored() {
        let d = makeDefaults()
        d.set(20, forKey: "fallAsleepMinutes")
        let reader = IntentSettingsReader(defaults: d)
        #expect(reader.fallAsleepMinutes == 20)
    }

    @Test("alarmLabel defaults to 'Wake Up' when key absent")
    func alarmLabelDefault() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        #expect(reader.alarmLabel == "Wake Up")
    }

    @Test("alarmLabel reads stored value")
    func alarmLabelStored() {
        let d = makeDefaults()
        d.set("Guten Morgen", forKey: "alarmLabel")
        let reader = IntentSettingsReader(defaults: d)
        #expect(reader.alarmLabel == "Guten Morgen")
    }

    @Test("effectiveWakeDate uses defaultWake when scheduleEnabled is false")
    func effectiveWakeDateUsesDefault() {
        let d = makeDefaults()
        d.set(false, forKey: "scheduleEnabled")
        d.set(7, forKey: "defaultWakeHour")
        d.set(30, forKey: "defaultWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: Date())
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("effectiveWakeDate uses weekendWake on weekends when scheduleEnabled")
    func effectiveWakeDateWeekend() throws {
        // Find a Saturday
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 7 // Saturday
        let saturday = try #require(Calendar.current.date(from: components))

        let d = makeDefaults()
        d.set(true, forKey: "scheduleEnabled")
        d.set(8, forKey: "weekendWakeHour")
        d.set(0, forKey: "weekendWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: saturday)
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(c.hour == 8)
        #expect(c.minute == 0)
    }

    @Test("effectiveWakeDate uses weekdayWake on weekdays when scheduleEnabled")
    func effectiveWakeDateWeekday() throws {
        // Find a Monday
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let monday = try #require(Calendar.current.date(from: components))

        let d = makeDefaults()
        d.set(true, forKey: "scheduleEnabled")
        d.set(6, forKey: "weekdayWakeHour")
        d.set(45, forKey: "weekdayWakeMinute")
        let reader = IntentSettingsReader(defaults: d)
        let date = reader.effectiveWakeDate(referenceDate: monday)
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(c.hour == 6)
        #expect(c.minute == 45)
    }

    @Test("defaultWakeHour defaults to 7 when key absent")
    func defaultWakeHourFallback() {
        let reader = IntentSettingsReader(defaults: makeDefaults())
        let date = reader.effectiveWakeDate(referenceDate: Date())
        let hour = Calendar.current.component(.hour, from: date)
        #expect(hour == 7)
    }
}
```

- [ ] **Step 2: Run to verify tests fail**

```
xcodebuild test -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: compile error — `IntentSettingsReader` not found.

- [ ] **Step 3: Implement IntentSettingsReader**

```swift
// SleepWell/Intents/IntentSettingsReader.swift
import Foundation

struct IntentSettingsReader {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
    }

    var fallAsleepMinutes: Int {
        int(forKey: "fallAsleepMinutes", default: 14)
    }

    var alarmLabel: String {
        defaults.string(forKey: "alarmLabel") ?? "Wake Up"
    }

    func effectiveWakeDate(referenceDate: Date = Date()) -> Date {
        let scheduleEnabled = defaults.bool(forKey: "scheduleEnabled")
        let hour: Int
        let minute: Int
        if scheduleEnabled && Calendar.current.isDateInWeekend(referenceDate) {
            hour   = int(forKey: "weekendWakeHour",   default: 8)
            minute = int(forKey: "weekendWakeMinute", default: 0)
        } else if scheduleEnabled {
            hour   = int(forKey: "weekdayWakeHour",   default: 7)
            minute = int(forKey: "weekdayWakeMinute", default: 0)
        } else {
            hour   = int(forKey: "defaultWakeHour",   default: 7)
            minute = int(forKey: "defaultWakeMinute", default: 0)
        }
        return makeWakeDate(hour: hour, minute: minute)
    }

    // MARK: - Private

    private func int(forKey key: String, default defaultValue: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.integer(forKey: key)
    }

    private func makeWakeDate(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour   = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
xcodebuild test -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: all `IntentSettingsReaderTests` pass.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/Intents/IntentSettingsReader.swift SleepWellTests/Intents/IntentSettingsReaderTests.swift
git commit -m "Add IntentSettingsReader for Siri Shortcut context"
```

---

## Task 2: NapType AppEnum

Defines the power/deep nap choice as an `AppEnum` so Siri can ask "Power nap or deep rest?" when the user doesn't specify.

**Files:**
- Create: `SleepWell/Intents/NapType.swift`

- [ ] **Step 1: Create NapType**

```swift
// SleepWell/Intents/NapType.swift
import AppIntents

enum NapType: String, AppEnum {
    case power
    case deep

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Nap Type"

    static let caseDisplayRepresentations: [NapType: DisplayRepresentation] = [
        .power: "Power nap (20 minutes)",
        .deep: "Deep rest (90 minutes)"
    ]
}
```

No tests needed — this is pure enum metadata with no logic.

- [ ] **Step 2: Build to verify no errors**

```
xcodebuild build -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/Intents/NapType.swift
git commit -m "Add NapType AppEnum for Siri nap intent"
```

---

## Task 3: BedtimeIntent

"When should I go to sleep tonight?" — computes recommended bedtime from saved wake schedule, speaks it, confirms alarm.

**Files:**
- Create: `SleepWell/Intents/BedtimeIntent.swift`

- [ ] **Step 1: Create BedtimeIntent**

```swift
// SleepWell/Intents/BedtimeIntent.swift
import AppIntents
import Foundation

struct BedtimeIntent: AppIntent {
    static let title: LocalizedStringResource = "When should I go to sleep?"
    static let description = IntentDescription(
        "Returns your recommended bedtime based on your wake schedule."
    )

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
        case .failed:
            return .result(dialog: "Something went wrong setting the alarm.")
        }
    }
}
```

- [ ] **Step 2: Build**

```
xcodebuild build -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/Intents/BedtimeIntent.swift
git commit -m "Add BedtimeIntent Siri Shortcut"
```

---

## Task 4: SleepNowIntent

"When should I wake up if I sleep now?" — computes wake times from current time.

**Files:**
- Create: `SleepWell/Intents/SleepNowIntent.swift`

- [ ] **Step 1: Create SleepNowIntent**

```swift
// SleepWell/Intents/SleepNowIntent.swift
import AppIntents
import Foundation

struct SleepNowIntent: AppIntent {
    static let title: LocalizedStringResource = "When should I wake up if I sleep now?"
    static let description = IntentDescription(
        "Calculates optimal wake times if you fall asleep right now."
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reader = IntentSettingsReader()
        let options = SleepCalculator.calculateWakeTimes(
            sleepTime: Date(),
            fallAsleepMinutes: reader.fallAsleepMinutes
        )

        guard let recommended = options.first(where: { $0.isRecommended }) else {
            return .result(dialog: "I couldn't calculate a wake time right now.")
        }

        let timeString = recommended.bedtime.formatted(date: .omitted, time: .shortened)

        try await requestConfirmation(
            result: .result(dialog: IntentDialog(
                "If you sleep now, wake up at \(timeString) for \(recommended.totalSleepFormatted) of sleep. Want me to set the alarm?"
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
        case .failed:
            return .result(dialog: "Something went wrong setting the alarm.")
        }
    }
}
```

- [ ] **Step 2: Build**

```
xcodebuild build -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/Intents/SleepNowIntent.swift
git commit -m "Add SleepNowIntent Siri Shortcut"
```

---

## Task 5: NapIntent

"I'm taking a nap now" — asks power vs deep, speaks result, confirms alarm.

**Files:**
- Create: `SleepWell/Intents/NapIntent.swift`

- [ ] **Step 1: Create NapIntent**

```swift
// SleepWell/Intents/NapIntent.swift
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
        case .failed:
            return .result(dialog: "Something went wrong setting the alarm.")
        }
    }
}
```

- [ ] **Step 2: Build**

```
xcodebuild build -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/Intents/NapIntent.swift
git commit -m "Add NapIntent Siri Shortcut"
```

---

## Task 6: SleepIntentsGroup — AppShortcutsProvider

Registers all three intents with Siri phrases and the Shortcuts app. Phrases must include the app name placeholder `.applicationName`.

**Files:**
- Create: `SleepWell/Intents/SleepIntentsGroup.swift`

- [ ] **Step 1: Create SleepIntentsGroup**

```swift
// SleepWell/Intents/SleepIntentsGroup.swift
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
```

- [ ] **Step 2: Build**

```
xcodebuild build -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/Intents/SleepIntentsGroup.swift
git commit -m "Register Siri Shortcut phrases via AppShortcutsProvider"
```

---

## Task 7: Verify on Device / Simulator

App Intents are auto-discovered — no manual registration in `SleepWellApp.swift` needed.

- [ ] **Step 1: Run app on simulator**

```
xcodebuild run -project SleepWell.xcodeproj -scheme SleepWell -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] **Step 2: Check Shortcuts app**

Open **Shortcuts app** → **App Shortcuts** section → verify SleepWell appears with Bedtime, Sleep Now, and Nap shortcuts listed.

- [ ] **Step 3: Test via Siri on device**

Say "When should I go to sleep in SleepWell" — verify Siri speaks back a bedtime and prompts for alarm confirmation.

- [ ] **Step 4: Backlog update**

Mark `Siri Shortcuts` as done in `wakeupCycle/BACKLOG.md`:

```markdown
- [x] Siri Shortcuts — "Hey Siri, when should I go to sleep tonight?" returns recommended bedtime based on default wake-up schedule
```

- [ ] **Step 5: Final commit**

```bash
git add wakeupCycle/BACKLOG.md
git commit -m "Mark Siri Shortcuts as complete in backlog"
```

---

## Localization Notes (pre-release)

All dialog strings in the intents use Swift string interpolation, which does not automatically use `LocalizableStringResource`. When the localization pass happens:

1. Replace bare string literals in `.result(dialog: "...")` with `LocalizableStringResource("...", table: "Intents")`
2. Add `Intents.strings` files per locale under `SleepWell/Intents/`
3. Add translated phrases to `SleepIntentsGroup.appShortcuts` phrases arrays per locale

This is out of scope for this plan — tracked in the pre-release backlog.

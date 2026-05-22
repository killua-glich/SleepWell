# Siri Shortcuts — Design Spec
_Date: 2026-05-21_

## Overview

Add three Siri Shortcuts to SleepWell using the **App Intents framework** (iOS 16+). Each intent reads the user's saved schedule, runs the existing `SleepCalculator`, speaks the result, and offers to set an alarm via `requestConfirmation()`.

All user-facing strings use `LocalizableStringResource` — ready for future locale `.strings` files (pre-release localization backlog item).

---

## Intents

### 1. `BedtimeIntent`
**Phrase:** "When should I go to sleep tonight?"
- Reads `effectiveWakeDate()` logic from App Group UserDefaults (auto-detects weekday vs weekend)
- Calls `SleepCalculator.calculate(wakeTime:fallAsleepMinutes:)`
- Picks the `isRecommended == true` option (5 cycles)
- Speaks: "You should go to sleep at [time] for 7.5 hours of sleep."
- Confirms: "Want me to set a bedtime alarm?" → `AlarmScheduler().schedule(at: option.bedtime, label: alarmLabel)` on `@MainActor`

### 2. `SleepNowIntent`
**Phrase:** "When should I wake up if I sleep now?"
- Calls `SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes:)`
- Picks the `isRecommended == true` option (5 cycles)
- Speaks: "If you sleep now, wake up at [time] for 7.5 hours of sleep."
- Confirms: "Want me to set a wake-up alarm?" → `AlarmScheduler().schedule(at: option.bedtime, label: alarmLabel)` on `@MainActor`

### 3. `NapIntent`
**Phrase:** "I'm taking a nap now" / "Take a nap"
- Asks follow-up: "Power nap (20 minutes) or deep rest (90 minutes)?" unless nap type supplied in phrase
- Calls `SleepCalculator.calculateNapTimes(napTime: Date(), fallAsleepMinutes:)`
- Picks the matching `BedtimeOption` by `totalSleepMinutes`
- Speaks: "Your [power nap / deep rest] alarm is at [time]."
- Confirms: "Want me to set the alarm?" → `AlarmScheduler().schedule(at: option.bedtime, label: alarmLabel)` on `@MainActor`

---

## Architecture

- **Location:** `SleepWell/Intents/` — new folder inside the main app target. No separate extension required for App Intents.
- **Files:**
  - `BedtimeIntent.swift`
  - `SleepNowIntent.swift`
  - `NapIntent.swift`
  - `SleepIntentsGroup.swift` — `AppShortcutsProvider` grouping all three for Shortcuts app visibility
- **No ViewModel dependency** — intents run out-of-process; access UserDefaults directly via `UserDefaults(suiteName: AppGroup.identifier)`
- **Reuses existing:** `SleepCalculator` (pure static), `AlarmScheduler`, `AppGroup`

---

## Data Flow

```
Siri trigger
  → AppIntent.perform()
  → UserDefaults(appGroup) → fallAsleepMinutes, wake schedule settings
  → SleepCalculator.calculate*() → [BedtimeOption]
  → pick recommended BedtimeOption
  → NapIntent only: requestConfirmation for nap type
  → speak result via .result(dialog:)
  → requestConfirmation("Set alarm?")
  → await MainActor.run { AlarmScheduler().schedule(at: option.bedtime, label: alarmLabel) } on confirm
```

---

## Localization

- All dialog strings: `LocalizableStringResource`
- Intent `title` and `description`: `LocalizableStringResource`
- Phrase synonyms per locale added to `AppShortcuts` phrases array
- `.strings` files per locale added in pre-release localization pass

---

## Error Handling

| Scenario | Behavior |
|---|---|
| No App Group data (first launch) | Fall back to defaults: 14 min latency, 7:00 AM wake |
| AlarmKit not authorized | Speak: "I couldn't set the alarm — please open SleepWell to grant permission" |
| Bedtime already passed | Return results anyway — user decides, same as app behavior |
| Nap type in original phrase | Skip follow-up question, use matched type directly |

---

## Testing

- Unit tests for each intent's `perform()` using a test `UserDefaults` suite
- `AlarmScheduler` not called in unit tests — verified via protocol/mock or separate integration test
- Follows existing pattern in `SleepCalculatorTests` and `SleepViewModelTests`

---

## Out of Scope

- HealthKit integration (pending Apple Watch availability)
- Live Activities / Dynamic Island (separate backlog item)
- Custom wake time override in Siri phrase (uses today's schedule only)

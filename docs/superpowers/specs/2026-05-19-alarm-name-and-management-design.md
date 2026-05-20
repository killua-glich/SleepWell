# Alarm Name & Management Design

**Goal:** Let users set a default alarm label and delete all scheduled AlarmKit alarms from Settings.

**Architecture:** Minimal — one new `@AppStorage` key threaded through existing alarm-scheduling call, plus a new Settings section with a text field and a destructive clear button.

**Tech Stack:** SwiftUI, AlarmKit (iOS 26+), `@AppStorage`

---

## Data Layer

- Add `@AppStorage("alarmLabel") var alarmLabel: String = "Wake Up"` to `SleepViewModel`
- `BedtimeResultsView` passes `viewModel.alarmLabel` to `alarmScheduler.schedule(at:label:)`
- `AlarmScheduler.schedule(at:label:)` already accepts a `label` parameter — no changes needed

## Settings UI

New **ALARMS** section added to `SettingsView` (placed above the SCHEDULE section).

### Alarm Name row
- Label: "Alarm Name"
- `TextField` bound to `alarmLabel` via `@AppStorage`
- Same visual style as existing settings rows

### Delete All Alarms button
- Destructive red button labeled "Delete All Alarms"
- Tapping shows a confirmation `Alert` before proceeding
- On confirm: fetches `(try? AlarmManager.shared.alarms) ?? []`, loops, calls `try? await AlarmManager.shared.cancel(id:)` for each
- Hidden entirely on iOS < 26 (`if #available(iOS 26, *)`)
- Shows a brief success/failure message via another alert after completion

## Files Changed

| File | Change |
|------|--------|
| `ViewModels/SleepViewModel.swift` | Add `@AppStorage("alarmLabel")` |
| `Views/SettingsView.swift` | Add ALARMS section with text field + delete button |
| `Views/BedtimeResultsView.swift` | Pass `viewModel.alarmLabel` to `schedule(at:label:)` |

## Out of Scope

- Per-alarm custom names (all alarms share the default label)
- Alarm list UI (view/cancel individual alarms)
- HealthKit sleep logging

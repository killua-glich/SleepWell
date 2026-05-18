# Custom Fall-Asleep Time — Design Spec

_Date: 2026-05-18_

## Goal

Replace the hardcoded 14-minute fall-asleep latency in `SleepCalculator` with a user-configurable value, persisted across sessions, accessible via a new Settings screen.

---

## Architecture

### `SleepCalculator` (Model)

- Remove the `static let fallAsleepLatency` constant.
- Update `calculate(wakeTime:)` to `calculate(wakeTime:fallAsleepMinutes:)` — latency passed as a parameter.
- Keeps the model pure and testable with any latency value.

### `SleepViewModel` (ViewModel)

- Add `@AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14`.
- Pass `fallAsleepMinutes` into `SleepCalculator.calculate()` in the `calculate()` method.

### `SettingsView` (New View)

- Pushed onto the existing `NavigationStack` from a gear icon in `WakeTimeInputView`'s toolbar.
- Contains a wheel-style picker for fall-asleep duration: **5–60 minutes, 1-minute steps**.
- Matches existing dark glass visual style (dark background, `ultraThinMaterial` containers, white text).
- Selection writes directly to `@AppStorage` via the ViewModel — no save button needed.

### `WakeTimeInputView` (Existing View)

- Add a `.toolbar` item with a gear `Image(systemName: "gearshape")` that navigates to `SettingsView`.

---

## Data Flow

```
User adjusts picker in SettingsView
    → @AppStorage("fallAsleepMinutes") updated immediately
    → SleepViewModel.fallAsleepMinutes reflects new value
    → Next calculate() call uses updated latency
```

---

## Persistence

`@AppStorage("fallAsleepMinutes")` — standard `UserDefaults` under the hood. No keychain, no custom store. Default: 14 minutes.

---

## Testing

- Update `SleepCalculatorTests` — pass explicit `fallAsleepMinutes` values, verify bedtime math.
- No UI tests needed for this change.

---

## Out of Scope

- Validation UI (5–60 range enforced by picker bounds, not code)
- iCloud sync
- Any other settings beyond fall-asleep time

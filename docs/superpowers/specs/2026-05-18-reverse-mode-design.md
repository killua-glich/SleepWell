# Reverse Mode — Design Spec
_2026-05-18_

## Overview

Add a "Sleep now" mode to SleepWell. Instead of picking a wake-up time, the user taps "Sleep now" and immediately gets optimal wake-up times based on the current time and their fall-asleep latency setting. Same 3–6 sleep cycle range as forward mode.

---

## Architecture

### `SleepCalculator`
Add a second static method alongside the existing `calculate(wakeTime:fallAsleepMinutes:)`:

```swift
static func calculateWakeTimes(sleepTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption]
```

- Adds fall-asleep latency to `sleepTime` to get actual sleep onset
- Returns 4 `BedtimeOption`s for 3, 4, 5, 6 cycles
- `BedtimeOption.bedtime` holds the wake-up time (field reused, no structural change)
- `isRecommended` remains `cycles == 5`

### `SleepViewModel`
Add:

```swift
enum Mode { case wakeUp, sleepNow }
var mode: Mode = .wakeUp
```

Update `calculate()` to branch on mode:
- `.wakeUp` → existing `SleepCalculator.calculate(wakeTime:fallAsleepMinutes:)`
- `.sleepNow` → new `SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes:)`

Add convenience method:
```swift
func calculateSleepNow() {
    mode = .sleepNow
    calculate()
}
```

---

## Views

### `WakeTimeInputView` (refactored into mode selector)
Replaces current picker-first layout with two large tappable options:
- **"Sleep now"** — calls `viewModel.calculateSleepNow()`, navigates to results
- **"Wake up at…"** — navigates to `WakeTimePickerView`

### `WakeTimePickerView` (new, extracted)
Current picker + calculate button, extracted verbatim from `WakeTimeInputView`. No logic changes.

### `BedtimeResultsView` (minor update)
Header adapts to `viewModel.mode`:
- `.wakeUp`: "WAKE UP AT [time]" / "Go to bed at…" (unchanged)
- `.sleepNow`: "SLEEPING NOW" / "Wake up at…"

Cards and alarm dialog unchanged.

---

## Data Flow

```
Sleep now tap
  → viewModel.calculateSleepNow()
      → mode = .sleepNow
      → SleepCalculator.calculateWakeTimes(sleepTime: Date(), ...)
      → bedtimes populated
      → showResults = true
  → navigate to BedtimeResultsView
```

```
Wake up at tap
  → navigate to WakeTimePickerView
      → user picks time
      → viewModel.calculate() [mode = .wakeUp]
      → navigate to BedtimeResultsView
```

---

## Testing

- `SleepCalculatorTests`: add tests for `calculateWakeTimes` — verify onset offset applied, correct cycle durations, `isRecommended` on 5-cycle option
- `SleepViewModel`: verify `calculateSleepNow()` sets mode and populates `bedtimes`
- No UI tests required for this change

---

## Out of Scope

- Adjustable sleep time for reverse mode (user always uses current time)
- Different visual style for reverse mode results

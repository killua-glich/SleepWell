# Nap Mode — Design Spec
_2026-05-18_

## Overview

Add a "Take a Nap" mode to SleepWell. User taps the card on the main screen and immediately sees two wake-up options: a 20-minute power nap and a 90-minute recovery nap (one full sleep cycle). Same alarm dialog flow as other modes.

---

## Architecture

### `BedtimeOption`
Add one new field with a default value so all existing call sites are unaffected:

```swift
let napLabel: String?  // nil for regular modes
```

Update `totalSleepFormatted` to handle sub-hour durations (currently assumes hours > 0):

```swift
var totalSleepFormatted: String {
    let hours = totalSleepMinutes / 60
    let minutes = totalSleepMinutes % 60
    if hours == 0 { return "\(minutes)m" }
    if minutes == 0 { return "\(hours) hrs" }
    return "\(hours)h \(minutes)m"
}
```

### `SleepCalculator`
Add:

```swift
static func calculateNapTimes(napTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption]
```

Returns exactly 2 options (sleep onset = napTime + latency):

| Label | `totalSleepMinutes` | `cycles` | `isRecommended` | `napLabel` |
|---|---|---|---|---|
| Power Nap | 20 | 0 | false | "Refreshing" |
| Recovery Nap | 90 | 1 | false | "Deep Rest" |

Wake-up time = sleep onset + `totalSleepMinutes`.

### `SleepMode`
Add `.nap` case:

```swift
enum SleepMode {
    case wakeUp, sleepNow, nap
}
```

### `SleepViewModel`
- `.nap` branch in `calculate()`: calls `SleepCalculator.calculateNapTimes(napTime: Date(), fallAsleepMinutes:)`
- Add `calculateNapNow()` convenience: sets `mode = .nap`, calls `calculate()`
- `reset()` already resets `mode = .wakeUp` — no change needed

---

## Views

### `BedtimeCard`
When `option.napLabel != nil`:
- Replace "X cycles" text + dots with a tag capsule showing the `napLabel` string
- No blue glow, no highlighted border — `isRecommended` is `false` for both nap options
- Duration (`totalSleepFormatted`) still shown as usual

### `BedtimeResultsView`
`headerEyebrow` adds `.nap` case → `"NAPPING NOW"`
`headerTitle` adds `.nap` case → `"Wake up at…"` (same as `.sleepNow`)

### `WakeTimeInputView`
Third mode card added below "Wake Up At…":

- Title: `"Take a Nap"`
- Subtitle: `"Power nap or full recovery"`
- Icon: `bed.double.fill`
- Action: `viewModel.calculateNapNow()`

---

## Data Flow

```
Take a Nap tap
  → viewModel.calculateNapNow()
      → mode = .nap
      → SleepCalculator.calculateNapTimes(napTime: Date(), ...)
      → bedtimes = [powerNap, recoveryNap]
      → showResults = true
  → BedtimeResultsView pushed
      → header: "NAPPING NOW" / "Wake up at…"
      → 2 cards with napLabel tags instead of cycle dots
      → tap card → alarm dialog → "Set alarm for X?"
```

---

## Testing

- `SleepCalculatorTests`: add `SleepCalculatorNapModeTests` suite
  - Returns exactly 2 options
  - Power nap wake time = napTime + latency + 20 min
  - Recovery nap wake time = napTime + latency + 90 min
  - `napLabel` values correct ("Refreshing", "Deep Rest")
  - `isRecommended` false for both
  - `totalSleepFormatted` for 20 min returns "20m"

---

## Out of Scope

- Custom nap duration picker
- Different fall-asleep latency for naps
- Nap-specific alarm sound or label

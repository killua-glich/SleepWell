# Wake-up Schedule — Design Spec

**Date:** 2026-05-19  
**Project:** SleepWell (wakeupCycle)  
**Status:** Approved

---

## Summary

Add a wake-up schedule to Settings that lets the user set separate default wake-up times for weekdays and weekends. A single toggle enables/disables the schedule. When enabled, the schedule times take priority over the existing single default wake-up time.

---

## Scope

- Settings screen only. The main "Wake Up At…" picker is unaffected.
- No per-day granularity — only weekday (Mon–Fri) and weekend (Sat–Sun).

---

## Data Layer (`SleepViewModel`)

Three new `@ObservationIgnored @AppStorage` properties:

| Key | Type | Default |
|-----|------|---------|
| `scheduleEnabled` | `Bool` | `false` |
| `weekdayWakeHour` | `Int` | `7` |
| `weekdayWakeMinute` | `Int` | `0` |
| `weekendWakeHour` | `Int` | `8` |
| `weekendWakeMinute` | `Int` | `0` |

New computed property `effectiveWakeDate: Date`:
- If `scheduleEnabled` is `true`, return the weekday or weekend time based on `Calendar.current.isDateInWeekend(Date())`.
- Otherwise return `defaultWakeDate`.

This property is the single source of truth for "what is the user's default wake-up time right now" — used by the widget (future).

---

## Settings UI (`SettingsView`)

### New section: SCHEDULE

Placed below the existing PREFERENCES card. Follows the identical visual pattern:
- Section label: `"SCHEDULE"` (same font/color/tracking as `"PREFERENCES"`)
- Card: `RoundedRectangle` with `.ultraThinMaterial` + white stroke, `cornerRadius: 20`, `padding(.horizontal, 24)`

### Card contents

1. **Toggle row** — label "Wake-up schedule", `Toggle` right-aligned. Tapping collapses any open picker before toggling.
2. When `scheduleEnabled` is `true`, with animation:
   - `Divider`
   - **Weekdays row** — expands to `DatePicker(.hourAndMinute)` wheel, same pattern as existing "Default wake-up" row
   - `Divider`
   - **Weekend row** — same

### `expanded` enum additions

```swift
case weekday, weekend
```

Tapping toggle while a picker is open: collapse picker first (set `expanded = nil`), then toggle `scheduleEnabled`.

### Animation

Same `.spring(response: 0.3, dampingFraction: 0.8)` used throughout the existing view. The two time rows use `.opacity.combined(with: .move(edge: .bottom))` transition, same as existing pickers.

---

## Out of Scope

- Per-day (Mon/Tue/…) granularity
- Auto-filling the "Wake Up At…" picker from schedule
- Widget implementation (separate backlog item)

# SleepWell Widget — Design Spec
_Date: 2026-05-20_

## Overview

WidgetKit extension for SleepWell. Shows recommended bedtime(s) based on the user's default wake schedule. Supports small, medium, and large sizes. Tapping any size opens the app directly to the bedtime results screen, pre-calculated for tonight.

---

## Architecture

### New Target
`SleepWellWidget` — a WidgetKit extension added to the existing Xcode project.

### Shared Code
`SleepCalculator.swift` and `BedtimeOption.swift` are added to both the app target and the widget target (same files, two memberships — no duplication).

### Data Sharing: App Group
Both targets share the entitlement `group.com.bence.SleepWell` (adjust to match Team ID).

The app's `@AppStorage` calls are updated to use `UserDefaults(suiteName: "group.com.bence.SleepWell")` so the widget can read the same values. Keys used:

| Key | Type | Default |
|---|---|---|
| `fallAsleepMinutes` | Int | 14 |
| `scheduleEnabled` | Bool | false |
| `defaultWakeHour` | Int | 7 |
| `defaultWakeMinute` | Int | 0 |
| `weekdayWakeHour` | Int | 7 |
| `weekdayWakeMinute` | Int | 0 |
| `weekendWakeHour` | Int | 8 |
| `weekendWakeMinute` | Int | 0 |

### Computation
Widget's `Provider.getTimeline()`:
1. Reads settings from shared `UserDefaults`
2. Determines tonight's effective wake time (weekday vs weekend, same logic as `SleepViewModel.effectiveWakeDate()`)
3. Calls `SleepCalculator.calculate(wakeTime:fallAsleepMinutes:)` → `[BedtimeOption]`
4. Returns a single `TimelineEntry` with `policy: .atEnd` pointing to next midnight

Widget recalculates automatically at midnight each day.

---

## Widget Sizes

### Small (`.systemSmall`)
Recommended bedtime only (5-cycle option). Everything centered.

- Label: "Go to bed" (small caps)
- Time: large bold `HH:MM` + `AM/PM` + duration (`7.5h sleep`)
- "Recommended" badge (indigo outline pill)
- 5 cycle dots (indigo, centered below badge)

### Medium (`.systemMedium`)
Recommended bedtime + tonight's wake time.

- Left side: same content as small
- Right side: "Wake up" label + effective wake time (e.g. `7:00 AM`) + 5 cycle dots right-aligned

### Large (`.systemLarge`)
All 4 bedtime options in a list.

- Header: "Bedtime options · Wake HH:MM AM/PM" (small caps)
- 4 rows (6, 5, 4, 3 cycles): time, duration/cycles, cycle dots
- 5-cycle row: subtle indigo background highlight + "Best" badge
- Cycle dots dim toward fewer cycles
- Footer: "Tap to open" (small caps)

---

## Visual Design

Follows existing app design tokens:

| Token | Value |
|---|---|
| Background | `linear-gradient(145deg, #1a1c2e, #12141f)` |
| Accent | `#4f6ef7` |
| Text primary | `#ffffff` |
| Text secondary | `rgba(255,255,255,0.5)` |
| Card background | `.ultraThinMaterial` (use WidgetKit background modifier) |
| Corner radius | `22pt` (system-managed for widgets) |
| Ambient glow | Radial gradient, indigo at 18% opacity, top-left |

Cycle dots: active = indigo + glow shadow; dim = indigo at 25% opacity, no shadow.

---

## Deep Link & Tap Behavior

All sizes use `widgetURL(URL(string: "sleepwell://results")!)`.

App registers the `sleepwell` URL scheme in `Info.plist`. `SleepWellApp.swift` handles `.onOpenURL` — calls `viewModel.calculateWakeUp()` (which uses `effectiveWakeDate()` internally) then sets `showResults = true`, pushing `BedtimeResultsView` via the existing `NavigationStack`.

No new views are needed in the app.

---

## Timeline & Refresh

- One `TimelineEntry` per refresh
- `TimelineReloadPolicy.atEnd` with next-midnight date
- Widget recalculates bedtimes each day at midnight
- No user-triggered refresh needed (settings changes don't require immediate widget reload — stale by at most one day, acceptable)

---

## Out of Scope

- Interactive widget controls (toggle, button inside widget)
- Lock screen / StandBy widget sizes (accessory families)
- HealthKit-driven wake time (separate backlog item)
- Widget configuration (intent-based customization)

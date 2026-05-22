# Live Activity — Bedtime Reminder Design

**Date:** 2026-05-22  
**Status:** Approved

---

## Overview

Add a bedtime countdown feature to the Wake Up mode. After setting an alarm, the user is offered an optional bedtime reminder — a Live Activity that runs silently in the background and surfaces a countdown on the Dynamic Island and lock screen as bedtime approaches.

A new Manager tab (tab bar) gives the user a single place to see and cancel active alarms and reminders.

---

## User Flow

1. User is in Wake Up mode, views bedtime options in `BedtimeResultsView`
2. Taps a `BedtimeCard` → existing alarm confirmation dialog: *"Set alarm for 11:30 PM?"* → **Set Alarm** / Cancel
3. Alarm set successfully → second prompt: *"Add a bedtime reminder?"* → **Remind Me** / Skip
4. **Remind Me** → `CountdownManager.start(bedtime:)` → Live Activity starts immediately in minimal state
5. User can cancel from the Manager tab at any time

This flow applies **only to Wake Up mode**. Sleep Now and Nap modes are unchanged.

---

## Tab Bar

Replace the current single-screen root with a `TabView`:

| Tab | Icon | Label |
|-----|------|-------|
| 0 | `house` (SF Symbol) | Sleep |
| 1 | `clock` (SF Symbol) | Manager |

**Style:** iOS 26 liquid glass floating pill tab bar (system default on iOS 26+).

---

## Manager Tab (`ManagerView`)

Settings-style layout with labeled sections. Sections only appear when they have content.

### REMINDERS section
- Shows active countdown card (indigo gradient, matching app palette)
- Displays live countdown (`1:43:00`) and target bedtime (`Bedtime at 11:30 PM`)
- **Cancel Reminder** button → calls `CountdownManager.cancel()`

### ALARMS section
- Lists scheduled alarms (time + label per row)
- Per-row **Cancel** (red, destructive)
- **Cancel All Alarms** destructive button below the list (moved from `SettingsView`)

### Empty state
- Shown when no active reminder and no scheduled alarms
- Icon: dimmed clock, text: "No alarms or timers"
- Subtext: "Set an alarm or bedtime reminder from the Sleep tab."

### `SettingsView` change
- Remove the existing "Delete All Alarms" button (it moves to Manager tab)

---

## Live Activity

### `BedtimeCountdownAttributes`

```swift
struct BedtimeCountdownAttributes: ActivityAttributes {
    let targetBedtime: Date

    struct ContentState: Codable, Hashable {
        var phase: CountdownPhase
    }
}

enum CountdownPhase: String, Codable {
    case active    // >1h remaining — minimal presence
    case imminent  // ≤1h remaining — full countdown visible
}
```

### Dynamic Island — Compact (both phases)

- Leading: moon SF Symbol
- Trailing: `BEDTIME` label + target time (e.g., `11:30`)
- Minimal: moon only

### Lock Screen — `.active` phase (>1h remaining)

Minimal thin bar. Unobtrusive — user is not yet in wind-down mode.

### Lock Screen — `.imminent` phase (≤1h remaining)

Full expanded widget:
- **Hero:** countdown timer (e.g., `48:00`) — large, bold
- **Below:** `Bedtime at 11:30 PM` — smaller, muted

---

## `CountdownManager`

`@Observable` class, injected into the SwiftUI environment.

### Responsibilities

- `start(bedtime: Date)` —
  1. Start Live Activity in `.active` phase
  2. Schedule silent `UNUserNotificationCenter` request at T−3h (no sound, no banner — notification centre only)
  3. Schedule 1h notification at T−1h: *"Your bedtime is in 1 hour — tap to open the countdown"* (gentle sound: `UNNotificationSound.default`). Tapping opens the app → `scenePhase` observer fires → phase transitions to `.imminent`
  4. Schedule bedtime notification at T=0: *"Time to sleep 🌙"* (gentle sound: `UNNotificationSound.default`)

- App foreground observer (`scenePhase == .active`) —
  - If activity running and time remaining ≤ 1h: update `ContentState.phase` to `.imminent`
  - If time remaining ≤ 0: call `end()`

- `end()` — end Live Activity with `.dismiss` policy, remove all pending notifications

- `cancel()` — same as `end()`, triggered by user

- Exposed state:
  - `isActive: Bool`
  - `targetBedtime: Date?`

### Threading
All activity updates on `MainActor`. Notification scheduling on background task via `Task`.

---

## `BedtimeResultsView` Changes

- After successful alarm schedule in Wake Up mode, present a second `.confirmationDialog`:
  - Title: `"Add a bedtime reminder?"`
  - **Remind Me** → `countdownManager.start(bedtime: option.bedtime)`
  - **Skip** → dismiss

- No changes to card layout or alarm flow.

---

## New Files

| File | Target | Purpose |
|------|--------|---------|
| `BedtimeCountdownAttributes.swift` | Live Activity extension | `ActivityAttributes` + `ContentState` |
| `BedtimeCountdownLiveActivity.swift` | Live Activity extension | Dynamic Island + lock screen views |
| `CountdownManager.swift` | Main app | Activity lifecycle + notifications |
| `ManagerView.swift` | Main app | Manager tab UI |

---

## Modified Files

| File | Change |
|------|--------|
| `SleepWellApp.swift` | Wrap root in `TabView`; inject `CountdownManager` into environment |
| `BedtimeResultsView.swift` | Add second confirmation dialog after alarm set (Wake Up mode only) |
| `SettingsView.swift` | Remove "Delete All Alarms" button |

---

## Known Limitations

- **Phase transition requires foreground:** The `.active` → `.imminent` transition is triggered by the `scenePhase` observer. The T−1h notification prompts the user to open the app, which triggers the transition. If the user dismisses the notification without opening the app, the lock screen widget stays in minimal layout until next foreground. The countdown time itself is always accurate (driven by `timerInterval`); only the visual expansion is delayed.

---

## Out of Scope

- HealthKit / Apple Watch integration (separate backlog item)
- Multiple simultaneous countdowns (one active reminder at a time)
- Widget updates driven by countdown state

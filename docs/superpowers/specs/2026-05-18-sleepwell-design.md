# SleepWell — Design Spec
_Date: 2026-05-18_

## Overview

iOS 26 SwiftUI app. User picks a wake-up time; app calculates 4 bedtime options based on sleep cycle science. Tapping a bedtime prompts to set an iOS Clock alarm.

**Target:** iOS 26+. No third-party dependencies. No persistence, HealthKit, notifications, or accounts.

---

## Sleep Logic

- One sleep cycle = 90 minutes
- Fall-asleep latency = 14 minutes
- Formula: `bedtime = wakeTime − (cycles × 90min) − 14min`
- Options: 6, 5, 4, 3 cycles (9h → 4.5h of sleep), sorted 6→3
- 5-cycle option (7.5h) is marked recommended

---

## Architecture

MVVM. One shared `SleepViewModel` injected via `@Environment`.

```
SleepWell/
├── SleepWellApp.swift
├── Model/
│   ├── SleepCalculator.swift      # pure static func, no SwiftUI imports
│   └── BedtimeOption.swift        # value type
├── ViewModels/
│   └── SleepViewModel.swift       # @Observable
└── Views/
    ├── WakeTimeInputView.swift
    ├── BedtimeResultsView.swift
    └── BedtimeCard.swift           # extracted subview
```

### SleepViewModel (`@Observable`)

```swift
var wakeTime: Date
var bedtimes: [BedtimeOption]       // empty until calculate() called
var selectedOption: BedtimeOption?  // non-nil → show confirmation dialog

func calculate()                    // populates bedtimes via SleepCalculator
```

Navigation: `NavigationStack` in app entry point. `WakeTimeInputView` pushes `BedtimeResultsView` when `bedtimes` is non-empty (driven by a `navigationDestination` on the stack).

---

## Data Model

### BedtimeOption

```swift
struct BedtimeOption: Identifiable {
    let id: UUID
    let bedtime: Date
    let totalSleep: Int    // minutes
    let cycles: Int        // 3–6
    let isRecommended: Bool
}
```

### SleepCalculator

```swift
struct SleepCalculator {
    static func calculate(wakeTime: Date) -> [BedtimeOption]
}
```

Iterates `[6, 5, 4, 3]`, applies formula, flags `cycles == 5` as recommended.

---

## Screens

### WakeTimeInputView

- Full-screen dark gradient: `#0b0d14` → `#090b16`
- Indigo ambient radial glow centered behind picker
- `DatePicker` wheel (`displayedComponents: .hourAndMinute`) in a Liquid Glass container: `.ultraThinMaterial` background, `cornerRadius(20)`, subtle white border
- "Calculate Bedtimes" primary button: full-width indigo glass pill, calls `viewModel.calculate()`, triggers navigation push

### BedtimeResultsView

- Same background gradient
- Header: small uppercase label "WAKE UP AT HH:MM AM/PM" + bold title "Go to bed at…"
- `ScrollView` wrapping `VStack` of 4 `BedtimeCard` rows
- Tap any card → sets `viewModel.selectedOption` → `.confirmationDialog` appears

### BedtimeCard

Extracted subview. Receives a `BedtimeOption`, emits a tap callback.

**Recommended card** (5 cycles):
- Background: `.ultraThinMaterial` + indigo color overlay (`rgba #4f6ef7, opacity 0.15`)
- Border: `rgba #4f6ef7, opacity 0.45`
- Cycle dots: glowing indigo (`shadow radius 4, color #4f6ef7`)
- Badge: outlined indigo pill, text "RECOMMENDED"

**Other cards**:
- Background: `.ultraThinMaterial`, neutral — no tint
- Border: white at low opacity
- Cycle dots: indigo at reduced opacity (dimming toward fewer cycles)
- No badge

**Card layout (both):**
- Left: large time (`HH:MM`) + small `PM/AM` + duration label below
- Right: cycle dots row (aligned right)

---

## Alarm Interaction

Tap card → `.confirmationDialog`:
- Title: "Set alarm for [time]?"
- Primary action: "Set Alarm" → `openURL(URL(string: "clock-alarm://")!)`
- Cancel action: dismisses dialog, clears `selectedOption`

Uses SwiftUI `openURL` environment value. Fallback: if URL fails to open, silently ignore (no error UI — out of scope).

---

## Design Tokens

| Token | Value |
|---|---|
| Background start | `#0b0d14` |
| Background end | `#090b16` |
| Accent | `#4f6ef7` |
| Text primary | `#ffffff` |
| Text secondary | `rgba(255,255,255,0.45)` |
| Card material | `.ultraThinMaterial` |
| Card corner radius | `16pt` |
| Picker container radius | `20pt` |
| Button corner radius | `16pt` |

---

## Out of Scope

- Accounts, sign-in
- Sleep tracking or HealthKit
- Push notifications
- Persistence (no UserDefaults, no CoreData)
- Onboarding

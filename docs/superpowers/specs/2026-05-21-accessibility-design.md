# SleepWell Accessibility — Design Spec
_Date: 2026-05-21_

## Overview

Three-pillar accessibility pass across all five views: VoiceOver labels and grouping, Dynamic Type via semantic fonts, and contrast floor for informational text. No new views or navigation changes.

---

## Pillar 1 — VoiceOver

### WakeTimeInputView

| Element | Change |
|---|---|
| Logo image | `.accessibilityHidden(true)` |
| "SleepWell" wordmark | `.accessibilityHidden(true)` |
| "How can I help?" | `.accessibilityAddTraits(.isHeader)` |
| Gear icon button | `.accessibilityLabel("Settings")` |
| "Sleep Now" button | `.accessibilityLabel("Sleep Now")` + `.accessibilityHint("Shows the best times to wake up")` |
| "Wake Up At…" button | `.accessibilityLabel("Wake Up At")` + `.accessibilityHint("Tell me when to go to bed")` |
| "Take a Nap" button | `.accessibilityLabel("Take a Nap")` + `.accessibilityHint("Power nap or full recovery")` |
| Mode card subtitle text | `.accessibilityHidden(true)` (info moved to button hint) |
| Chevron icons | `.accessibilityHidden(true)` |

### WakeTimePickerView

| Element | Change |
|---|---|
| "SleepWell" wordmark | `.accessibilityHidden(true)` |
| "When do you wake up?" | `.accessibilityAddTraits(.isHeader)` |
| `DatePicker` | No change — native VoiceOver support |
| "Calculate Bedtimes" button | No change — text is the label |

### BedtimeResultsView

| Element | Change |
|---|---|
| Eyebrow + title `VStack` | `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isHeader)` |

### BedtimeCard

The button gets a computed `.accessibilityLabel` and `.accessibilityHint`. Internal decorative elements are hidden.

**Label format:**
- Normal option: `"11:16 PM, 7 hours 30 minutes, 5 sleep cycles"` 
- Recommended option: `"11:16 PM, recommended, 7 hours 30 minutes, 5 sleep cycles"`
- Nap option: `"9:46 AM, Refreshing nap, 20 minutes"`

**Hint:** `"Double tap to set alarm"`

**Hidden from VoiceOver:**
- Cycle dot `Circle` elements — `.accessibilityHidden(true)`
- "RECOMMENDED" / nap label `Text` — `.accessibilityHidden(true)`
- AM/PM `Text` — `.accessibilityHidden(true)` (time is read together via the label)
- Duration `Text` — `.accessibilityHidden(true)` (in label)
- Cycles count `Text` — `.accessibilityHidden(true)` (in label)

The label is computed in `BedtimeCard` using `BedtimeOption` fields:

```swift
private var accessibilityTimeString: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: option.bedtime)
}

private var accessibilityCardLabel: String {
    if let nap = option.napLabel {
        return "\(accessibilityTimeString), \(nap) nap, \(option.totalSleepFormatted)"
    }
    let recommended = option.isRecommended ? "recommended, " : ""
    let cycles = "\(option.cycles) sleep cycle\(option.cycles == 1 ? "" : "s")"
    return "\(accessibilityTimeString), \(recommended)\(option.totalSleepFormatted), \(cycles)"
}
```

### SettingsView

| Element | Change |
|---|---|
| "SleepWell" wordmark | `.accessibilityHidden(true)` |
| "Settings" heading | `.accessibilityAddTraits(.isHeader)` |
| "PREFERENCES" / "ALARMS" / "SCHEDULE" section headers | `.accessibilityHidden(true)` (decorative) |
| `fallAsleepRow` button | `.accessibilityLabel("Fall asleep time, \(viewModel.fallAsleepMinutes) minutes")` + `.accessibilityHint("Double tap to adjust")` |
| `wakeUpRow` button | `.accessibilityLabel("Default wake-up, \(wakeTimeLabel)")` + `.accessibilityHint("Double tap to adjust")` |
| `scheduleToggleRow` Toggle | `.accessibilityLabel("Wake-up schedule")` (Toggle is `.labelsHidden()` so needs explicit label) |
| `weekdayRow` button | `.accessibilityLabel("Weekdays, \(String(format: "%02d:%02d", weekdayWakeHour, weekdayWakeMinute))")` + `.accessibilityHint("Double tap to adjust")` |
| `weekendRow` button | `.accessibilityLabel("Weekend, \(String(format: "%02d:%02d", weekendWakeHour, weekendWakeMinute))")` + `.accessibilityHint("Double tap to adjust")` |
| Alarm name TextField | Already has `.accessibilityLabel("Alarm Name")` ✓ |
| "Delete All Alarms" button | No change — text label is clear |

---

## Pillar 2 — Dynamic Type (Semantic Fonts)

Replace all hardcoded `size:` with semantic text styles. SwiftUI semantic styles scale with the user's text size preference automatically.

### Font mapping

| View | Current | New |
|---|---|---|
| BedtimeCard — time | `size: 28, weight: .bold, design: .rounded` | `.system(.title, design: .rounded).weight(.bold)` |
| BedtimeCard — AM/PM | `size: 14` | `.footnote` |
| BedtimeCard — duration | `size: 12` | `.caption` |
| BedtimeCard — cycles text | `size: 10, weight: .semibold` | `.caption2.weight(.semibold)` |
| BedtimeCard — badge | `size: 9, weight: .bold` | `.caption2.weight(.bold)` |
| BedtimeResultsView — eyebrow | `size: 11, weight: .semibold` | `.caption2.weight(.semibold)` |
| BedtimeResultsView — title | `size: 22, weight: .bold` | `.title2.weight(.bold)` |
| WakeTimeInputView — "How can I help?" | `size: 26, weight: .bold` | `.title.weight(.bold)` |
| WakeTimeInputView — "SleepWell" | `size: 12, weight: .semibold` | `.caption.weight(.semibold)` |
| WakeTimeInputView — mode title | `size: 17, weight: .semibold` | `.headline` |
| WakeTimeInputView — mode subtitle | `size: 13` | `.footnote` |
| WakeTimePickerView — "When do you wake up?" | `size: 26, weight: .bold` | `.title.weight(.bold)` |
| WakeTimePickerView — "SleepWell" | `size: 12, weight: .semibold` | `.caption.weight(.semibold)` |
| SettingsView — "Settings" | `size: 26, weight: .bold` | `.title.weight(.bold)` |
| SettingsView — "SleepWell" | `size: 12, weight: .semibold` | `.caption.weight(.semibold)` |
| SettingsView — section headers | `size: 11, weight: .semibold` | `.caption2.weight(.semibold)` |
| SettingsView — row labels/values | `size: 15` | `.body` |
| WakeTimePickerView — "Calculate Bedtimes" | `size: 17, weight: .semibold` | `.headline` |

The `BedtimeCard` badge grows from 9→11pt (`.caption2` default). Acceptable — the badge is supplementary and hidden from VoiceOver.

---

## Pillar 3 — Contrast

Background is `#1a1c2e`. WCAG AA requires 4.5:1 for normal text, 3:1 for large text (≥18pt regular or ≥14pt bold).

**Problem:** `.white.opacity(0.4)` on `#1a1c2e` ≈ 3.9:1 — fails AA for small informational text.

**Fix:** Minimum 0.6 opacity for any `Text` that conveys information to the user.

### Changes per view

**WakeTimeInputView:**
- Mode card subtitle: `0.5` → `0.6`

**BedtimeCard:**
- Duration text (non-recommended): `0.4` → `0.55` (passes AA at `.caption` size as large text)
- Duration text (recommended): already `0.6` ✓
- Cycles count text: `0.45` → `0.55`
- AM/PM: `0.5` → hidden from VoiceOver anyway; raise to `0.55` for sighted users

**BedtimeResultsView:**
- Eyebrow: `0.4` → `0.5` (all-caps tracked text at `.caption2` is treated as large text; 4.3:1 passes)

**SettingsView:**
- Section headers ("PREFERENCES" etc): leave at `0.4` — hidden from VoiceOver, sighted orientation only
- "SleepWell" wordmarks: leave at `0.4` — hidden from VoiceOver, decorative

**No changes to:**
- Chevrons, stroke borders, background glows, dividers — purely decorative

---

## Out of Scope

- Reduce Motion support (no animations affect conveyed information)
- Smart Invert / high contrast color scheme overrides
- Accessibility for widget views (WidgetKit handles VoiceOver automatically from the view hierarchy)

---

## Testing

Each screen tested with VoiceOver enabled (Settings → Accessibility → VoiceOver) by navigating every interactive element and verifying labels, hints, and grouping are correct.

Dynamic Type tested at "Accessibility Large" size (Settings → Accessibility → Display & Text Size → Larger Text) — verify no text truncation on BedtimeCard or SettingsView rows.

Contrast verified visually at Accessibility Large + bold text.

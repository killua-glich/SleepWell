# Wake-up Schedule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-day-type wake-up schedule (weekdays vs weekends) to Settings, with a single toggle that enables both rows.

**Architecture:** Two changes in isolation — (1) add schedule data properties and `effectiveWakeDate(referenceDate:)` to `SleepViewModel`, tested with Swift Testing; (2) add a SCHEDULE card to `SettingsView` with a toggle and two time-picker rows matching existing UI patterns.

**Tech Stack:** Swift, SwiftUI, `@AppStorage` (UserDefaults-backed), Swift Testing framework (`import Testing`, `#expect`), `@Observable` macro.

---

## File Map

| File | Change |
|------|--------|
| `SleepWell/SleepWell/ViewModels/SleepViewModel.swift` | Add 5 `@AppStorage` properties + `effectiveWakeDate(referenceDate:)` |
| `SleepWell/SleepWellTests/SleepViewModelTests.swift` | Add tests for `effectiveWakeDate` |
| `SleepWell/SleepWell/Views/SettingsView.swift` | Add SCHEDULE section with toggle + weekday/weekend rows |

---

### Task 1: ViewModel — schedule properties and effectiveWakeDate

**Files:**
- Modify: `SleepWell/SleepWell/ViewModels/SleepViewModel.swift`
- Test: `SleepWell/SleepWellTests/SleepViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

Add a new `@Suite` block to `SleepWellTests/SleepViewModelTests.swift` after the existing suite:

```swift
@Suite("SleepViewModel effectiveWakeDate")
struct EffectiveWakeDateTests {

    // Monday 2026-05-18
    let monday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 18
        return Calendar.current.date(from: c)!
    }()

    // Sunday 2026-05-17
    let sunday: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 5; c.day = 17
        return Calendar.current.date(from: c)!
    }()

    @Test("returns defaultWakeDate when schedule disabled")
    func returnsDefaultWhenDisabled() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = false
        vm.defaultWakeHour = 7
        vm.defaultWakeMinute = 30
        let result = vm.effectiveWakeDate(referenceDate: monday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("returns weekday time on weekday when schedule enabled")
    func returnsWeekdayTimeOnWeekday() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = true
        vm.weekdayWakeHour = 6
        vm.weekdayWakeMinute = 15
        vm.weekendWakeHour = 9
        vm.weekendWakeMinute = 0
        let result = vm.effectiveWakeDate(referenceDate: monday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 6)
        #expect(components.minute == 15)
    }

    @Test("returns weekend time on weekend when schedule enabled")
    func returnsWeekendTimeOnWeekend() {
        let vm = SleepViewModel()
        vm.scheduleEnabled = true
        vm.weekdayWakeHour = 6
        vm.weekdayWakeMinute = 15
        vm.weekendWakeHour = 9
        vm.weekendWakeMinute = 0
        let result = vm.effectiveWakeDate(referenceDate: sunday)
        let components = Calendar.current.dateComponents([.hour, .minute], from: result)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

In Xcode: Product → Test (⌘U), or run the `SleepWellTests` target.  
Expected: compile error — `scheduleEnabled`, `weekdayWakeHour`, etc. do not exist yet.

- [ ] **Step 3: Add schedule properties and effectiveWakeDate to SleepViewModel**

In `SleepWell/SleepWell/ViewModels/SleepViewModel.swift`, add after the `defaultWakeMinute` property (after line 24):

```swift
    @ObservationIgnored
    @AppStorage("scheduleEnabled") var scheduleEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("weekdayWakeHour") var weekdayWakeHour: Int = 7

    @ObservationIgnored
    @AppStorage("weekdayWakeMinute") var weekdayWakeMinute: Int = 0

    @ObservationIgnored
    @AppStorage("weekendWakeHour") var weekendWakeHour: Int = 8

    @ObservationIgnored
    @AppStorage("weekendWakeMinute") var weekendWakeMinute: Int = 0
```

Then add after the `defaultWakeDate` computed property (after line 28):

```swift
    func effectiveWakeDate(referenceDate: Date = Date()) -> Date {
        guard scheduleEnabled else { return defaultWakeDate }
        if Calendar.current.isDateInWeekend(referenceDate) {
            return SleepViewModel.makeWakeDate(hour: weekendWakeHour, minute: weekendWakeMinute)
        } else {
            return SleepViewModel.makeWakeDate(hour: weekdayWakeHour, minute: weekdayWakeMinute)
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Product → Test (⌘U). All 3 new tests in `EffectiveWakeDateTests` and all existing tests must be green.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/ViewModels/SleepViewModel.swift
git add SleepWell/SleepWellTests/SleepViewModelTests.swift
git commit -m "Add wake-up schedule properties and effectiveWakeDate to SleepViewModel"
```

---

### Task 2: SettingsView — SCHEDULE card

**Files:**
- Modify: `SleepWell/SleepWell/Views/SettingsView.swift`

- [ ] **Step 1: Expand the ExpandedSetting enum**

Replace:
```swift
    private enum ExpandedSetting {
        case fallAsleep, wakeUp
    }
```
With:
```swift
    private enum ExpandedSetting {
        case fallAsleep, wakeUp, weekday, weekend
    }
```

- [ ] **Step 2: Add schedule @AppStorage properties to SettingsView**

After the existing `private let minuteRange` line, add:

```swift
    @AppStorage("scheduleEnabled") private var scheduleEnabled: Bool = false
    @AppStorage("weekdayWakeHour") private var weekdayWakeHour: Int = 7
    @AppStorage("weekdayWakeMinute") private var weekdayWakeMinute: Int = 0
    @AppStorage("weekendWakeHour") private var weekendWakeHour: Int = 8
    @AppStorage("weekendWakeMinute") private var weekendWakeMinute: Int = 0
```

- [ ] **Step 3: Add SCHEDULE section to body**

In the `body` computed property, after the closing `}` of the PREFERENCES `VStack(alignment: .leading, spacing: 6)` block and before the trailing `Spacer()`, add:

```swift
                VStack(alignment: .leading, spacing: 6) {
                    Text("SCHEDULE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .padding(.horizontal, 28)

                    VStack(spacing: 0) {
                        scheduleToggleRow
                        if scheduleEnabled {
                            Divider().overlay(Color.white.opacity(0.08))
                            weekdayRow
                            Divider().overlay(Color.white.opacity(0.08))
                            weekendRow
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scheduleEnabled)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expanded)
                }
```

- [ ] **Step 4: Add scheduleToggleRow computed property**

Add after the `// MARK: - Wake-up row` section's closing brace:

```swift
    // MARK: - Schedule toggle row

    private var scheduleToggleRow: some View {
        HStack {
            Text("Wake-up schedule")
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $scheduleEnabled)
                .labelsHidden()
                .tint(Color.accent)
                .onChange(of: scheduleEnabled) { _, _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expanded = nil
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
```

- [ ] **Step 5: Add weekdayRow computed property**

```swift
    // MARK: - Weekday row

    private var weekdayRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expanded = expanded == .weekday ? nil : .weekday
                }
            } label: {
                HStack {
                    Text("Weekdays")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekdayWakeHour, weekdayWakeMinute))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .weekday {
                DatePicker(
                    "",
                    selection: weekdayWakeBinding(),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }
```

- [ ] **Step 6: Add weekendRow computed property**

```swift
    // MARK: - Weekend row

    private var weekendRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expanded = expanded == .weekend ? nil : .weekend
                }
            } label: {
                HStack {
                    Text("Weekend")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekendWakeHour, weekendWakeMinute))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .weekend {
                DatePicker(
                    "",
                    selection: weekendWakeBinding(),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }
```

- [ ] **Step 7: Add binding helpers**

Add after the existing `defaultWakeBinding(vm:)` function in the `// MARK: - Helpers` section:

```swift
    private func weekdayWakeBinding() -> Binding<Date> {
        Binding(
            get: { SleepViewModel.makeWakeDate(hour: weekdayWakeHour, minute: weekdayWakeMinute) },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                weekdayWakeHour = components.hour ?? 7
                weekdayWakeMinute = components.minute ?? 0
            }
        )
    }

    private func weekendWakeBinding() -> Binding<Date> {
        Binding(
            get: { SleepViewModel.makeWakeDate(hour: weekendWakeHour, minute: weekendWakeMinute) },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                weekendWakeHour = components.hour ?? 8
                weekendWakeMinute = components.minute ?? 0
            }
        )
    }
```

- [ ] **Step 8: Build and verify**

Product → Build (⌘B). Must compile with no errors or warnings.  
Then Product → Test (⌘U). All existing tests must still pass.

- [ ] **Step 9: Smoke test in simulator**

Launch the app. Open Settings. Verify:
- SCHEDULE section appears below PREFERENCES
- Toggle off: only "Wake-up schedule" row visible
- Toggle on: "Weekdays" and "Weekend" rows animate in
- Tapping a row expands the time picker
- Tapping the toggle while a picker is open collapses the picker first
- Killing and relaunching the app preserves the toggle state and both times

- [ ] **Step 10: Commit**

```bash
git add SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Add wake-up schedule toggle and weekday/weekend rows to Settings"
```

---

### Task 3: Update backlog

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Mark wake-up schedule done**

In `wakeupCycle/BACKLOG.md`, change:
```
- [ ] Wake-up schedule — separate defaults for weekdays vs weekends
```
to:
```
- [x] Wake-up schedule — separate defaults for weekdays vs weekends
```

Update the `_Last updated` line:
```
_Last updated: 2026-05-19_ (wake-up schedule: toggle-gated weekday/weekend times in Settings)
```

- [ ] **Step 2: Commit**

```bash
git add BACKLOG.md
git commit -m "Mark wake-up schedule complete in backlog"
```

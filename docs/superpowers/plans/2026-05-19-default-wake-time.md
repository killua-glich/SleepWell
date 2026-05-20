# Default Wake-Up Time Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist a default wake-up time in Settings so the Wake Up At picker always opens pre-filled with the user's preference.

**Architecture:** Two `@AppStorage` keys (`defaultWakeHour`, `defaultWakeMinute`) added to `SleepViewModel` alongside the existing `fallAsleepMinutes`. A `defaultWakeDate` computed property constructs the `Date`. `WakeTimePickerView` syncs `wakeTime` from this default on `onAppear`. `SettingsView` gains a `DatePicker` section bound to those keys via a `Binding<Date>`.

**Tech Stack:** Swift 6, SwiftUI, `@AppStorage` (UserDefaults), Swift Testing

---

### Task 1: Add storage keys and `defaultWakeDate` to `SleepViewModel`

**Files:**
- Modify: `wakeupCycle/SleepWell/SleepWell/ViewModels/SleepViewModel.swift`
- Create: `wakeupCycle/SleepWell/SleepWellTests/SleepViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

Create `wakeupCycle/SleepWell/SleepWellTests/SleepViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import SleepWell

@Suite("SleepViewModel default wake date")
struct SleepViewModelTests {

    @Test("makeWakeDate builds date with correct hour and minute")
    func makeWakeDateComponents() {
        let date = SleepViewModel.makeWakeDate(hour: 7, minute: 30)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 7)
        #expect(components.minute == 30)
    }

    @Test("makeWakeDate at midnight")
    func makeWakeDateMidnight() {
        let date = SleepViewModel.makeWakeDate(hour: 0, minute: 0)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    @Test("makeWakeDate at 23:59")
    func makeWakeDateLateNight() {
        let date = SleepViewModel.makeWakeDate(hour: 23, minute: 59)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
xcodebuild test \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SleepWellTests/SleepViewModelTests \
  2>&1 | grep -E "(FAIL|PASS|error:|Build)"
```

Expected: FAIL — `SleepViewModel.makeWakeDate` not defined.

- [ ] **Step 3: Add storage keys and helper to `SleepViewModel`**

Replace `SleepViewModel.swift` with:

```swift
import Foundation
import Observation
import SwiftUI

enum SleepMode {
    case wakeUp, sleepNow, nap
}

@Observable
final class SleepViewModel {
    var wakeTime: Date = SleepViewModel.makeWakeDate(hour: 7, minute: 0)
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil
    var mode: SleepMode = .wakeUp

    @ObservationIgnored
    @AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14

    @ObservationIgnored
    @AppStorage("defaultWakeHour") var defaultWakeHour: Int = 7

    @ObservationIgnored
    @AppStorage("defaultWakeMinute") var defaultWakeMinute: Int = 0

    var defaultWakeDate: Date {
        SleepViewModel.makeWakeDate(hour: defaultWakeHour, minute: defaultWakeMinute)
    }

    static func makeWakeDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    func calculate() {
        switch mode {
        case .wakeUp:
            bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        case .sleepNow:
            bedtimes = SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        case .nap:
            bedtimes = SleepCalculator.calculateNapTimes(napTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        }
        showResults = true
    }

    func calculateWakeUp() {
        mode = .wakeUp
        calculate()
    }

    func calculateSleepNow() {
        mode = .sleepNow
        calculate()
    }

    func calculateNapNow() {
        mode = .nap
        calculate()
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
        mode = .wakeUp
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
xcodebuild test \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing SleepWellTests/SleepViewModelTests \
  2>&1 | grep -E "(FAIL|PASS|error:|Build)"
```

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add wakeupCycle/SleepWell/SleepWell/ViewModels/SleepViewModel.swift \
        wakeupCycle/SleepWell/SleepWellTests/SleepViewModelTests.swift
git commit -m "Add defaultWakeHour/Minute storage and makeWakeDate helper to SleepViewModel"
```

---

### Task 2: Sync WakeTimePickerView from stored default on appear

**Files:**
- Modify: `wakeupCycle/SleepWell/SleepWell/Views/WakeTimePickerView.swift`

- [ ] **Step 1: Add `onAppear` to sync `wakeTime`**

In `WakeTimePickerView.swift`, add `.onAppear` to the outermost `ZStack`. The full `body` becomes:

```swift
var body: some View {
    ZStack {
        backgroundView

        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 6) {
                Text("SleepWell")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)

                Text("When do you wake up?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            @Bindable var vm = viewModel
            DatePicker(
                "",
                selection: $vm.wakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            Button {
                viewModel.calculateWakeUp()
            } label: {
                Text("Calculate Bedtimes")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accent.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.15), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.accent.opacity(0.4), radius: 12, y: 4)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Spacer()
        }
    }
    .onAppear {
        viewModel.wakeTime = viewModel.defaultWakeDate
    }
    .navigationTitle("")
    .toolbarBackground(.hidden, for: .navigationBar)
}
```

- [ ] **Step 2: Build to verify no errors**

```
xcodebuild build \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|warning:|BUILD)"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 3: Commit**

```bash
git add wakeupCycle/SleepWell/SleepWell/Views/WakeTimePickerView.swift
git commit -m "Pre-fill wake time picker from stored default on appear"
```

---

### Task 3: Add Default Wake-Up Time section to SettingsView

**Files:**
- Modify: `wakeupCycle/SleepWell/SleepWell/Views/SettingsView.swift`

- [ ] **Step 1: Replace `SettingsView.swift` with two-section layout**

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private let minuteRange = Array(5...60)

    var body: some View {
        ZStack {
            backgroundView

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 16)

                    VStack(spacing: 6) {
                        Text("Settings")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)
                    }

                    // MARK: - Fall asleep time
                    settingSection(label: "How long to fall asleep?", caption: "Used to calculate your ideal bedtime") {
                        @Bindable var vm = viewModel
                        Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                            ForEach(minuteRange, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .colorScheme(.dark)
                    }

                    // MARK: - Default wake-up time
                    settingSection(label: "Default wake-up time", caption: "Pre-fills the Wake Up At picker") {
                        @Bindable var vm = viewModel
                        DatePicker(
                            "",
                            selection: defaultWakeBinding(vm: viewModel),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                    }

                    Spacer().frame(height: 16)
                }
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // Converts the two AppStorage ints to a Binding<Date> for the DatePicker.
    private func defaultWakeBinding(vm: SleepViewModel) -> Binding<Date> {
        Binding(
            get: { vm.defaultWakeDate },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                vm.defaultWakeHour = components.hour ?? 7
                vm.defaultWakeMinute = components.minute ?? 0
            }
        )
    }

    @ViewBuilder
    private func settingSection<Content: View>(
        label: String,
        caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            content()
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appBackgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.accent.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .frame(width: 300, height: 300)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(SleepViewModel())
    }
}
```

- [ ] **Step 2: Build and run all tests**

```
xcodebuild test \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(FAIL|PASS|error:|BUILD)"
```

Expected: `BUILD SUCCEEDED`, all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add wakeupCycle/SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Add default wake-up time picker to Settings"
```

---

### Task 4: Mark backlog item complete

**Files:**
- Modify: `wakeupCycle/BACKLOG.md`

- [ ] **Step 1: Mark item done**

Change:
```
- [ ] Default wake-up time — user sets a persistent wake-up target used for recommendations
```
to:
```
- [x] Default wake-up time — user sets a persistent wake-up target used for recommendations
```

- [ ] **Step 2: Update last-updated date**

Change:
```
_Last updated: 2026-05-18_ (nap mode shipped: power nap + recovery nap options)
```
to:
```
_Last updated: 2026-05-19_ (default wake-up time: persisted in Settings, pre-fills Wake Up At picker)
```

- [ ] **Step 3: Commit**

```bash
git add wakeupCycle/BACKLOG.md
git commit -m "Mark default wake-up time backlog item complete"
```

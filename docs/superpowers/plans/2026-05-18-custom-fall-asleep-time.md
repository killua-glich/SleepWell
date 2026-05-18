# Custom Fall-Asleep Time Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded 14-minute fall-asleep latency with a user-configurable value (5–60 min) persisted via `@AppStorage`, accessible from a new Settings screen.

**Architecture:** `SleepCalculator.calculate()` gains a `fallAsleepMinutes` parameter. `SleepViewModel` holds `@AppStorage("fallAsleepMinutes")` and passes it through. `SettingsView` is a new view pushed from `WakeTimeInputView`'s toolbar.

**Tech Stack:** Swift, SwiftUI, `@AppStorage` (UserDefaults), Swift Testing framework.

---

## File Map

| Action | Path |
|--------|------|
| Modify | `SleepWell/SleepWell/Model/SleepCalculator.swift` |
| Modify | `SleepWell/SleepWellTests/SleepCalculatorTests.swift` |
| Modify | `SleepWell/SleepWell/ViewModels/SleepViewModel.swift` |
| Modify | `SleepWell/SleepWell/Views/WakeTimeInputView.swift` |
| Create | `SleepWell/SleepWell/Views/SettingsView.swift` |

---

### Task 1: Update `SleepCalculator` to accept latency as a parameter

**Files:**
- Modify: `SleepWell/SleepWell/Model/SleepCalculator.swift`
- Modify: `SleepWell/SleepWellTests/SleepCalculatorTests.swift`

- [ ] **Step 1: Update the failing tests first**

Replace all calls to `SleepCalculator.calculate(wakeTime: wakeTime)` with `SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)` in `SleepCalculatorTests.swift`. Also update the two bedtime math tests to use the new signature and add a test for a non-default latency:

```swift
import Testing
import Foundation
@testable import SleepWell

@Suite("SleepCalculator")
struct SleepCalculatorTests {

    let wakeTime: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 8
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }()

    @Test("returns 4 options")
    func returnsExactlyFourOptions() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        #expect(results.count == 4)
    }

    @Test("sorted 6 cycles first")
    func sortedByDescendingCycles() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        #expect(results.map(\.cycles) == [6, 5, 4, 3])
    }

    @Test("only 5-cycle option is recommended")
    func onlyFiveCyclesRecommended() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let recommended = results.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.cycles == 5)
    }

    @Test("6-cycle bedtime is 9h14m before wake with 14min latency")
    func sixCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        // 6 × 90 + 14 = 554 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-554 * 60)
        #expect(sixCycle.bedtime == expectedBedtime)
    }

    @Test("5-cycle bedtime is 7h44m before wake with 14min latency")
    func fiveCycleBedtime() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        // 5 × 90 + 14 = 464 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-464 * 60)
        #expect(fiveCycle.bedtime == expectedBedtime)
    }

    @Test("totalSleepMinutes equals cycles × 90")
    func totalSleepMinutes() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        for option in results {
            #expect(option.totalSleepMinutes == option.cycles * 90)
        }
    }

    @Test("totalSleepFormatted for 7.5h")
    func totalSleepFormatted() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 14)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        #expect(fiveCycle.totalSleepFormatted == "7h 30m")
    }

    @Test("custom latency shifts bedtimes correctly")
    func customLatencyShiftsBedtimes() {
        let results = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: 30)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        // 6 × 90 + 30 = 570 minutes before wake
        let expectedBedtime = wakeTime.addingTimeInterval(-570 * 60)
        #expect(sixCycle.bedtime == expectedBedtime)
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure**

In Xcode: Product → Test (⌘U). Expected: build error — `calculate(wakeTime:)` doesn't have `fallAsleepMinutes` parameter yet.

- [ ] **Step 3: Update `SleepCalculator`**

Replace the entire file:

```swift
import Foundation

struct SleepCalculator {
    static let cycleDuration: TimeInterval = 90 * 60

    static func calculate(wakeTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption] {
        let latency = TimeInterval(fallAsleepMinutes) * 60
        return [6, 5, 4, 3].map { cycles in
            let sleepDuration = TimeInterval(cycles) * cycleDuration
            let bedtime = wakeTime - sleepDuration - latency
            return BedtimeOption(
                bedtime: bedtime,
                totalSleepMinutes: cycles * 90,
                cycles: cycles,
                isRecommended: cycles == 5
            )
        }
    }
}
```

- [ ] **Step 4: Run tests — expect all pass**

⌘U. Expected: all 8 tests green.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/Model/SleepCalculator.swift SleepWell/SleepWellTests/SleepCalculatorTests.swift
git commit -m "Parameterise fall-asleep latency in SleepCalculator"
```

---

### Task 2: Wire latency into `SleepViewModel`

**Files:**
- Modify: `SleepWell/SleepWell/ViewModels/SleepViewModel.swift`

- [ ] **Step 1: Update `SleepViewModel`**

Replace the entire file:

```swift
import Foundation
import Observation

@Observable
final class SleepViewModel {
    var wakeTime: Date = defaultWakeTime()
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil

    @ObservationIgnored
    @AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14

    func calculate() {
        bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        showResults = true
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
    }
}

private func defaultWakeTime() -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 7
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}
```

Note: `@ObservationIgnored` is required because `@AppStorage` and `@Observable` don't compose directly — `@Observable` tries to synthesize observation for stored properties, but `@AppStorage` has its own property wrapper storage. `@ObservationIgnored` tells `@Observable` to leave this property alone.

- [ ] **Step 2: Build — expect success**

⌘B. No errors expected.

- [ ] **Step 3: Run tests — expect all pass**

⌘U. All 8 tests green.

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWell/ViewModels/SleepViewModel.swift
git commit -m "Add @AppStorage fallAsleepMinutes to SleepViewModel"
```

---

### Task 3: Create `SettingsView`

**Files:**
- Create: `SleepWell/SleepWell/Views/SettingsView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private let minuteRange = Array(5...60)

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Settings")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)

                    Text("How long to fall asleep?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                @Bindable var vm = viewModel
                Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                    ForEach(minuteRange, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
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

                Text("Used to calculate your ideal bedtime")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
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

- [ ] **Step 2: Build — expect success**

⌘B. No errors expected.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Add SettingsView with fall-asleep duration picker"
```

---

### Task 4: Add gear icon to `WakeTimeInputView`

**Files:**
- Modify: `SleepWell/SleepWell/Views/WakeTimeInputView.swift`

- [ ] **Step 1: Add toolbar and NavigationLink**

Add the following modifier to the `body` view chain, after `.toolbarBackground(.hidden, for: .navigationBar)`:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
```

The full `body` after the change:

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
                viewModel.calculate()
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
    .navigationTitle("")
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}
```

- [ ] **Step 2: Build and run on simulator**

⌘R. Verify:
- Gear icon appears top-right on main screen
- Tapping gear navigates to Settings screen
- Wheel picker shows 5–60 minutes, starts at 14
- Changing the value persists — kill and relaunch the app, confirm value is remembered
- After changing latency, go back and calculate — bedtimes shift by the difference

- [ ] **Step 3: Run tests — all pass**

⌘U. All 8 tests green.

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWell/Views/WakeTimeInputView.swift
git commit -m "Add gear icon linking to SettingsView from main screen"
```

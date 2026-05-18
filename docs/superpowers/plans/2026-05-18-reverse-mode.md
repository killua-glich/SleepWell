# Reverse Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Sleep now" mode where the user taps one button and immediately sees optimal wake-up times based on the current time.

**Architecture:** `WakeTimeInputView` becomes a two-option mode selector. "Wake up at…" pushes a new `WakeTimePickerView` (extracted from the current input view). "Sleep now" calculates immediately using `Date()` and pushes `BedtimeResultsView`. `SleepCalculator` gets a second static method; `SleepViewModel` gets a `Mode` enum and `calculateSleepNow()`.

**Tech Stack:** Swift, SwiftUI, Swift Testing (`@Suite`, `@Test`, `#expect`), `@Observable`, `@AppStorage`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `SleepWell/SleepWell/Model/SleepCalculator.swift` | Add `calculateWakeTimes(sleepTime:fallAsleepMinutes:)` |
| Modify | `SleepWell/SleepWellTests/SleepCalculatorTests.swift` | Tests for the new method |
| Modify | `SleepWell/SleepWell/ViewModels/SleepViewModel.swift` | Add `Mode` enum, `calculateSleepNow()`, update `calculate()` and `reset()` |
| Create | `SleepWell/SleepWell/Views/WakeTimePickerView.swift` | Picker + calculate button (extracted from current `WakeTimeInputView`) |
| Modify | `SleepWell/SleepWell/Views/WakeTimeInputView.swift` | Becomes mode selector with two tappable cards |
| Modify | `SleepWell/SleepWell/Views/BedtimeResultsView.swift` | Mode-aware header text |

---

## Task 1: Add `calculateWakeTimes` to `SleepCalculator`

**Files:**
- Test: `SleepWell/SleepWellTests/SleepCalculatorTests.swift`
- Modify: `SleepWell/SleepWell/Model/SleepCalculator.swift`

- [ ] **Step 1: Write the failing tests**

Add a new `@Suite` at the bottom of `SleepWell/SleepWellTests/SleepCalculatorTests.swift`:

```swift
@Suite("SleepCalculator reverse mode")
struct SleepCalculatorReverseModeTests {

    let sleepTime: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 1; c.day = 1
        c.hour = 23; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c)!
    }()

    @Test("returns 4 options")
    func returnsExactlyFourOptions() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        #expect(results.count == 4)
    }

    @Test("sorted 6 cycles first")
    func sortedByDescendingCycles() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        #expect(results.map(\.cycles) == [6, 5, 4, 3])
    }

    @Test("only 5-cycle option is recommended")
    func onlyFiveCyclesRecommended() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let recommended = results.filter(\.isRecommended)
        #expect(recommended.count == 1)
        #expect(recommended.first?.cycles == 5)
    }

    @Test("6-cycle wake time is 9h14m after sleep with 14min latency")
    func sixCycleWakeTime() {
        // 14min latency + 6×90min = 554 minutes after sleepTime
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        let expected = sleepTime.addingTimeInterval(554 * 60)
        #expect(sixCycle.bedtime == expected)
    }

    @Test("5-cycle wake time is 7h44m after sleep with 14min latency")
    func fiveCycleWakeTime() {
        // 14min latency + 5×90min = 464 minutes after sleepTime
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        let fiveCycle = results.first(where: { $0.cycles == 5 })!
        let expected = sleepTime.addingTimeInterval(464 * 60)
        #expect(fiveCycle.bedtime == expected)
    }

    @Test("totalSleepMinutes equals cycles × 90")
    func totalSleepMinutes() {
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 14)
        for option in results {
            #expect(option.totalSleepMinutes == option.cycles * 90)
        }
    }

    @Test("custom latency shifts wake times correctly")
    func customLatencyShiftsWakeTimes() {
        // 30min latency + 6×90min = 570 minutes after sleepTime
        let results = SleepCalculator.calculateWakeTimes(sleepTime: sleepTime, fallAsleepMinutes: 30)
        let sixCycle = results.first(where: { $0.cycles == 6 })!
        let expected = sleepTime.addingTimeInterval(570 * 60)
        #expect(sixCycle.bedtime == expected)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

In Xcode: Product → Test (⌘U), or run the SleepWellTests target.
Expected: compile error — `calculateWakeTimes` does not exist yet.

- [ ] **Step 3: Implement `calculateWakeTimes` in `SleepCalculator`**

Replace the full contents of `SleepWell/SleepWell/Model/SleepCalculator.swift`:

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

    static func calculateWakeTimes(sleepTime: Date, fallAsleepMinutes: Int) -> [BedtimeOption] {
        let latency = TimeInterval(fallAsleepMinutes) * 60
        let sleepOnset = sleepTime + latency
        return [6, 5, 4, 3].map { cycles in
            let sleepDuration = TimeInterval(cycles) * cycleDuration
            let wakeTime = sleepOnset + sleepDuration
            return BedtimeOption(
                bedtime: wakeTime,
                totalSleepMinutes: cycles * 90,
                cycles: cycles,
                isRecommended: cycles == 5
            )
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run ⌘U. Expected: all `SleepCalculatorReverseModeTests` pass, existing tests still pass.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/Model/SleepCalculator.swift \
        SleepWell/SleepWellTests/SleepCalculatorTests.swift
git commit -m "Add SleepCalculator.calculateWakeTimes for reverse mode"
```

---

## Task 2: Add `Mode` and `calculateSleepNow()` to `SleepViewModel`

**Files:**
- Modify: `SleepWell/SleepWell/ViewModels/SleepViewModel.swift`

- [ ] **Step 1: Replace the full contents of `SleepViewModel.swift`**

```swift
import Foundation
import Observation
import SwiftUI

enum SleepMode {
    case wakeUp, sleepNow
}

@Observable
final class SleepViewModel {
    var wakeTime: Date = defaultWakeTime()
    var bedtimes: [BedtimeOption] = []
    var showResults: Bool = false
    var selectedOption: BedtimeOption? = nil
    var mode: SleepMode = .wakeUp

    @ObservationIgnored
    @AppStorage("fallAsleepMinutes") var fallAsleepMinutes: Int = 14

    func calculate() {
        switch mode {
        case .wakeUp:
            bedtimes = SleepCalculator.calculate(wakeTime: wakeTime, fallAsleepMinutes: fallAsleepMinutes)
        case .sleepNow:
            bedtimes = SleepCalculator.calculateWakeTimes(sleepTime: Date(), fallAsleepMinutes: fallAsleepMinutes)
        }
        showResults = true
    }

    func calculateSleepNow() {
        mode = .sleepNow
        calculate()
    }

    func reset() {
        bedtimes = []
        showResults = false
        selectedOption = nil
        mode = .wakeUp
    }
}

private func defaultWakeTime() -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 7
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
}
```

- [ ] **Step 2: Build to verify no compile errors**

Product → Build (⌘B). Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/ViewModels/SleepViewModel.swift
git commit -m "Add SleepMode enum and calculateSleepNow() to SleepViewModel"
```

---

## Task 3: Create `WakeTimePickerView`

**Files:**
- Create: `SleepWell/SleepWell/Views/WakeTimePickerView.swift`

This is the existing picker + calculate button, extracted verbatim. The gear icon is removed (it stays on the mode selector).

- [ ] **Step 1: Create `SleepWell/SleepWell/Views/WakeTimePickerView.swift`**

```swift
import SwiftUI

struct WakeTimePickerView: View {
    @Environment(SleepViewModel.self) private var viewModel

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
        WakeTimePickerView()
            .environment(SleepViewModel())
    }
}
```

- [ ] **Step 2: Build to verify no compile errors**

⌘B. Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/WakeTimePickerView.swift
git commit -m "Add WakeTimePickerView extracted from WakeTimeInputView"
```

---

## Task 4: Refactor `WakeTimeInputView` into mode selector

**Files:**
- Modify: `SleepWell/SleepWell/Views/WakeTimeInputView.swift`

- [ ] **Step 1: Replace the full contents of `WakeTimeInputView.swift`**

```swift
import SwiftUI

struct WakeTimeInputView: View {
    @Environment(SleepViewModel.self) private var viewModel

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

                    Text("How can I help?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 16) {
                    Button {
                        viewModel.calculateSleepNow()
                    } label: {
                        modeCard(
                            title: "Sleep Now",
                            subtitle: "Show me the best times to wake up",
                            icon: "moon.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WakeTimePickerView()
                    } label: {
                        modeCard(
                            title: "Wake Up At…",
                            subtitle: "Tell me when to go to bed",
                            icon: "alarm"
                        )
                    }
                    .buttonStyle(.plain)
                }
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

    @ViewBuilder
    private func modeCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
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
                endRadius: 220
            )
            .frame(width: 360, height: 360)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        WakeTimeInputView()
            .environment(SleepViewModel())
    }
}
```

- [ ] **Step 2: Build to verify no compile errors**

⌘B. Expected: build succeeds.

- [ ] **Step 3: Run the app in simulator and verify both paths work**

- Tap "Sleep Now" → results appear immediately showing wake-up times
- Tap "Wake Up At…" → picker screen appears → Calculate → bedtime results appear
- Back navigation returns to mode selector cleanly

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWell/Views/WakeTimeInputView.swift
git commit -m "Refactor WakeTimeInputView into mode selector"
```

---

## Task 5: Update `BedtimeResultsView` header for mode

**Files:**
- Modify: `SleepWell/SleepWell/Views/BedtimeResultsView.swift`

- [ ] **Step 1: Update the header section in `BedtimeResultsView`**

Replace the `wakeTimeLabel` computed property and the header `VStack` in `BedtimeResultsView.swift`.

Current `wakeTimeLabel`:
```swift
private var wakeTimeLabel: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: viewModel.wakeTime).uppercased()
}
```

Replace with two computed properties:
```swift
private var headerEyebrow: String {
    switch viewModel.mode {
    case .wakeUp:
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "WAKE UP AT \(formatter.string(from: viewModel.wakeTime).uppercased())"
    case .sleepNow:
        return "SLEEPING NOW"
    }
}

private var headerTitle: String {
    switch viewModel.mode {
    case .wakeUp: return "Go to bed at…"
    case .sleepNow: return "Wake up at…"
    }
}
```

Replace the header `VStack` (currently lines ~32–39):
```swift
VStack(spacing: 4) {
    Text(headerEyebrow)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.white.opacity(0.4))
        .tracking(1.5)

    Text(headerTitle)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(.white)
}
.padding(.top, 20)
.padding(.bottom, 24)
```

Also remove the now-unused `wakeTimeLabel` property if it remains.

- [ ] **Step 2: Build and verify**

⌘B. Expected: build succeeds.

Run in simulator:
- Sleep Now mode: header shows "SLEEPING NOW" / "Wake up at…"
- Wake Up At mode: header shows "WAKE UP AT 7:00 AM" / "Go to bed at…"

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/BedtimeResultsView.swift
git commit -m "Update BedtimeResultsView header for reverse mode"
```

---

## Task 6: Final verification and push

- [ ] **Step 1: Run all tests**

⌘U. Expected: all tests pass (both `SleepCalculator` suites).

- [ ] **Step 2: Smoke test both modes end-to-end in simulator**

- Open app → mode selector visible
- "Sleep Now" → results load instantly, header says "SLEEPING NOW" / "Wake up at…", 4 cards shown
- Back → mode selector
- "Wake Up At…" → picker → change time → Calculate → results, header says "WAKE UP AT [time]" / "Go to bed at…"
- Tap a card → alarm dialog appears
- Back → mode selector (not picker)

- [ ] **Step 3: Update BACKLOG.md**

Mark reverse mode as done:
```markdown
- [x] Reverse mode — "I'm going to sleep now, when should I wake up?" calculates optimal alarm times from current time
```

```bash
git add BACKLOG.md
git commit -m "Mark reverse mode complete in BACKLOG"
```

- [ ] **Step 4: Push**

```bash
git push origin main
```

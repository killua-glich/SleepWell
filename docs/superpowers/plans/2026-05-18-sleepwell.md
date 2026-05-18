# SleepWell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftUI iOS 26 app that calculates bedtimes from a wake-up time using sleep cycle science, with Liquid Glass design and iOS Clock alarm deep-link.

**Architecture:** MVVM — one `@Observable` SleepViewModel shared via `@Environment`. Pure `SleepCalculator` struct holds all logic. `NavigationStack` pushes results when Calculate is tapped. Confirmation dialog on card tap before opening Clock alarm deep-link.

**Tech Stack:** SwiftUI, iOS 26+, Swift Testing, no third-party dependencies.

---

## File Map

| File | Responsibility |
|---|---|
| `SleepWell/SleepWellApp.swift` | `@main`, NavigationStack, injects SleepViewModel |
| `SleepWell/Model/BedtimeOption.swift` | Value type: bedtime, cycles, duration, isRecommended |
| `SleepWell/Model/SleepCalculator.swift` | Static `calculate(wakeTime:)` — pure logic, no SwiftUI |
| `SleepWell/ViewModels/SleepViewModel.swift` | `@Observable`: wakeTime, bedtimes, selectedOption, showResults |
| `SleepWell/Views/WakeTimeInputView.swift` | Wheel picker + Calculate button |
| `SleepWell/Views/BedtimeResultsView.swift` | Header + scrollable list of cards + confirmationDialog |
| `SleepWell/Views/BedtimeCard.swift` | Single bedtime row — glass card, cycle dots, optional badge |
| `SleepWell/Utilities/Color+Hex.swift` | `Color(hex:)` initializer |
| `SleepWellTests/SleepCalculatorTests.swift` | Swift Testing unit tests for SleepCalculator |

---

## Task 1: Create Xcode Project (Manual Step)

**Files:**
- Creates: entire Xcode project at `/Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle/SleepWell/`

- [ ] **Step 1: Open Xcode → File → New → Project**

  Choose **iOS → App**. Fill in:
  - Product Name: `SleepWell`
  - Bundle Identifier: `com.yourname.SleepWell`
  - Interface: SwiftUI
  - Language: Swift
  - Storage: None
  - Include Tests: ✅ (check this)

  Save into `/Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle/`.

- [ ] **Step 2: Set deployment target to iOS 26**

  Select the SleepWell target → General → Minimum Deployments → iOS 26.0.

- [ ] **Step 3: Delete generated placeholder files**

  Delete `ContentView.swift` (move to trash). Keep `SleepWellApp.swift` and `Assets.xcassets`.

- [ ] **Step 4: Create folder groups in Xcode**

  In Xcode's project navigator, create groups (not folder references — use "New Group"):
  - `Model`
  - `ViewModels`
  - `Views`
  - `Utilities`

- [ ] **Step 5: Verify build succeeds**

  `Cmd+B`. Expected: build succeeds (SleepWellApp.swift will have an error about missing body — fix by adding an empty WindowGroup for now):

  ```swift
  // SleepWell/SleepWellApp.swift — temporary, will be replaced in Task 9
  import SwiftUI

  @main
  struct SleepWellApp: App {
      var body: some Scene {
          WindowGroup {
              Text("Hello")
          }
      }
  }
  ```

---

## Task 2: BedtimeOption Model

**Files:**
- Create: `SleepWell/Model/BedtimeOption.swift`

- [ ] **Step 1: Create `BedtimeOption.swift`**

  ```swift
  import Foundation

  struct BedtimeOption: Identifiable {
      let id = UUID()
      let bedtime: Date
      let totalSleepMinutes: Int
      let cycles: Int
      let isRecommended: Bool

      var totalSleepFormatted: String {
          let hours = totalSleepMinutes / 60
          let minutes = totalSleepMinutes % 60
          if minutes == 0 {
              return "\(hours) hrs"
          }
          return "\(hours)h \(minutes)m"
      }
  }
  ```

- [ ] **Step 2: Build to confirm no errors**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 3: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle init
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/Model/BedtimeOption.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add BedtimeOption model"
  ```

---

## Task 3: SleepCalculator — TDD

**Files:**
- Create: `SleepWell/Model/SleepCalculator.swift`
- Create: `SleepWellTests/SleepCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `SleepWellTests/SleepCalculatorTests.swift`:

  ```swift
  import Testing
  import Foundation
  @testable import SleepWell

  @Suite("SleepCalculator")
  struct SleepCalculatorTests {

      // Fixed wake time: 8:00 AM on a reference date
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
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          #expect(results.count == 4)
      }

      @Test("sorted 6 cycles first")
      func sortedByDescendingCycles() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          #expect(results.map(\.cycles) == [6, 5, 4, 3])
      }

      @Test("only 5-cycle option is recommended")
      func onlyFiveCyclesRecommended() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          let recommended = results.filter(\.isRecommended)
          #expect(recommended.count == 1)
          #expect(recommended.first?.cycles == 5)
      }

      @Test("6-cycle bedtime is 9h14m before wake")
      func sixCycleBedtime() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          let sixCycle = results.first(where: { $0.cycles == 6 })!
          // 6 × 90 + 14 = 554 minutes before wake
          let expectedBedtime = wakeTime.addingTimeInterval(-554 * 60)
          #expect(sixCycle.bedtime == expectedBedtime)
      }

      @Test("5-cycle bedtime is 7h44m before wake")
      func fiveCycleBedtime() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          let fiveCycle = results.first(where: { $0.cycles == 5 })!
          // 5 × 90 + 14 = 464 minutes before wake
          let expectedBedtime = wakeTime.addingTimeInterval(-464 * 60)
          #expect(fiveCycle.bedtime == expectedBedtime)
      }

      @Test("totalSleepMinutes equals cycles × 90")
      func totalSleepMinutes() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          for option in results {
              #expect(option.totalSleepMinutes == option.cycles * 90)
          }
      }

      @Test("totalSleepFormatted for 7.5h")
      func totalSleepFormatted() {
          let results = SleepCalculator.calculate(wakeTime: wakeTime)
          let fiveCycle = results.first(where: { $0.cycles == 5 })!
          #expect(fiveCycle.totalSleepFormatted == "7h 30m")
      }
  }
  ```

- [ ] **Step 2: Run tests — verify they fail**

  `Cmd+U`. Expected: compile error — `SleepCalculator` not found.

- [ ] **Step 3: Implement SleepCalculator**

  Create `SleepWell/Model/SleepCalculator.swift`:

  ```swift
  import Foundation

  struct SleepCalculator {
      static let cycleDuration: TimeInterval = 90 * 60      // 90 min in seconds
      static let fallAsleepLatency: TimeInterval = 14 * 60  // 14 min in seconds

      static func calculate(wakeTime: Date) -> [BedtimeOption] {
          [6, 5, 4, 3].map { cycles in
              let sleepDuration = TimeInterval(cycles) * cycleDuration
              let bedtime = wakeTime - sleepDuration - fallAsleepLatency
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

- [ ] **Step 4: Run tests — verify they pass**

  `Cmd+U`. Expected: all 7 tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add \
    SleepWell/Model/SleepCalculator.swift \
    SleepWellTests/SleepCalculatorTests.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add SleepCalculator with tests"
  ```

---

## Task 4: SleepViewModel

**Files:**
- Create: `SleepWell/ViewModels/SleepViewModel.swift`

- [ ] **Step 1: Create `SleepViewModel.swift`**

  ```swift
  import Foundation
  import Observation

  @Observable
  final class SleepViewModel {
      var wakeTime: Date = defaultWakeTime()
      var bedtimes: [BedtimeOption] = []
      var showResults: Bool = false
      var selectedOption: BedtimeOption? = nil

      func calculate() {
          bedtimes = SleepCalculator.calculate(wakeTime: wakeTime)
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

- [ ] **Step 2: Build to confirm no errors**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 3: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/ViewModels/SleepViewModel.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add SleepViewModel"
  ```

---

## Task 5: Color Utilities

**Files:**
- Create: `SleepWell/Utilities/Color+Hex.swift`

- [ ] **Step 1: Create `Color+Hex.swift`**

  ```swift
  import SwiftUI

  extension Color {
      init(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          Scanner(string: hex).scanHexInt64(&int)
          let r, g, b: UInt64
          switch hex.count {
          case 3:
              (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
          case 6:
              (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
          default:
              (r, g, b) = (0, 0, 0)
          }
          self.init(
              .sRGB,
              red: Double(r) / 255,
              green: Double(g) / 255,
              blue: Double(b) / 255
          )
      }

      static let appBackground = Color(hex: "0b0d14")
      static let appBackgroundEnd = Color(hex: "090b16")
      static let accent = Color(hex: "4f6ef7")
  }
  ```

- [ ] **Step 2: Build to confirm no errors**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 3: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/Utilities/Color+Hex.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add Color hex utilities and design tokens"
  ```

---

## Task 6: BedtimeCard View

**Files:**
- Create: `SleepWell/Views/BedtimeCard.swift`

- [ ] **Step 1: Create `BedtimeCard.swift`**

  ```swift
  import SwiftUI

  struct BedtimeCard: View {
      let option: BedtimeOption
      let onTap: () -> Void

      private var timeString: String {
          let formatter = DateFormatter()
          formatter.dateFormat = "h:mm"
          return formatter.string(from: option.bedtime)
      }

      private var amPmString: String {
          let formatter = DateFormatter()
          formatter.dateFormat = "a"
          return formatter.string(from: option.bedtime)
      }

      private var dotOpacity: Double {
          switch option.cycles {
          case 6: return 1.0
          case 5: return 1.0
          case 4: return 0.55
          case 3: return 0.35
          default: return 0.35
          }
      }

      var body: some View {
          Button(action: onTap) {
              HStack(alignment: .center) {
                  // Left: time + duration
                  VStack(alignment: .leading, spacing: 2) {
                      HStack(alignment: .lastTextBaseline, spacing: 4) {
                          Text(timeString)
                              .font(.system(size: 28, weight: .bold, design: .rounded))
                              .foregroundStyle(.white)
                          Text(amPmString)
                              .font(.system(size: 14, weight: .regular))
                              .foregroundStyle(.white.opacity(0.5))
                      }
                      Text(option.totalSleepFormatted)
                          .font(.system(size: 12, weight: .regular))
                          .foregroundStyle(.white.opacity(option.isRecommended ? 0.6 : 0.4))
                  }

                  Spacer()

                  // Right: cycle dots + optional badge
                  VStack(alignment: .trailing, spacing: 6) {
                      HStack(spacing: 4) {
                          ForEach(0..<option.cycles, id: \.self) { _ in
                              Circle()
                                  .fill(Color.accent.opacity(dotOpacity))
                                  .frame(width: 8, height: 8)
                                  .shadow(
                                      color: option.isRecommended ? Color.accent.opacity(0.8) : .clear,
                                      radius: 4
                                  )
                          }
                      }

                      if option.isRecommended {
                          Text("RECOMMENDED")
                              .font(.system(size: 9, weight: .bold))
                              .foregroundStyle(Color.accent)
                              .padding(.horizontal, 8)
                              .padding(.vertical, 3)
                              .overlay(
                                  Capsule()
                                      .stroke(Color.accent.opacity(0.8), lineWidth: 1.5)
                              )
                      }
                  }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background {
                  if option.isRecommended {
                      RoundedRectangle(cornerRadius: 16)
                          .fill(.ultraThinMaterial)
                          .overlay(
                              RoundedRectangle(cornerRadius: 16)
                                  .fill(Color.accent.opacity(0.15))
                          )
                          .overlay(
                              RoundedRectangle(cornerRadius: 16)
                                  .stroke(Color.accent.opacity(0.45), lineWidth: 1)
                          )
                  } else {
                      RoundedRectangle(cornerRadius: 16)
                          .fill(.ultraThinMaterial)
                          .overlay(
                              RoundedRectangle(cornerRadius: 16)
                                  .stroke(.white.opacity(0.1), lineWidth: 1)
                          )
                  }
              }
          }
          .buttonStyle(.plain)
      }
  }

  #Preview {
      ZStack {
          LinearGradient(
              colors: [Color.appBackground, Color.appBackgroundEnd],
              startPoint: .top, endPoint: .bottom
          )
          .ignoresSafeArea()

          VStack(spacing: 12) {
              BedtimeCard(
                  option: BedtimeOption(
                      bedtime: Date(),
                      totalSleepMinutes: 450,
                      cycles: 5,
                      isRecommended: true
                  ),
                  onTap: {}
              )
              BedtimeCard(
                  option: BedtimeOption(
                      bedtime: Date().addingTimeInterval(-5400),
                      totalSleepMinutes: 360,
                      cycles: 4,
                      isRecommended: false
                  ),
                  onTap: {}
              )
          }
          .padding()
      }
  }
  ```

- [ ] **Step 2: Verify preview renders in Xcode**

  Open the preview canvas (`Cmd+Option+Return`). Confirm both cards render — recommended with indigo tint, other neutral.

- [ ] **Step 3: Build**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 4: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/Views/BedtimeCard.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add BedtimeCard view"
  ```

---

## Task 7: BedtimeResultsView

**Files:**
- Create: `SleepWell/Views/BedtimeResultsView.swift`

- [ ] **Step 1: Create `BedtimeResultsView.swift`**

  ```swift
  import SwiftUI

  struct BedtimeResultsView: View {
      @Environment(SleepViewModel.self) private var viewModel
      @Environment(\.openURL) private var openURL

      private var wakeTimeLabel: String {
          let formatter = DateFormatter()
          formatter.dateFormat = "h:mm a"
          return formatter.string(from: viewModel.wakeTime).uppercased()
      }

      private var showDialog: Binding<Bool> {
          Binding(
              get: { viewModel.selectedOption != nil },
              set: { if !$0 { viewModel.selectedOption = nil } }
          )
      }

      private var dialogTitle: String {
          guard let option = viewModel.selectedOption else { return "" }
          let formatter = DateFormatter()
          formatter.dateFormat = "h:mm a"
          return "Set alarm for \(formatter.string(from: option.bedtime))?"
      }

      var body: some View {
          ZStack {
              backgroundView

              VStack(spacing: 0) {
                  // Header
                  VStack(spacing: 4) {
                      Text("WAKE UP AT \(wakeTimeLabel)")
                          .font(.system(size: 11, weight: .semibold))
                          .foregroundStyle(.white.opacity(0.4))
                          .tracking(1.5)

                      Text("Go to bed at…")
                          .font(.system(size: 22, weight: .bold))
                          .foregroundStyle(.white)
                  }
                  .padding(.top, 20)
                  .padding(.bottom, 24)

                  // Cards
                  ScrollView {
                      VStack(spacing: 12) {
                          ForEach(viewModel.bedtimes) { option in
                              BedtimeCard(option: option) {
                                  viewModel.selectedOption = option
                              }
                          }
                      }
                      .padding(.horizontal, 20)
                      .padding(.bottom, 32)
                  }
              }
          }
          .navigationBarBackButtonHidden(false)
          .navigationTitle("")
          .toolbarBackground(.hidden, for: .navigationBar)
          .confirmationDialog(
              dialogTitle,
              isPresented: showDialog,
              titleVisibility: .visible
          ) {
              Button("Set Alarm") {
                  if let url = URL(string: "clock-alarm://") {
                      openURL(url)
                  }
                  viewModel.selectedOption = nil
              }
              Button("Cancel", role: .cancel) {
                  viewModel.selectedOption = nil
              }
          }
      }

      private var backgroundView: some View {
          ZStack {
              LinearGradient(
                  colors: [Color.appBackground, Color.appBackgroundEnd],
                  startPoint: .top,
                  endPoint: .bottom
              )

              // Ambient glow
              RadialGradient(
                  colors: [Color.accent.opacity(0.15), .clear],
                  center: .top,
                  startRadius: 0,
                  endRadius: 200
              )
          }
          .ignoresSafeArea()
      }
  }

  #Preview {
      let vm = SleepViewModel()
      vm.wakeTime = {
          var c = DateComponents()
          c.hour = 8; c.minute = 30
          return Calendar.current.date(from: c) ?? Date()
      }()
      vm.calculate()
      return NavigationStack {
          BedtimeResultsView()
              .environment(vm)
      }
  }
  ```

- [ ] **Step 2: Verify preview renders**

  Check canvas. Confirm 4 cards appear, recommended card has indigo tint.

- [ ] **Step 3: Build**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 4: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/Views/BedtimeResultsView.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add BedtimeResultsView"
  ```

---

## Task 8: WakeTimeInputView

**Files:**
- Create: `SleepWell/Views/WakeTimeInputView.swift`

- [ ] **Step 1: Create `WakeTimeInputView.swift`**

  ```swift
  import SwiftUI

  struct WakeTimeInputView: View {
      @Environment(SleepViewModel.self) private var viewModel

      var body: some View {
          ZStack {
              backgroundView

              VStack(spacing: 32) {
                  Spacer()

                  // Title
                  VStack(spacing: 6) {
                      Text("SleepWell")
                          .font(.system(size: 12, weight: .semibold))
                          .foregroundStyle(.white.opacity(0.4))
                          .tracking(2)

                      Text("When do you wake up?")
                          .font(.system(size: 26, weight: .bold))
                          .foregroundStyle(.white)
                  }

                  // Glass picker container
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

                  // Calculate button
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

              // Ambient glow behind picker
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
          WakeTimeInputView()
              .environment(SleepViewModel())
      }
  }
  ```

- [ ] **Step 2: Verify preview renders**

  Check canvas. Confirm dark background, picker in glass container, indigo button.

- [ ] **Step 3: Build**

  `Cmd+B`. Expected: clean build.

- [ ] **Step 4: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/Views/WakeTimeInputView.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add WakeTimeInputView"
  ```

---

## Task 9: Wire Up App Entry Point

**Files:**
- Modify: `SleepWell/SleepWellApp.swift`

- [ ] **Step 1: Replace SleepWellApp.swift**

  ```swift
  import SwiftUI

  @main
  struct SleepWellApp: App {
      @State private var viewModel = SleepViewModel()

      var body: some Scene {
          WindowGroup {
              NavigationStack {
                  WakeTimeInputView()
                      .navigationDestination(isPresented: $viewModel.showResults) {
                          BedtimeResultsView()
                      }
              }
              .environment(viewModel)
              .preferredColorScheme(.dark)
          }
      }
  }
  ```

- [ ] **Step 2: Build and run on simulator**

  Select an iPhone 16 Pro simulator (iOS 26). `Cmd+R`.

  Expected flow:
  1. Dark input screen with wheel picker and Calculate button
  2. Tap Calculate → results screen pushes in
  3. Back button → returns to input
  4. Tap any card → confirmation dialog with "Set Alarm" / "Cancel"
  5. Tap "Set Alarm" → (will fail to open on simulator, which is expected)

- [ ] **Step 3: Run tests**

  `Cmd+U`. Expected: all SleepCalculator tests pass.

- [ ] **Step 4: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add SleepWell/SleepWellApp.swift
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Wire up app entry point and navigation"
  ```

---

## Task 10: Add .gitignore

**Files:**
- Create: `/Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle/.gitignore`

- [ ] **Step 1: Create .gitignore**

  ```
  # Xcode
  build/
  *.xcworkspace
  xcuserdata/
  DerivedData/
  *.moved-aside
  *.pbxuser
  !default.pbxuser
  *.mode1v3
  !default.mode1v3
  *.mode2v3
  !default.mode2v3
  *.perspectivev3
  !default.perspectivev3

  # Swift Package Manager
  .build/
  .swiftpm/

  # Visual companion
  .superpowers/
  ```

- [ ] **Step 2: Commit**

  ```bash
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle add .gitignore
  git -C /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle commit -m "Add .gitignore"
  ```

---

## Done Criteria

- `Cmd+U` passes all tests
- `Cmd+R` on iPhone 16 Pro simulator: input screen → calculate → results → tap card → dialog → "Set Alarm" tapped without crash
- No compiler warnings

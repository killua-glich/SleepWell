# Settings Inline Pickers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two full-height wheel pickers in SettingsView with a compact list of rows — each showing label + value, expanding an inline wheel picker when tapped.

**Architecture:** A single glassmorphic card holds both setting rows. An `@State var expanded: ExpandedSetting?` enum controls which (if any) picker is open. Tapping a row that is already open collapses it; tapping a closed row opens it and closes any other. The `defaultWakeBinding` helper from the previous implementation is retained unchanged.

**Tech Stack:** SwiftUI, Swift 6, `@Observable`, `@AppStorage`

---

### Task 1: Rewrite SettingsView with inline-expand rows

This is a complete replacement of `SettingsView.swift`. No new files — one file changes.

**Files:**
- Modify: `wakeupCycle/SleepWell/SleepWell/Views/SettingsView.swift`

- [ ] **Step 1: Read the current file**

Read `wakeupCycle/SleepWell/SleepWell/Views/SettingsView.swift` to confirm the current state before overwriting.

- [ ] **Step 2: Replace SettingsView.swift**

Write the following complete file to `wakeupCycle/SleepWell/SleepWell/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private enum ExpandedSetting {
        case fallAsleep, wakeUp
    }

    @State private var expanded: ExpandedSetting? = nil
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
                }

                VStack(spacing: 0) {
                    fallAsleepRow
                    Divider().background(.white.opacity(0.08))
                    wakeUpRow
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

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Fall asleep row

    private var fallAsleepRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expanded = expanded == .fallAsleep ? nil : .fallAsleep
                }
            } label: {
                HStack {
                    Text("Fall asleep time")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(viewModel.fallAsleepMinutes) min")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .fallAsleep {
                @Bindable var vm = viewModel
                Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                    ForEach(minuteRange, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }

    // MARK: - Wake-up row

    private var wakeUpRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expanded = expanded == .wakeUp ? nil : .wakeUp
                }
            } label: {
                HStack {
                    Text("Default wake-up")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(wakeTimeLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .wakeUp {
                DatePicker(
                    "",
                    selection: defaultWakeBinding(vm: viewModel),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }

    // MARK: - Helpers

    private var wakeTimeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.defaultWakeDate)
    }

    // NOTE: defaultWakeHour and defaultWakeMinute are @ObservationIgnored, so SwiftUI's
    // observation machinery won't re-evaluate this binding's get-closure if those values
    // are mutated externally. On this settings screen that's fine — the picker is the
    // only writer.
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

- [ ] **Step 3: Build and run all tests**

```
xcodebuild test \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "(FAIL|PASS|error:|BUILD)"
```

Expected: `BUILD SUCCEEDED`, all tests PASS (the view change has no testable logic — existing tests cover the ViewModel).

- [ ] **Step 4: Commit**

```bash
git -C wakeupCycle add SleepWell/SleepWell/Views/SettingsView.swift
git -C wakeupCycle commit -m "Replace wheel pickers in Settings with inline-expand rows"
```

---

### Task 2: Reload app on simulator

**Files:** none

- [ ] **Step 1: Install and launch**

```bash
xcodebuild build \
  -project wakeupCycle/SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/SleepWellBuild \
  2>&1 | grep -E "(error:|BUILD)"

xcrun simctl terminate booted com.highland.SleepWell 2>/dev/null; \
xcrun simctl install booted /tmp/SleepWellBuild/Build/Products/Debug-iphonesimulator/SleepWell.app && \
xcrun simctl launch booted com.highland.SleepWell
```

Expected: App launches showing the new compact Settings rows.

- [ ] **Step 2: Report back with result**

Open Settings in the running app and confirm both rows appear with label + value, and tapping each expands/collapses the wheel picker inline.

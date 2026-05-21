# Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add VoiceOver labels/grouping, Dynamic Type via semantic fonts, and WCAG AA contrast fixes across all five app views.

**Architecture:** Each view is modified independently — no shared helper needed. Changes are purely additive SwiftUI modifiers (`.accessibilityLabel`, `.accessibilityHidden`, `.accessibilityAddTraits`) plus font replacements and two opacity bumps per view. `BedtimeCard` is the most complex: it computes a spoken label from `BedtimeOption` fields and hides decorative sub-elements.

**Tech Stack:** SwiftUI, iOS 26, `XCTest` / `XCUIApplication.performAccessibilityAudit()` for automated verification.

---

## File map

| File | What changes |
|---|---|
| `SleepWell/Views/BedtimeCard.swift` | Accessibility label computed from option, decorative elements hidden, semantic fonts, contrast |
| `SleepWell/Views/WakeTimeInputView.swift` | Button labels + hints, decorative elements hidden, heading trait, semantic fonts, contrast |
| `SleepWell/Views/WakeTimePickerView.swift` | Decorative elements hidden, heading trait, semantic fonts |
| `SleepWell/Views/BedtimeResultsView.swift` | Header group combine + heading trait, semantic fonts |
| `SleepWell/Views/SettingsView.swift` | Row button labels, toggle label, section headers hidden, semantic fonts |
| `SleepWellUITests/SleepWellUITests.swift` | Add `performAccessibilityAudit()` tests for all screens |

---

### Task 1: BedtimeCard — accessibility labels, semantic fonts, contrast

**Files:**
- Modify: `SleepWell/SleepWell/Views/BedtimeCard.swift`

**Context:**  
`BedtimeCard` is a `Button` whose body contains a time string, AM/PM text, duration, cycle dots, and a badge overlay. VoiceOver currently reads each sub-element separately. We need one coherent label on the button and silence the decorative internals. Fonts are all hardcoded `size:` values — replace with semantic styles. Two contrast bumps.

`BedtimeOption` has: `bedtime: Date`, `totalSleepMinutes: Int`, `cycles: Int`, `isRecommended: Bool`, `napLabel: String?`.

- [ ] **Step 1: Replace `SleepWell/SleepWell/Views/BedtimeCard.swift` with the following**

```swift
import SwiftUI

struct BedtimeCard: View {
    let option: BedtimeOption
    let onTap: () -> Void

    private static var uses24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return !format.contains("a")
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.uses24Hour ? "HH:mm" : "h:mm"
        return formatter.string(from: option.bedtime)
    }

    private var amPmString: String {
        guard !Self.uses24Hour else { return "" }
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

    private var hasTag: Bool {
        option.isRecommended || option.napLabel != nil
    }

    // MARK: - Accessibility

    private var accessibilityTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: option.bedtime)
    }

    private var accessibleDurationString: String {
        let hours = option.totalSleepMinutes / 60
        let minutes = option.totalSleepMinutes % 60
        if hours == 0 { return "\(minutes) minutes" }
        if minutes == 0 { return "\(hours) hour\(hours == 1 ? "" : "s")" }
        return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minutes"
    }

    private var accessibilityCardLabel: String {
        if let nap = option.napLabel {
            return "\(accessibilityTimeString), \(nap) nap, \(accessibleDurationString)"
        }
        let recommended = option.isRecommended ? "recommended, " : ""
        let cycles = "\(option.cycles) sleep cycle\(option.cycles == 1 ? "" : "s")"
        return "\(accessibilityTimeString), \(recommended)\(accessibleDurationString), \(cycles)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                // Left: time + duration
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(timeString)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        if !amPmString.isEmpty {
                            Text(amPmString)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                                .accessibilityHidden(true)
                        }
                    }
                    Text(option.totalSleepFormatted)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(option.isRecommended ? 0.6 : 0.55))
                        .accessibilityHidden(true)
                }

                Spacer()

                // Right: cycle dots (hidden for nap options)
                if option.napLabel == nil {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(option.cycles) cycles")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
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
                    }
                    .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, hasTag ? 30 : 14)
            .padding(.bottom, 14)
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
            .overlay(alignment: .topTrailing) {
                if option.isRecommended {
                    Text("RECOMMENDED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule()
                                .stroke(Color.accent.opacity(0.8), lineWidth: 1.5)
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                        .accessibilityHidden(true)
                } else if let label = option.napLabel {
                    Text(label.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityCardLabel)
        .accessibilityHint("Double tap to set alarm")
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
                    bedtime: Date().addingTimeInterval(20 * 60),
                    totalSleepMinutes: 20,
                    cycles: 0,
                    isRecommended: false,
                    napLabel: "Refreshing"
                ),
                onTap: {}
            )
            BedtimeCard(
                option: BedtimeOption(
                    bedtime: Date().addingTimeInterval(90 * 60),
                    totalSleepMinutes: 90,
                    cycles: 1,
                    isRecommended: false,
                    napLabel: "Deep Rest"
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
```

- [ ] **Step 2: Build and run existing tests**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **` — 20 tests pass.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/BigBoy/Home2/Documents/xCode/wakeupCycle
git add SleepWell/SleepWell/Views/BedtimeCard.swift
git commit -m "Accessibility: VoiceOver labels, semantic fonts, contrast in BedtimeCard"
```

---

### Task 2: WakeTimeInputView — accessibility labels, semantic fonts, contrast

**Files:**
- Modify: `SleepWell/SleepWell/Views/WakeTimeInputView.swift`

**Context:**  
Home screen. Three mode card `Button`s have no labels — VoiceOver reads their internal text children in an awkward order. The gear icon button has no label. The logo and wordmark are decorative. Section heading needs `.isHeader` trait.

- [ ] **Step 1: Replace `SleepWell/SleepWell/Views/WakeTimeInputView.swift` with the following**

```swift
import SwiftUI

struct WakeTimeInputView: View {
    @Environment(SleepViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()
                    .frame(maxHeight: 40)

                VStack(spacing: 6) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 110)
                        .accessibilityHidden(true)

                    Text("SleepWell")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)
                        .accessibilityHidden(true)

                    Text("How can I help?")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
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
                    .accessibilityLabel("Sleep Now")
                    .accessibilityHint("Shows the best times to wake up")

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
                    .accessibilityLabel("Wake Up At")
                    .accessibilityHint("Tell me when to go to bed")

                    Button {
                        viewModel.calculateNapNow()
                    } label: {
                        modeCard(
                            title: "Take a Nap",
                            subtitle: "Power nap or full recovery",
                            icon: "bed.double.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Take a Nap")
                    .accessibilityHint("Power nap or full recovery")
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 60)
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
                .accessibilityLabel("Settings")
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
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .accessibilityHidden(true)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .accessibilityHidden(true)
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

- [ ] **Step 2: Build and run existing tests**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/WakeTimeInputView.swift
git commit -m "Accessibility: VoiceOver labels, semantic fonts, contrast in WakeTimeInputView"
```

---

### Task 3: WakeTimePickerView — accessibility labels, semantic fonts

**Files:**
- Modify: `SleepWell/SleepWell/Views/WakeTimePickerView.swift`

**Context:**  
Picker screen. "SleepWell" wordmark is decorative. "When do you wake up?" should be a header. `DatePicker` has native VoiceOver — no changes needed. "Calculate Bedtimes" button text is its own label — no change needed.

- [ ] **Step 1: Replace `SleepWell/SleepWell/Views/WakeTimePickerView.swift` with the following**

```swift
import SwiftUI

struct WakeTimePickerView: View {
    @Environment(SleepViewModel.self) private var viewModel
    @State private var hasPrefilledDefault = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("SleepWell")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)
                        .accessibilityHidden(true)

                    Text("When do you wake up?")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
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
                        .font(.headline)
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
            if !hasPrefilledDefault {
                viewModel.wakeTime = viewModel.defaultWakeDate
                hasPrefilledDefault = true
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

- [ ] **Step 2: Build and run existing tests**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/WakeTimePickerView.swift
git commit -m "Accessibility: VoiceOver labels, semantic fonts in WakeTimePickerView"
```

---

### Task 4: BedtimeResultsView — accessibility grouping, semantic fonts

**Files:**
- Modify: `SleepWell/SleepWell/Views/BedtimeResultsView.swift`

**Context:**  
The header area is two separate `Text` views: an eyebrow ("WAKE UP AT 7:00 AM") and a title ("Go to bed at…"). They should be read as one heading by VoiceOver. Wrap their container `VStack` with `.accessibilityElement(children: .combine)` + `.accessibilityAddTraits(.isHeader)`. The background gradient and glow are purely decorative — they are in a separate `backgroundView` computed property and SwiftUI already excludes non-interactive shapes from the accessibility tree, so no change needed there.

- [ ] **Step 1: Replace `SleepWell/SleepWell/Views/BedtimeResultsView.swift` with the following**

```swift
import SwiftUI

struct BedtimeResultsView: View {
    @Environment(SleepViewModel.self) private var viewModel
    @State private var alarmScheduler = AlarmScheduler()
    @State private var alarmResultMessage: String? = nil

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private var headerEyebrow: String {
        switch viewModel.mode {
        case .wakeUp:
            return "WAKE UP AT \(Self.timeFormatter.string(from: viewModel.wakeTime).uppercased())"
        case .sleepNow:
            return "SLEEPING NOW"
        case .nap:
            return "NAPPING NOW"
        }
    }

    private var headerTitle: String {
        switch viewModel.mode {
        case .wakeUp: return "Go to bed at…"
        case .sleepNow: return "Wake up at…"
        case .nap: return "Wake up at…"
        }
    }

    private var showDialog: Binding<Bool> {
        Binding(
            get: { viewModel.selectedOption != nil },
            set: { if !$0 { viewModel.selectedOption = nil } }
        )
    }

    private var dialogTitle: String {
        guard let option = viewModel.selectedOption else { return "" }
        return "Set alarm for \(Self.timeFormatter.string(from: option.bedtime))?"
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(headerEyebrow)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.5)

                    Text(headerTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
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
                guard let option = viewModel.selectedOption else { return }
                let alarmDate = option.bedtime
                viewModel.selectedOption = nil
                Task {
                    let result = await alarmScheduler.schedule(at: alarmDate, label: viewModel.alarmLabel)
                    switch result {
                    case .scheduled:
                        alarmResultMessage = "Alarm set"
                    case .denied:
                        alarmResultMessage = "Alarm access denied — enable it in Settings"
                    case .unsupportedOS:
                        alarmResultMessage = "Setting alarms requires iOS 26 or later"
                    case .failed:
                        alarmResultMessage = "Could not set alarm"
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.selectedOption = nil
            }
        }
        .alert(alarmResultMessage ?? "", isPresented: .init(
            get: { alarmResultMessage != nil },
            set: { if !$0 { alarmResultMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
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
    NavigationStack {
        BedtimeResultsView()
            .environment({
                let vm = SleepViewModel()
                var c = DateComponents()
                c.hour = 8
                c.minute = 30
                vm.wakeTime = Calendar.current.date(from: c) ?? Date()
                vm.calculate()
                return vm
            }())
    }
}
```

- [ ] **Step 2: Build and run existing tests**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/BedtimeResultsView.swift
git commit -m "Accessibility: VoiceOver header grouping, semantic fonts in BedtimeResultsView"
```

---

### Task 5: SettingsView — accessibility labels, semantic fonts

**Files:**
- Modify: `SleepWell/SleepWell/Views/SettingsView.swift`

**Context:**  
Five interactive rows act as buttons but have no accessibility labels — VoiceOver reads only the row label text and misses the current value. The toggle uses `.labelsHidden()` so needs an explicit `.accessibilityLabel`. Section headers ("PREFERENCES", "ALARMS", "SCHEDULE") are decorative orientation text — hide from VoiceOver. The "SleepWell" wordmark and "Settings" heading follow the same pattern as other views.

Replace the whole file:

- [ ] **Step 1: Replace `SleepWell/SleepWell/Views/SettingsView.swift` with the following**

```swift
import SwiftUI
import AlarmKit

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private enum ExpandedSetting {
        case fallAsleep, wakeUp, weekday, weekend
    }

    @State private var expanded: ExpandedSetting? = nil
    @AppStorage("defaultWakeHour", store: .appGroup) private var defaultWakeHour: Int = 7
    @AppStorage("defaultWakeMinute", store: .appGroup) private var defaultWakeMinute: Int = 0
    private let minuteRange = Array(5...60)
    @AppStorage("scheduleEnabled", store: .appGroup) private var scheduleEnabled: Bool = false
    @AppStorage("weekdayWakeHour", store: .appGroup) private var weekdayWakeHour: Int = 7
    @AppStorage("weekdayWakeMinute", store: .appGroup) private var weekdayWakeMinute: Int = 0
    @AppStorage("weekendWakeHour", store: .appGroup) private var weekendWakeHour: Int = 8
    @AppStorage("weekendWakeMinute", store: .appGroup) private var weekendWakeMinute: Int = 0
    @AppStorage("alarmLabel", store: .appGroup) private var alarmLabel: String = "Wake Up"
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteResultMessage: String? = nil

    var body: some View {
        ZStack {
            backgroundView

            if expanded != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expanded = nil
                        }
                    }
            }

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("SleepWell")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)
                        .accessibilityHidden(true)
                    Text("Settings")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("PREFERENCES")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .padding(.horizontal, 28)
                        .accessibilityHidden(true)

                VStack(spacing: 0) {
                    fallAsleepRow
                    Divider().overlay(Color.white.opacity(0.08))
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
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expanded)
                }

                alarmsSection

                VStack(alignment: .leading, spacing: 6) {
                    Text("SCHEDULE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .padding(.horizontal, 28)
                        .accessibilityHidden(true)

                    VStack(spacing: 0) {
                        scheduleToggleRow
                        if scheduleEnabled {
                            Divider().overlay(Color.white.opacity(0.08))
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            weekdayRow
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            Divider().overlay(Color.white.opacity(0.08))
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            weekendRow
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
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

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Alarms section

    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ALARMS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1.5)
                .padding(.horizontal, 28)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                // Alarm Name row
                HStack {
                    Text("Alarm Name")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    TextField("Wake Up", text: $alarmLabel)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160)
                        .accessibilityLabel("Alarm Name")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Delete All Alarms button (iOS 26+ only)
                if #available(iOS 26, *) {
                    Divider().overlay(Color.white.opacity(0.08))

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Text("Delete All Alarms")
                                .font(.body)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Delete all scheduled alarms?",
                        isPresented: $showDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Delete All", role: .destructive) {
                            Task { await deleteAllAlarms() }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
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
            .alert(deleteResultMessage ?? "", isPresented: .init(
                get: { deleteResultMessage != nil },
                set: { if !$0 { deleteResultMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    // MARK: - Fall asleep row

    private var fallAsleepRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .fallAsleep ? nil : .fallAsleep
            } label: {
                HStack {
                    Text("Fall asleep time")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(viewModel.fallAsleepMinutes) min")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fall asleep time, \(viewModel.fallAsleepMinutes) minutes")
            .accessibilityHint("Double tap to adjust")

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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }

    // MARK: - Wake-up row

    private var wakeUpRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .wakeUp ? nil : .wakeUp
            } label: {
                HStack {
                    Text("Default wake-up")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(wakeTimeLabel)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Default wake-up, \(wakeTimeLabel)")
            .accessibilityHint("Double tap to adjust")

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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }

    // MARK: - Schedule toggle row

    private var scheduleToggleRow: some View {
        HStack {
            Text("Wake-up schedule")
                .font(.body)
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: Binding(
                get: { scheduleEnabled },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expanded = nil
                    }
                    scheduleEnabled = newValue
                }
            ))
            .labelsHidden()
            .tint(Color.accent)
            .accessibilityLabel("Wake-up schedule")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Weekday row

    private var weekdayRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .weekday ? nil : .weekday
            } label: {
                HStack {
                    Text("Weekdays")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekdayWakeHour, weekdayWakeMinute))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weekdays, \(String(format: "%02d:%02d", weekdayWakeHour, weekdayWakeMinute))")
            .accessibilityHint("Double tap to adjust")

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

    // MARK: - Weekend row

    private var weekendRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .weekend ? nil : .weekend
            } label: {
                HStack {
                    Text("Weekend")
                        .font(.body)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekendWakeHour, weekendWakeMinute))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weekend, \(String(format: "%02d:%02d", weekendWakeHour, weekendWakeMinute))")
            .accessibilityHint("Double tap to adjust")

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

    // MARK: - Helpers

    @available(iOS 26, *)
    private func deleteAllAlarms() async {
        let alarms = (try? AlarmManager.shared.alarms) ?? []
        for alarm in alarms {
            try? await AlarmManager.shared.cancel(id: alarm.id)
        }
        let count = alarms.count
        deleteResultMessage = count == 0
            ? "No alarms scheduled"
            : "Deleted \(count) alarm\(count == 1 ? "" : "s")"
    }

    private var wakeTimeLabel: String {
        String(format: "%02d:%02d", defaultWakeHour, defaultWakeMinute)
    }

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

- [ ] **Step 2: Build and run existing tests**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Accessibility: VoiceOver labels, semantic fonts in SettingsView"
```

---

### Task 6: Add accessibility audit UI tests

**Files:**
- Modify: `SleepWell/SleepWellUITests/SleepWellUITests.swift`

**Context:**  
`XCUIApplication.performAccessibilityAudit()` (iOS 17+) runs Apple's built-in accessibility checker against the current screen. It catches unlabeled buttons, empty interactive elements, and contrast issues. We add one test per screen. Navigation uses the labels we just added.

The `SleepWell` scheme must be selected (not `SleepWellUITests`) when running — the UI test target is embedded. Run with `-testPlan` or use the scheme's test action.

- [ ] **Step 1: Replace `SleepWell/SleepWellUITests/SleepWellUITests.swift` with the following**

```swift
import XCTest

final class AccessibilityAuditTests: XCTestCase {

    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - Home screen

    @MainActor
    func testHomeScreenAccessibility() throws {
        try app.performAccessibilityAudit()
    }

    // MARK: - Wake time picker

    @MainActor
    func testWakeTimePickerAccessibility() throws {
        app.buttons["Wake Up At"].tap()
        try app.performAccessibilityAudit()
    }

    // MARK: - Bedtime results (Sleep Now path — no picker needed)

    @MainActor
    func testBedtimeResultsAccessibility() throws {
        app.buttons["Sleep Now"].tap()
        // Wait for results to render
        let firstCard = app.buttons.element(boundBy: 0)
        XCTAssertTrue(firstCard.waitForExistence(timeout: 3))
        try app.performAccessibilityAudit()
    }

    // MARK: - Settings

    @MainActor
    func testSettingsAccessibility() throws {
        app.buttons["Settings"].tap()
        try app.performAccessibilityAudit()
    }
}
```

- [ ] **Step 2: Build and run the full test suite**

```bash
xcodebuild -project SleepWell/SleepWell.xcodeproj \
  -scheme SleepWell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  build test 2>&1 | grep -E "Test Suite|PASS|FAIL|error:" | tail -20
```

Expected: All unit tests pass (20). UI audit tests pass. If any audit test reports a failure, read the issue description in the output — it names the element and the violation.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWellUITests/SleepWellUITests.swift
git commit -m "Add XCUIAccessibilityAudit tests for all screens"
```

---

## Self-review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| WakeTimeInputView — logo hidden | Task 2 |
| WakeTimeInputView — wordmark hidden | Task 2 |
| WakeTimeInputView — heading trait | Task 2 |
| WakeTimeInputView — 3 button labels + hints | Task 2 |
| WakeTimeInputView — gear label "Settings" | Task 2 |
| WakeTimeInputView — subtitle + chevron hidden | Task 2 |
| WakeTimePickerView — wordmark hidden, heading trait | Task 3 |
| BedtimeResultsView — header combine + isHeader | Task 4 |
| BedtimeCard — computed label with time/recommended/duration/cycles | Task 1 |
| BedtimeCard — hint "Double tap to set alarm" | Task 1 |
| BedtimeCard — dots, badge, AM/PM, duration text hidden | Task 1 |
| SettingsView — wordmark hidden, heading trait | Task 5 |
| SettingsView — section headers hidden | Task 5 |
| SettingsView — 4 row button labels + hints | Task 5 |
| SettingsView — toggle label | Task 5 |
| All views — semantic fonts | Tasks 1–5 |
| BedtimeCard contrast: duration 0.4→0.55, cycles 0.45→0.55 | Task 1 |
| WakeTimeInputView contrast: subtitle 0.5→0.6 | Task 2 |
| BedtimeResultsView contrast: eyebrow 0.4→0.5 | Task 4 |
| Automated verification | Task 6 |

All requirements covered. ✓

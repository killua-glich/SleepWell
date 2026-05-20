# Alarm Name & Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users set a default alarm label in Settings, and delete all scheduled AlarmKit alarms from a new ALARMS settings section.

**Architecture:** Add one `@AppStorage` key to `SleepViewModel`, thread it through to `AlarmScheduler.schedule(at:label:)` in `BedtimeResultsView`, and add a new ALARMS card in `SettingsView` with a text field and a destructive delete button.

**Tech Stack:** SwiftUI, AlarmKit (iOS 26+), `@AppStorage`, Swift Testing

---

## File Map

| File | Change |
|------|--------|
| `SleepWell/ViewModels/SleepViewModel.swift` | Add `@AppStorage("alarmLabel") var alarmLabel: String = "Wake Up"` |
| `SleepWell/Views/BedtimeResultsView.swift` | Pass `viewModel.alarmLabel` to `alarmScheduler.schedule(at:label:)` |
| `SleepWell/Views/SettingsView.swift` | Add ALARMS section: alarm name text field + delete all button |
| `SleepWellTests/SleepViewModelTests.swift` | Add test for `alarmLabel` default value |

---

### Task 1: Add alarmLabel to SleepViewModel + test

**Files:**
- Modify: `SleepWell/SleepWell/ViewModels/SleepViewModel.swift`
- Test: `SleepWell/SleepWellTests/SleepViewModelTests.swift`

- [ ] **Step 1: Write the failing test**

Add a new `@Suite` at the bottom of `SleepViewModelTests.swift`:

```swift
@Suite("SleepViewModel alarmLabel")
struct AlarmLabelTests {

    @Test("alarmLabel default is Wake Up")
    func alarmLabelDefault() {
        UserDefaults.standard.removeObject(forKey: "alarmLabel")
        let vm = SleepViewModel()
        #expect(vm.alarmLabel == "Wake Up")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

In Xcode: Product → Test (⌘U), or run the `AlarmLabelTests` suite.

Expected: FAIL — `SleepViewModel` has no `alarmLabel` property.

- [ ] **Step 3: Add alarmLabel to SleepViewModel**

In `SleepViewModel.swift`, after the `weekendWakeMinute` property (line ~39), add:

```swift
@ObservationIgnored
@AppStorage("alarmLabel") var alarmLabel: String = "Wake Up"
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS — `alarmLabel` returns `"Wake Up"` when key absent from UserDefaults.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/ViewModels/SleepViewModel.swift SleepWell/SleepWellTests/SleepViewModelTests.swift
git commit -m "Add alarmLabel AppStorage property to SleepViewModel"
```

---

### Task 2: Wire alarmLabel through BedtimeResultsView

**Files:**
- Modify: `SleepWell/SleepWell/Views/BedtimeResultsView.swift`

No new test needed — `AlarmScheduler.schedule(at:label:)` already accepts `label`; this is a one-line call-site change.

- [ ] **Step 1: Find the schedule call**

In `BedtimeResultsView.swift`, locate this line (inside the `Button("Set Alarm")` action, around line 92):

```swift
let result = await alarmScheduler.schedule(at: alarmDate)
```

- [ ] **Step 2: Pass alarmLabel**

Replace it with:

```swift
let result = await alarmScheduler.schedule(at: alarmDate, label: viewModel.alarmLabel)
```

- [ ] **Step 3: Build to confirm no errors**

In Xcode: Product → Build (⌘B). Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWell/Views/BedtimeResultsView.swift
git commit -m "Pass alarmLabel to AlarmScheduler from BedtimeResultsView"
```

---

### Task 3: Add ALARMS section to SettingsView

**Files:**
- Modify: `SleepWell/SleepWell/Views/SettingsView.swift`

No unit test — UI-only change. Manual verification steps at the end.

- [ ] **Step 1: Add AppStorage + state vars**

At the top of `SettingsView` (after the existing `@AppStorage("weekendWakeMinute")` line, around line 18), add:

```swift
@AppStorage("alarmLabel") private var alarmLabel: String = "Wake Up"
@State private var showDeleteConfirm: Bool = false
@State private var deleteResultMessage: String? = nil
```

- [ ] **Step 2: Add the alarmsSection computed property**

Add this before the `// MARK: - Fall asleep row` comment:

```swift
// MARK: - Alarms section

private var alarmsSection: some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("ALARMS")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(1.5)
            .padding(.horizontal, 28)

        VStack(spacing: 0) {
            // Alarm Name row
            HStack {
                Text("Alarm Name")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                TextField("Wake Up", text: $alarmLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160)
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
                            .font(.system(size: 15))
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
```

- [ ] **Step 3: Add deleteAllAlarms helper**

Add this after the `// MARK: - Helpers` comment (before `wakeTimeLabel`):

```swift
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
```

- [ ] **Step 4: Add AlarmKit import**

At the top of `SettingsView.swift`, after `import SwiftUI`, add:

```swift
import AlarmKit
```

- [ ] **Step 5: Insert alarmsSection into body**

In the `body` VStack, insert `alarmsSection` between the PREFERENCES section and the SCHEDULE section. The VStack currently looks like:

```swift
VStack(spacing: 32) {
    Spacer()
    // title VStack
    // PREFERENCES VStack
    // SCHEDULE VStack
    Spacer()
}
```

Add `alarmsSection` between PREFERENCES and SCHEDULE:

```swift
VStack(spacing: 32) {
    Spacer()

    VStack(spacing: 6) { /* title */ }

    VStack(alignment: .leading, spacing: 6) { /* PREFERENCES */ }

    alarmsSection   // ← add this line

    VStack(alignment: .leading, spacing: 6) { /* SCHEDULE */ }

    Spacer()
}
```

- [ ] **Step 6: Build and verify**

Product → Build (⌘B). Expected: builds cleanly.

- [ ] **Step 7: Manual verify**

1. Open Settings — ALARMS section appears between PREFERENCES and SCHEDULE
2. Alarm Name field shows "Wake Up" by default, is editable
3. Change alarm name → go to results screen → set alarm → confirm name appears in Clock alarm title
4. On iOS 26 device/sim: tap "Delete All Alarms" → confirmation dialog appears → confirm → "Deleted N alarms" message shown
5. On iOS < 26: "Delete All Alarms" row not visible

- [ ] **Step 8: Commit**

```bash
git add SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Add ALARMS settings section with alarm name field and delete all button"
```

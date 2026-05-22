# Live Activity — Bedtime Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bedtime countdown Live Activity to Wake Up mode — after setting an alarm the user can start a silent background countdown that surfaces on Dynamic Island and lock screen as bedtime approaches, managed via a new Manager tab.

**Architecture:** Live Activity runs in the existing widget extension (`SleepWellWidget`). `CountdownManager` (main app, `@Observable`) owns the Activity lifecycle and schedules three `UNUserNotificationCenter` requests (3h silent, 1h gentle, bedtime gentle). A `ScheduledAlarmStore` persists alarm metadata to UserDefaults so `ManagerView` can list and cancel individual alarms. A `TabView` at the root replaces the single-screen layout.

**Tech Stack:** ActivityKit (iOS 16.1+), WidgetKit, UserNotifications, Swift Testing, SwiftUI `@Observable`

---

## File Map

| File | Action | Target(s) |
|------|--------|-----------|
| `SleepWell/SleepWell/Model/BedtimeCountdownAttributes.swift` | Create | Main app + Widget extension |
| `SleepWell/SleepWellWidget/BedtimeCountdownLiveActivity.swift` | Create | Widget extension |
| `SleepWell/SleepWellWidget/SleepWellWidgetBundle.swift` | Modify | Widget extension |
| `SleepWell/SleepWell/Model/ScheduledAlarmStore.swift` | Create | Main app |
| `SleepWell/SleepWell/Model/AlarmScheduler.swift` | Modify | Main app |
| `SleepWell/SleepWell/Model/CountdownManager.swift` | Create | Main app |
| `SleepWell/SleepWell/Views/ManagerView.swift` | Create | Main app |
| `SleepWell/SleepWell/SleepWellApp.swift` | Modify | Main app |
| `SleepWell/SleepWell/Views/BedtimeResultsView.swift` | Modify | Main app |
| `SleepWell/SleepWell/Views/SettingsView.swift` | Modify | Main app |
| `SleepWellTests/ScheduledAlarmStoreTests.swift` | Create | Tests |
| `SleepWellTests/CountdownManagerTests.swift` | Create | Tests |

---

## Task 1: `BedtimeCountdownAttributes` data model

**Files:**
- Create: `SleepWell/SleepWell/Model/BedtimeCountdownAttributes.swift`

- [ ] **Step 1: Create the file**

```swift
// SleepWell/SleepWell/Model/BedtimeCountdownAttributes.swift
import ActivityKit
import Foundation

enum CountdownPhase: String, Codable, Sendable {
    case active    // >1h remaining — minimal Dynamic Island presence
    case imminent  // ≤1h remaining — full lock screen countdown visible
}

struct BedtimeCountdownAttributes: ActivityAttributes {
    let targetBedtime: Date

    struct ContentState: Codable, Hashable, Sendable {
        var phase: CountdownPhase
    }
}
```

- [ ] **Step 2: Add file to both Xcode targets**

In Xcode: select `BedtimeCountdownAttributes.swift` in the file inspector → check both `SleepWell` (main app) and `SleepWellWidgetExtension` under Target Membership.

- [ ] **Step 3: Add `NSSupportsLiveActivities` to Info.plist**

In Xcode: select the `SleepWell` target → Info tab → add key `NSSupportsLiveActivities` with value `YES` (Boolean).

- [ ] **Step 4: Verify `Color+Hex.swift` is in the widget extension target**

In Xcode: select `Color+Hex.swift` → file inspector → confirm `SleepWellWidgetExtension` is checked under Target Membership. If not, add it.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/Model/BedtimeCountdownAttributes.swift
git commit -m "Add BedtimeCountdownAttributes and CountdownPhase for Live Activity"
```

---

## Task 2: `ScheduledAlarmStore` — persist alarm metadata

`AlarmKit` doesn't expose the scheduled `Date` from a stored alarm, so we persist it ourselves in `UserDefaults.appGroup`.

**Files:**
- Create: `SleepWell/SleepWell/Model/ScheduledAlarmStore.swift`
- Create: `SleepWell/SleepWellTests/ScheduledAlarmStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// SleepWell/SleepWellTests/ScheduledAlarmStoreTests.swift
import Testing
import Foundation
@testable import SleepWell

@Suite("ScheduledAlarmStore")
struct ScheduledAlarmStoreTests {

    // Use a fresh in-memory defaults for each test
    func makeStore() -> ScheduledAlarmStore {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return ScheduledAlarmStore(defaults: defaults)
    }

    @Test("starts empty")
    func startsEmpty() {
        #expect(makeStore().all().isEmpty)
    }

    @Test("add and retrieve alarm")
    func addAndRetrieve() throws {
        let store = makeStore()
        let alarm = ScheduledAlarm(id: UUID(), date: Date(), label: "Wake Up")
        store.add(alarm)
        let all = store.all()
        #expect(all.count == 1)
        #expect(all[0].id == alarm.id)
        #expect(all[0].label == "Wake Up")
    }

    @Test("remove by id")
    func removeById() {
        let store = makeStore()
        let a = ScheduledAlarm(id: UUID(), date: Date(), label: "A")
        let b = ScheduledAlarm(id: UUID(), date: Date(), label: "B")
        store.add(a)
        store.add(b)
        store.remove(id: a.id)
        let all = store.all()
        #expect(all.count == 1)
        #expect(all[0].id == b.id)
    }

    @Test("removeAll clears store")
    func removeAllClears() {
        let store = makeStore()
        store.add(ScheduledAlarm(id: UUID(), date: Date(), label: "A"))
        store.add(ScheduledAlarm(id: UUID(), date: Date(), label: "B"))
        store.removeAll()
        #expect(store.all().isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to confirm they fail**

In Xcode: `Cmd+U` or `Product → Test`. Expect: compile error — `ScheduledAlarmStore` not found.

- [ ] **Step 3: Create `ScheduledAlarmStore`**

```swift
// SleepWell/SleepWell/Model/ScheduledAlarmStore.swift
import Foundation

struct ScheduledAlarm: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let label: String
}

final class ScheduledAlarmStore: @unchecked Sendable {
    private static let key = "com.highland.SleepWell.scheduledAlarms"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
    }

    func all() -> [ScheduledAlarm] {
        guard let data = defaults.data(forKey: Self.key),
              let alarms = try? JSONDecoder().decode([ScheduledAlarm].self, from: data)
        else { return [] }
        return alarms
    }

    func add(_ alarm: ScheduledAlarm) {
        var alarms = all()
        alarms.append(alarm)
        save(alarms)
    }

    func remove(id: UUID) {
        save(all().filter { $0.id != id })
    }

    func removeAll() {
        save([])
    }

    private func save(_ alarms: [ScheduledAlarm]) {
        defaults.set(try? JSONEncoder().encode(alarms), forKey: Self.key)
    }
}
```

- [ ] **Step 4: Run tests — expect all pass**

`Cmd+U`. Expected: 4 tests pass in `ScheduledAlarmStoreTests`.

- [ ] **Step 5: Update `AlarmScheduler` to write to store on schedule**

Replace the full content of `SleepWell/SleepWell/Model/AlarmScheduler.swift`:

```swift
import AlarmKit
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.highland.SleepWell", category: "AlarmScheduler")

@available(iOS 26, *)
struct SleepAlarmMetadata: AlarmMetadata {}

enum AlarmResult {
    case scheduled
    case denied
    case unsupportedOS
    case failed(Error)
}

@MainActor
final class AlarmScheduler {
    let store: ScheduledAlarmStore

    init(store: ScheduledAlarmStore = ScheduledAlarmStore()) {
        self.store = store
    }

    func schedule(at date: Date, label: String = "Time to wake up") async -> AlarmResult {
        logger.info("schedule() called for date: \(date)")

        guard #available(iOS 26, *) else {
            logger.warning("iOS version too old for AlarmKit")
            return .unsupportedOS
        }

        let manager = AlarmManager.shared

        do {
            logger.info("Calling requestAuthorization()")
            let state = try await manager.requestAuthorization()
            logger.info("requestAuthorization() returned: \(String(describing: state))")
            guard state == .authorized else {
                logger.warning("Not authorized — state: \(String(describing: state))")
                return .denied
            }
        } catch {
            logger.error("requestAuthorization() threw: \(error)")
            return .failed(error)
        }

        let alarmID = UUID()
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: label))
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes<SleepAlarmMetadata>(
            presentation: presentation,
            tintColor: Color.accentColor
        )
        let config = AlarmManager.AlarmConfiguration<SleepAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes
        )

        do {
            logger.info("Scheduling alarm at \(date)")
            let alarm = try await manager.schedule(id: alarmID, configuration: config)
            let allAlarms = (try? manager.alarms) ?? []
            logger.info("Alarm scheduled. ID: \(alarm.id). Total: \(allAlarms.count)")
            store.add(ScheduledAlarm(id: alarmID, date: date, label: label))
            return .scheduled
        } catch {
            logger.error("schedule() threw: \(error)")
            return .failed(error)
        }
    }

    func cancel(id: UUID) async {
        guard #available(iOS 26, *) else { return }
        try? await AlarmManager.shared.cancel(id: id)
        store.remove(id: id)
    }

    func cancelAll() async {
        guard #available(iOS 26, *) else { return }
        let alarms = (try? AlarmManager.shared.alarms) ?? []
        for alarm in alarms {
            try? await AlarmManager.shared.cancel(id: alarm.id)
        }
        store.removeAll()
    }
}
```

- [ ] **Step 6: Run tests — still pass**

`Cmd+U`. All 4 `ScheduledAlarmStoreTests` pass.

- [ ] **Step 7: Commit**

```bash
git add SleepWell/SleepWell/Model/ScheduledAlarmStore.swift \
        SleepWell/SleepWell/Model/AlarmScheduler.swift \
        SleepWell/SleepWellTests/ScheduledAlarmStoreTests.swift
git commit -m "Add ScheduledAlarmStore and update AlarmScheduler to persist alarm metadata"
```

---

## Task 3: `CountdownManager` — Live Activity lifecycle

**Files:**
- Create: `SleepWell/SleepWell/Model/CountdownManager.swift`
- Create: `SleepWell/SleepWellTests/CountdownManagerTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// SleepWell/SleepWellTests/CountdownManagerTests.swift
import Testing
import Foundation
@testable import SleepWell

@Suite("CountdownManager state")
@MainActor
struct CountdownManagerTests {

    @Test("starts inactive")
    func startsInactive() {
        let manager = CountdownManager()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }

    @Test("start sets isActive and targetBedtime")
    func startSetsState() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(3 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        #expect(manager.isActive)
        #expect(manager.targetBedtime == bedtime)
    }

    @Test("cancel clears state")
    func cancelClearsState() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(3 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        await manager.cancel()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }

    @Test("handleForeground with >1h remaining stays active")
    func handleForegroundMoreThanOneHour() async {
        let manager = CountdownManager()
        let bedtime = Date().addingTimeInterval(2 * 3600)
        await manager.startForTesting(bedtime: bedtime)
        await manager.handleForeground()
        #expect(manager.isActive)
    }

    @Test("handleForeground with past bedtime ends countdown")
    func handleForegroundPastBedtime() async {
        let manager = CountdownManager()
        let pastBedtime = Date().addingTimeInterval(-60) // 1 minute ago
        await manager.startForTesting(bedtime: pastBedtime)
        await manager.handleForeground()
        #expect(!manager.isActive)
        #expect(manager.targetBedtime == nil)
    }
}
```

- [ ] **Step 2: Run tests to confirm they fail**

`Cmd+U`. Expected: compile error — `CountdownManager` not found.

- [ ] **Step 3: Create `CountdownManager`**

```swift
// SleepWell/SleepWell/Model/CountdownManager.swift
import ActivityKit
import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class CountdownManager {
    private static let bedtimeKey = "com.highland.SleepWell.activeBedtime"

    private(set) var isActive: Bool = false
    private(set) var targetBedtime: Date? = nil

    // Stored as String (activity.id) to avoid generic type issues in storage
    private var activityID: String? = nil

    init() {
        restore()
    }

    // MARK: - Public API

    func start(bedtime: Date) async {
        guard !isActive else { return }
        isActive = true
        targetBedtime = bedtime
        UserDefaults.appGroup.set(bedtime, forKey: Self.bedtimeKey)

        startLiveActivity(bedtime: bedtime)
        scheduleNotifications(bedtime: bedtime)
    }

    func cancel() async {
        await endActivity()
        clearState()
    }

    func handleForeground() async {
        guard isActive, let bedtime = targetBedtime else { return }
        let remaining = bedtime.timeIntervalSinceNow
        if remaining <= 0 {
            await endActivity()
            clearState()
        } else if remaining <= 3600 {
            await updateActivityToImminent()
        }
    }

    // MARK: - Testing entry point (skips ActivityKit, which can't run in unit tests)

    func startForTesting(bedtime: Date) async {
        guard !isActive else { return }
        isActive = true
        targetBedtime = bedtime
        UserDefaults.appGroup.set(bedtime, forKey: Self.bedtimeKey)
    }

    // MARK: - Private

    private func restore() {
        guard let stored = UserDefaults.appGroup.object(forKey: Self.bedtimeKey) as? Date,
              stored > Date()
        else {
            UserDefaults.appGroup.removeObject(forKey: Self.bedtimeKey)
            return
        }
        isActive = true
        targetBedtime = stored
        // Reconnect to existing live activity if still running
        if #available(iOS 16.2, *) {
            activityID = Activity<BedtimeCountdownAttributes>.activities.first?.id
        }
    }

    private func startLiveActivity(bedtime: Date) {
        guard #available(iOS 16.2, *) else { return }
        let attributes = BedtimeCountdownAttributes(targetBedtime: bedtime)
        let state = BedtimeCountdownAttributes.ContentState(phase: .active)
        let content = ActivityContent(state: state, staleDate: nil)
        let activity = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
        activityID = activity?.id
    }

    private func updateActivityToImminent() async {
        guard #available(iOS 16.2, *),
              let id = activityID,
              let activity = Activity<BedtimeCountdownAttributes>.activities.first(where: { $0.id == id })
        else { return }
        let newState = BedtimeCountdownAttributes.ContentState(phase: .imminent)
        let content = ActivityContent(state: newState, staleDate: nil)
        await activity.update(content)
    }

    private func endActivity() async {
        guard #available(iOS 16.2, *),
              let id = activityID,
              let activity = Activity<BedtimeCountdownAttributes>.activities.first(where: { $0.id == id })
        else { return }
        let finalState = BedtimeCountdownAttributes.ContentState(phase: .imminent)
        let content = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
    }

    private func clearState() {
        isActive = false
        targetBedtime = nil
        activityID = nil
        UserDefaults.appGroup.removeObject(forKey: Self.bedtimeKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["bedtime-3h", "bedtime-1h", "bedtime-now"]
        )
    }

    private func scheduleNotifications(bedtime: Date) {
        let center = UNUserNotificationCenter.current()
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        // Silent notification at T−3h
        let minus3h = bedtime.addingTimeInterval(-3 * 3600)
        if minus3h > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Bedtime approaching"
            content.body = "You have 3 hours until bedtime."
            // No sound — intentionally silent
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: minus3h
                ),
                repeats: false
            )
            center.add(
                UNNotificationRequest(identifier: "bedtime-3h", content: content, trigger: trigger)
            )
        }

        // Gentle notification at T−1h
        let minus1h = bedtime.addingTimeInterval(-3600)
        if minus1h > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Bedtime in 1 hour"
            content.body = "Your bedtime is in 1 hour — tap to open the countdown."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: minus1h
                ),
                repeats: false
            )
            center.add(
                UNNotificationRequest(identifier: "bedtime-1h", content: content, trigger: trigger)
            )
        }

        // Bedtime notification
        let content = UNMutableNotificationContent()
        content.title = "Time to sleep 🌙"
        content.body = "Goodnight!"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: bedtime
            ),
            repeats: false
        )
        center.add(
            UNNotificationRequest(identifier: "bedtime-now", content: content, trigger: trigger)
        )
    }
}
```

- [ ] **Step 4: Run tests — expect all pass**

`Cmd+U`. Expected: 5 tests pass in `CountdownManagerTests`.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/Model/CountdownManager.swift \
        SleepWell/SleepWellTests/CountdownManagerTests.swift
git commit -m "Add CountdownManager for Live Activity lifecycle and notification scheduling"
```

---

## Task 4: `BedtimeCountdownLiveActivity` — Dynamic Island + lock screen views

**Files:**
- Create: `SleepWell/SleepWellWidget/BedtimeCountdownLiveActivity.swift`
- Modify: `SleepWell/SleepWellWidget/SleepWellWidgetBundle.swift`

- [ ] **Step 1: Create the Live Activity widget**

```swift
// SleepWell/SleepWellWidget/BedtimeCountdownLiveActivity.swift
import ActivityKit
import SwiftUI
import WidgetKit

struct BedtimeCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BedtimeCountdownAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    expandedCenterView(context: context)
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.accent)
                    .font(.caption)
            } compactTrailing: {
                Text(shortTimeString(context.attributes.targetBedtime))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.accent)
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.accent)
                    .font(.caption2)
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<BedtimeCountdownAttributes>
    ) -> some View {
        switch context.state.phase {
        case .active:
            // Minimal thin bar — unobtrusive
            HStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.accent)
                    .font(.caption2)
                Text("Bedtime at \(shortTimeString(context.attributes.targetBedtime))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .activityBackgroundTint(Color.appBackground)

        case .imminent:
            // Full countdown
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color.accent)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        timerInterval: Date.now...context.attributes.targetBedtime,
                        countsDown: true
                    )
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                    Text("Bedtime at \(shortTimeString(context.attributes.targetBedtime))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(Color(hex: "1e1b4b"))
        }
    }

    // MARK: - Dynamic Island Expanded

    @ViewBuilder
    private func expandedCenterView(
        context: ActivityViewContext<BedtimeCountdownAttributes>
    ) -> some View {
        VStack(spacing: 2) {
            Text(
                timerInterval: Date.now...context.attributes.targetBedtime,
                countsDown: true
            )
            .font(.system(.title2, design: .rounded).weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.white)

            Text("until bedtime")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func shortTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}
```

- [ ] **Step 2: Add to `SleepWellWidgetBundle`**

Replace `SleepWell/SleepWellWidget/SleepWellWidgetBundle.swift`:

```swift
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SleepWellWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWellWidget()
        BedtimeCountdownLiveActivity()
    }
}
```

- [ ] **Step 3: Build the widget extension — confirm no errors**

In Xcode: select the `SleepWellWidgetExtension` scheme → `Cmd+B`. Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWellWidget/BedtimeCountdownLiveActivity.swift \
        SleepWell/SleepWellWidget/SleepWellWidgetBundle.swift
git commit -m "Add BedtimeCountdownLiveActivity widget with Dynamic Island and lock screen views"
```

---

## Task 5: `ManagerView` — Manager tab

**Files:**
- Create: `SleepWell/SleepWell/Views/ManagerView.swift`

- [ ] **Step 1: Create `ManagerView`**

```swift
// SleepWell/SleepWell/Views/ManagerView.swift
import AlarmKit
import SwiftUI

struct ManagerView: View {
    @Environment(CountdownManager.self) private var countdownManager
    @State private var alarmScheduler = AlarmScheduler()
    @State private var alarms: [ScheduledAlarm] = []
    @State private var showCancelAllConfirm = false
    @State private var resultMessage: String? = nil

    var body: some View {
        ZStack {
            backgroundView

            if alarms.isEmpty && !countdownManager.isActive {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if countdownManager.isActive {
                            remindersSection
                        }
                        if !alarms.isEmpty {
                            alarmsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Manager")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { alarms = alarmScheduler.store.all() }
        .alert(resultMessage ?? "", isPresented: .init(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Reminders")

            VStack(alignment: .leading, spacing: 6) {
                if let bedtime = countdownManager.targetBedtime {
                    Text(timerInterval: Date.now...bedtime, countsDown: true)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text("Bedtime at \(shortTimeString(bedtime))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Button {
                    Task { await countdownManager.cancel() }
                } label: {
                    Text("Cancel Reminder")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "c4b5fd"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "4c1d95").opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1e1b4b"), Color(hex: "312e81")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "4f46e5").opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Alarms")

            VStack(spacing: 0) {
                ForEach(alarms) { alarm in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortTimeString(alarm.date))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(alarm.label)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Button("Cancel") {
                            Task {
                                await alarmScheduler.cancel(id: alarm.id)
                                alarms = alarmScheduler.store.all()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.34))
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    if alarm.id != alarms.last?.id {
                        Divider().overlay(Color.white.opacity(0.08))
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

            if #available(iOS 26, *) {
                Button {
                    showCancelAllConfirm = true
                } label: {
                    Text("Cancel All Alarms")
                        .font(.body)
                        .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.34))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .confirmationDialog(
                    "Cancel all scheduled alarms?",
                    isPresented: $showCancelAllConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Cancel All", role: .destructive) {
                        Task {
                            await alarmScheduler.cancelAll()
                            alarms = alarmScheduler.store.all()
                            resultMessage = "All alarms cancelled"
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            Text("No alarms or timers")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.4))
            Text("Set an alarm or bedtime reminder\nfrom the Sleep tab.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(1.5)
            .padding(.horizontal, 4)
            .accessibilityHidden(true)
    }

    private func shortTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appBackgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.accent.opacity(0.12), .clear],
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
        ManagerView()
            .environment(CountdownManager())
    }
}
```

- [ ] **Step 2: Build — confirm no errors**

`Cmd+B`. Expected: builds successfully.

- [ ] **Step 3: Commit**

```bash
git add SleepWell/SleepWell/Views/ManagerView.swift
git commit -m "Add ManagerView with Reminders and Alarms sections"
```

---

## Task 6: `SleepWellApp` — TabView root

**Files:**
- Modify: `SleepWell/SleepWell/SleepWellApp.swift`

- [ ] **Step 1: Replace `SleepWellApp.swift`**

```swift
// SleepWell/SleepWell/SleepWellApp.swift
import SwiftUI

@main
struct SleepWellApp: App {
    @State private var viewModel = SleepViewModel()
    @State private var countdownManager = CountdownManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Sleep", systemImage: "house") {
                    NavigationStack {
                        WakeTimeInputView()
                            .navigationDestination(isPresented: $viewModel.showResults) {
                                BedtimeResultsView()
                            }
                    }
                }

                Tab("Manager", systemImage: "clock") {
                    NavigationStack {
                        ManagerView()
                    }
                }
            }
            .environment(viewModel)
            .environment(countdownManager)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                guard url.scheme == "sleepwell", url.host == "results" else { return }
                viewModel.calculateFromEffectiveSchedule()
            }
            .task {
                await countdownManager.handleForeground()
            }
        }
    }
}
```

- [ ] **Step 2: Build — confirm no errors**

`Cmd+B`. Expected: builds successfully.

- [ ] **Step 3: Run on simulator — verify tab bar appears**

`Cmd+R` on iPhone 16 Pro simulator. Confirm:
- Tab bar visible with house and clock icons
- Sleep tab shows existing `WakeTimeInputView`
- Manager tab shows `ManagerView` (empty state)

- [ ] **Step 4: Commit**

```bash
git add SleepWell/SleepWell/SleepWellApp.swift
git commit -m "Wrap root in TabView with Sleep and Manager tabs; inject CountdownManager"
```

---

## Task 7: `BedtimeResultsView` — bedtime reminder prompt

Add a second confirmation dialog that appears after setting an alarm in Wake Up mode.

**Files:**
- Modify: `SleepWell/SleepWell/Views/BedtimeResultsView.swift`

- [ ] **Step 1: Add `countdownManager` environment and state to `BedtimeResultsView`**

Add these properties at the top of the struct (after the existing `@State private var alarmResultMessage`):

```swift
@Environment(CountdownManager.self) private var countdownManager
@State private var reminderBedtime: Date? = nil
```

- [ ] **Step 2: Add reminder prompt after alarm set**

In the `"Set Alarm"` button action inside `.confirmationDialog`, replace:

```swift
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
```

with:

```swift
Button("Set Alarm") {
    guard let option = viewModel.selectedOption else { return }
    let alarmDate = option.bedtime
    viewModel.selectedOption = nil
    Task {
        let result = await alarmScheduler.schedule(at: alarmDate, label: viewModel.alarmLabel)
        switch result {
        case .scheduled:
            if viewModel.mode == .wakeUp {
                reminderBedtime = alarmDate
            } else {
                alarmResultMessage = "Alarm set"
            }
        case .denied:
            alarmResultMessage = "Alarm access denied — enable it in Settings"
        case .unsupportedOS:
            alarmResultMessage = "Setting alarms requires iOS 26 or later"
        case .failed:
            alarmResultMessage = "Could not set alarm"
        }
    }
}
```

- [ ] **Step 3: Add the reminder confirmation dialog**

Add a second `.confirmationDialog` modifier to the `ZStack` (after the existing `.confirmationDialog` and `.alert`):

```swift
.confirmationDialog(
    reminderBedtime.map { "Bedtime reminder for \(Self.timeFormatter.string(from: $0))?" } ?? "",
    isPresented: .init(
        get: { reminderBedtime != nil },
        set: { if !$0 { reminderBedtime = nil } }
    ),
    titleVisibility: .visible
) {
    Button("Remind Me") {
        guard let bedtime = reminderBedtime else { return }
        reminderBedtime = nil
        Task { await countdownManager.start(bedtime: bedtime) }
        alarmResultMessage = "Alarm set. Bedtime reminder active."
    }
    Button("Skip", role: .cancel) {
        reminderBedtime = nil
        alarmResultMessage = "Alarm set"
    }
}
```

- [ ] **Step 4: Build — confirm no errors**

`Cmd+B`. Expected: builds successfully.

- [ ] **Step 5: Run on simulator and test the flow**

`Cmd+R`. Go to Wake Up At → pick a wake time → calculate → tap a bedtime card → confirm "Set Alarm" → confirm the reminder prompt appears → tap "Remind Me" → verify success message shows.

- [ ] **Step 6: Commit**

```bash
git add SleepWell/SleepWell/Views/BedtimeResultsView.swift
git commit -m "Add bedtime reminder prompt after alarm is set in Wake Up mode"
```

---

## Task 8: `SettingsView` — remove Delete All Alarms

The "Delete All Alarms" button is now in `ManagerView`. Remove it from Settings.

**Files:**
- Modify: `SleepWell/SleepWell/Views/SettingsView.swift`

- [ ] **Step 1: Remove the `alarmsSection` property and its callsite**

In `SettingsView.swift`:

1. Delete the entire `private var alarmsSection: some View { ... }` computed property (lines 122–194 in the original file).

2. Delete the `@State private var showDeleteConfirm: Bool = false` property.

3. Delete the `@State private var deleteResultMessage: String? = nil` property.

4. Delete the `private func deleteAllAlarms() async { ... }` function.

5. In `body`, remove the line `alarmsSection` (the call between the PREFERENCES section and SCHEDULE section).

6. The ALARMS section is now settings-only: just the Alarm Name row. Keep the section label and the `alarmLabel` `TextField` row. Rewrite the ALARMS section inline as:

```swift
VStack(alignment: .leading, spacing: 6) {
    Text("ALARMS")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.4))
        .tracking(1.5)
        .padding(.horizontal, 28)
        .accessibilityHidden(true)

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
    .background {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
    }
    .padding(.horizontal, 24)
}
```

Place this block between the PREFERENCES section and the SCHEDULE section in `body`.

- [ ] **Step 2: Remove unused `import AlarmKit`**

Remove the `import AlarmKit` at the top of `SettingsView.swift` — it's no longer needed.

- [ ] **Step 3: Build — confirm no errors**

`Cmd+B`. Expected: builds successfully with no warnings about unused imports.

- [ ] **Step 4: Run all tests**

`Cmd+U`. Expected: all existing tests + new tests pass.

- [ ] **Step 5: Commit**

```bash
git add SleepWell/SleepWell/Views/SettingsView.swift
git commit -m "Remove Delete All Alarms from Settings — moved to Manager tab"
```

---

## Done Criteria

- [ ] Build succeeds with no errors or warnings
- [ ] All unit tests pass (`Cmd+U`)
- [ ] Tab bar visible on all screens with house / clock icons
- [ ] Wake Up mode: alarm confirmation → reminder prompt → "Remind Me" starts countdown
- [ ] Manager tab shows active reminder card and alarm list
- [ ] Manager tab shows empty state when nothing is scheduled
- [ ] Cancel Reminder ends the Live Activity and removes pending notifications
- [ ] Cancel individual alarm removes it from AlarmKit and `ScheduledAlarmStore`
- [ ] Cancel All Alarms works from Manager tab; removed from Settings
- [ ] Live Activity appears in Dynamic Island (test on physical device — simulator does not support Live Activities)
- [ ] Lock screen shows minimal bar in `.active` phase, full countdown in `.imminent` phase

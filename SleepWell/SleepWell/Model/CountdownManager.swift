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
        // No UserDefaults persistence — test entry point only, avoids cross-test state pollution
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

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SleepWellWidgetEntry: TimelineEntry {
    let date: Date
    let bedtimes: [BedtimeOption]
    let wakeTime: Date
}

// MARK: - Timeline Provider

struct SleepWellWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepWellWidgetEntry {
        makePlaceholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepWellWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepWellWidgetEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at next midnight so bedtimes recalculate for the new day
        let midnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    // MARK: - Helpers

    private func makeEntry() -> SleepWellWidgetEntry {
        let reader = WidgetScheduleReader()
        let now = Date()
        return SleepWellWidgetEntry(
            date: now,
            bedtimes: reader.bedtimes(for: now),
            wakeTime: reader.effectiveWakeTime(for: now)
        )
    }

    private func makePlaceholder() -> SleepWellWidgetEntry {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 7; c.minute = 0
        let wake = Calendar.current.date(from: c) ?? Date()
        return SleepWellWidgetEntry(
            date: Date(),
            bedtimes: SleepCalculator.calculate(wakeTime: wake, fallAsleepMinutes: 14),
            wakeTime: wake
        )
    }
}

// MARK: - Entry View (routes to size-specific views)

struct SleepWellWidgetEntryView: View {
    var entry: SleepWellWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "sleepwell://results")!)
    }
}

// MARK: - Widget Declaration

struct SleepWellWidget: Widget {
    let kind = "SleepWellWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepWellWidgetProvider()) { entry in
            SleepWellWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SleepWell")
        .description("Tonight's recommended bedtime.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

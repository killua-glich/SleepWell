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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private func shortTimeString(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: SleepWellWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Bedtime options · Wake \(timeString(entry.wakeTime)) \(ampmString(entry.wakeTime))")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.8)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            // Bedtime rows
            VStack(spacing: 0) {
                ForEach(entry.bedtimes) { option in
                    BedtimeRowView(option: option)
                    if option.id != entry.bedtimes.last?.id {
                        Divider()
                            .overlay(Color.white.opacity(0.07))
                    }
                }
            }

            Spacer()

            // Footer
            Text("Tap to open")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(0.8)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

// MARK: - Bedtime row subview

private struct BedtimeRowView: View {
    let option: BedtimeOption

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString(option.bedtime))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(option.totalSleepFormatted) · \(option.cycles) cycles")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                CycleDotsView(filled: option.cycles, total: 6)
                if option.isRecommended {
                    Text("Best")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.accent)
                        .tracking(0.7)
                        .textCase(.uppercase)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.accent.opacity(0.45), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, option.isRecommended ? 6 : 0)
        .background(
            option.isRecommended
                ? RoundedRectangle(cornerRadius: 8).fill(Color.accent.opacity(0.08))
                : nil
        )
    }
}

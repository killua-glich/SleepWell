import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: SleepWellWidgetEntry

    private var recommended: BedtimeOption? {
        entry.bedtimes.first(where: { $0.isRecommended })
    }

    var body: some View {
        HStack(alignment: .center) {
            // Left: recommended bedtime
            VStack(alignment: .leading, spacing: 4) {
                Text("Go to bed at")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(0.8)
                    .textCase(.uppercase)

                if let option = recommended {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(timeString(option.bedtime))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text(ampmString(option.bedtime))
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text("\(option.totalSleepFormatted) · \(option.cycles) cycles")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Recommended")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.accent)
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.accent.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.top, 4)
                }
            }

            Spacer()

            // Right: wake time + dots
            VStack(alignment: .trailing, spacing: 6) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Wake up")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("\(timeString(entry.wakeTime)) \(ampmString(entry.wakeTime))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                CycleDotsView(filled: 5, total: 5)
            }
        }
        .padding(.horizontal, 16)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

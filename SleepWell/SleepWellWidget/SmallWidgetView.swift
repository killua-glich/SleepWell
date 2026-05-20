import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: SleepWellWidgetEntry

    private var recommended: BedtimeOption? {
        entry.bedtimes.first(where: { $0.isRecommended })
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Top: label + time + duration
            VStack(alignment: .center, spacing: 2) {
                Text("Go to bed")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(0.8)
                    .textCase(.uppercase)

                if let option = recommended {
                    Text(timeString(option.bedtime))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)

                    Text("\(ampmString(option.bedtime)) · \(option.totalSleepFormatted)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            // Bottom: badge + dots (centered)
            VStack(alignment: .center, spacing: 8) {
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

                CycleDotsView(filled: 5, total: 5)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
}

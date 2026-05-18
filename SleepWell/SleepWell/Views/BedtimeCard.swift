import SwiftUI

struct BedtimeCard: View {
    let option: BedtimeOption
    let onTap: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: option.bedtime)
    }

    private var amPmString: String {
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

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                // Left: time + duration
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(amPmString)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text(option.totalSleepFormatted)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(option.isRecommended ? 0.6 : 0.4))
                }

                Spacer()

                // Right: cycle dots (hidden for nap options)
                if option.napLabel == nil {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(option.cycles) cycles")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
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
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule()
                                .stroke(Color.accent.opacity(0.8), lineWidth: 1.5)
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                } else if let label = option.napLabel {
                    Text(label.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                }
            }
        }
        .buttonStyle(.plain)
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

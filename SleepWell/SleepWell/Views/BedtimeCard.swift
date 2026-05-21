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

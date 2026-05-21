import SwiftUI

struct WakeTimeInputView: View {
    @Environment(SleepViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()
                    .frame(maxHeight: 40)

                VStack(spacing: 6) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 110)
                        .accessibilityHidden(true)

                    Text("SleepWell")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)
                        .accessibilityHidden(true)

                    Text("How can I help?")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(spacing: 16) {
                    Button {
                        viewModel.calculateSleepNow()
                    } label: {
                        modeCard(
                            title: "Sleep Now",
                            subtitle: "Show me the best times to wake up",
                            icon: "moon.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sleep Now")
                    .accessibilityHint("Shows the best times to wake up")

                    NavigationLink {
                        WakeTimePickerView()
                    } label: {
                        modeCard(
                            title: "Wake Up At…",
                            subtitle: "Tell me when to go to bed",
                            icon: "alarm"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Wake Up At")
                    .accessibilityHint("Tell me when to go to bed")

                    Button {
                        viewModel.calculateNapNow()
                    } label: {
                        modeCard(
                            title: "Take a Nap",
                            subtitle: "Power nap or full recovery",
                            icon: "bed.double.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Take a Nap")
                    .accessibilityHint("Power nap or full recovery")
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 60)
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    @ViewBuilder
    private func modeCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.accent)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .accessibilityHidden(true)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .accessibilityHidden(true)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appBackgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.accent.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 220
            )
            .frame(width: 360, height: 360)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        WakeTimeInputView()
            .environment(SleepViewModel())
    }
}

import SwiftUI

struct WakeTimeInputView: View {
    @Environment(SleepViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("SleepWell")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)

                    Text("How can I help?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
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
                }
                .padding(.horizontal, 24)

                Spacer()
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

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
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

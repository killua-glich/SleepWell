import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private let minuteRange = Array(5...60)

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Settings")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)

                    Text("How long to fall asleep?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                @Bindable var vm = viewModel
                Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                    ForEach(minuteRange, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

                Text("Used to calculate your ideal bedtime")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
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
                endRadius: 180
            )
            .frame(width: 300, height: 300)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(SleepViewModel())
    }
}

import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private let minuteRange = Array(5...60)

    var body: some View {
        ZStack {
            backgroundView

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 16)

                    VStack(spacing: 6) {
                        Text("Settings")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)
                    }

                    // MARK: - Fall asleep time
                    settingSection(label: "How long to fall asleep?", caption: "Used to calculate your ideal bedtime") {
                        @Bindable var vm = viewModel
                        Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                            ForEach(minuteRange, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .colorScheme(.dark)
                    }

                    // MARK: - Default wake-up time
                    settingSection(label: "Default wake-up time", caption: "Pre-fills the Wake Up At picker") {
                        DatePicker(
                            "",
                            selection: defaultWakeBinding(vm: viewModel),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                    }

                    Spacer().frame(height: 16)
                }
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // Converts the two AppStorage ints to a Binding<Date> for the DatePicker.
    // NOTE: defaultWakeHour and defaultWakeMinute are @ObservationIgnored, so SwiftUI's
    // observation machinery won't re-evaluate this binding's get-closure if those values
    // are mutated externally. On this settings screen that's fine — the picker is the
    // only writer.
    private func defaultWakeBinding(vm: SleepViewModel) -> Binding<Date> {
        Binding(
            get: { vm.defaultWakeDate },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                vm.defaultWakeHour = components.hour ?? 7
                vm.defaultWakeMinute = components.minute ?? 0
            }
        )
    }

    @ViewBuilder
    private func settingSection<Content: View>(
        label: String,
        caption: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            content()
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

            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
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

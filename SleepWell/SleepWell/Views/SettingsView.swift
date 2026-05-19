import SwiftUI

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private enum ExpandedSetting {
        case fallAsleep, wakeUp
    }

    @State private var expanded: ExpandedSetting? = nil
    @AppStorage("defaultWakeHour") private var defaultWakeHour: Int = 7
    @AppStorage("defaultWakeMinute") private var defaultWakeMinute: Int = 0
    private let minuteRange = Array(5...60)

    var body: some View {
        ZStack {
            backgroundView

            if expanded != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            expanded = nil
                        }
                    }
            }

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 6) {
                    Text("SleepWell")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)
                    Text("Personalize")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 0) {
                    fallAsleepRow
                    Divider().overlay(Color.white.opacity(0.08))
                    wakeUpRow
                }
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expanded)

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Fall asleep row

    private var fallAsleepRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .fallAsleep ? nil : .fallAsleep
            } label: {
                HStack {
                    Text("Fall asleep time")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(viewModel.fallAsleepMinutes) min")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .fallAsleep {
                @Bindable var vm = viewModel
                Picker("Fall asleep time", selection: $vm.fallAsleepMinutes) {
                    ForEach(minuteRange, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }

    // MARK: - Wake-up row

    private var wakeUpRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .wakeUp ? nil : .wakeUp
            } label: {
                HStack {
                    Text("Default wake-up")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(wakeTimeLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .wakeUp {
                DatePicker(
                    "",
                    selection: defaultWakeBinding(vm: viewModel),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 150)
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .clipped()
    }

    // MARK: - Helpers

    private var wakeTimeLabel: String {
        String(format: "%02d:%02d", defaultWakeHour, defaultWakeMinute)
    }

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

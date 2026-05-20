import SwiftUI
import AlarmKit

struct SettingsView: View {
    @Environment(SleepViewModel.self) private var viewModel

    private enum ExpandedSetting {
        case fallAsleep, wakeUp, weekday, weekend
    }

    @State private var expanded: ExpandedSetting? = nil
    @AppStorage("defaultWakeHour", store: .appGroup) private var defaultWakeHour: Int = 7
    @AppStorage("defaultWakeMinute", store: .appGroup) private var defaultWakeMinute: Int = 0
    private let minuteRange = Array(5...60)
    @AppStorage("scheduleEnabled", store: .appGroup) private var scheduleEnabled: Bool = false
    @AppStorage("weekdayWakeHour", store: .appGroup) private var weekdayWakeHour: Int = 7
    @AppStorage("weekdayWakeMinute", store: .appGroup) private var weekdayWakeMinute: Int = 0
    @AppStorage("weekendWakeHour", store: .appGroup) private var weekendWakeHour: Int = 8
    @AppStorage("weekendWakeMinute", store: .appGroup) private var weekendWakeMinute: Int = 0
    @AppStorage("alarmLabel", store: .appGroup) private var alarmLabel: String = "Wake Up"
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteResultMessage: String? = nil

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
                    Text("Settings")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("PREFERENCES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .padding(.horizontal, 28)

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
                } // end PREFERENCES VStack

                alarmsSection

                VStack(alignment: .leading, spacing: 6) {
                    Text("SCHEDULE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .padding(.horizontal, 28)

                    VStack(spacing: 0) {
                        scheduleToggleRow
                        if scheduleEnabled {
                            Divider().overlay(Color.white.opacity(0.08))
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            weekdayRow
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            Divider().overlay(Color.white.opacity(0.08))
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            weekendRow
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
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
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scheduleEnabled)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expanded)
                }

                Spacer()
            }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Alarms section

    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ALARMS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1.5)
                .padding(.horizontal, 28)

            VStack(spacing: 0) {
                // Alarm Name row
                HStack {
                    Text("Alarm Name")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    TextField("Wake Up", text: $alarmLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160)
                        .accessibilityLabel("Alarm Name")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Delete All Alarms button (iOS 26+ only)
                if #available(iOS 26, *) {
                    Divider().overlay(Color.white.opacity(0.08))

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Text("Delete All Alarms")
                                .font(.system(size: 15))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Delete all scheduled alarms?",
                        isPresented: $showDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Delete All", role: .destructive) {
                            Task { await deleteAllAlarms() }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
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
            .alert(deleteResultMessage ?? "", isPresented: .init(
                get: { deleteResultMessage != nil },
                set: { if !$0 { deleteResultMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            }
        }
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

    // MARK: - Schedule toggle row

    private var scheduleToggleRow: some View {
        HStack {
            Text("Wake-up schedule")
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: Binding(
                get: { scheduleEnabled },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        expanded = nil
                    }
                    scheduleEnabled = newValue
                }
            ))
            .labelsHidden()
            .tint(Color.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Weekday row

    private var weekdayRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .weekday ? nil : .weekday
            } label: {
                HStack {
                    Text("Weekdays")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekdayWakeHour, weekdayWakeMinute))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .weekday {
                DatePicker(
                    "",
                    selection: weekdayWakeBinding(),
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

    // MARK: - Weekend row

    private var weekendRow: some View {
        VStack(spacing: 0) {
            Button {
                expanded = expanded == .weekend ? nil : .weekend
            } label: {
                HStack {
                    Text("Weekend")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", weekendWakeHour, weekendWakeMinute))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded == .weekend {
                DatePicker(
                    "",
                    selection: weekendWakeBinding(),
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

    @available(iOS 26, *)
    private func deleteAllAlarms() async {
        let alarms = (try? AlarmManager.shared.alarms) ?? []
        for alarm in alarms {
            try? await AlarmManager.shared.cancel(id: alarm.id)
        }
        let count = alarms.count
        deleteResultMessage = count == 0
            ? "No alarms scheduled"
            : "Deleted \(count) alarm\(count == 1 ? "" : "s")"
    }

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

    private func weekdayWakeBinding() -> Binding<Date> {
        Binding(
            get: { SleepViewModel.makeWakeDate(hour: weekdayWakeHour, minute: weekdayWakeMinute) },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                weekdayWakeHour = components.hour ?? 7
                weekdayWakeMinute = components.minute ?? 0
            }
        )
    }

    private func weekendWakeBinding() -> Binding<Date> {
        Binding(
            get: { SleepViewModel.makeWakeDate(hour: weekendWakeHour, minute: weekendWakeMinute) },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                weekendWakeHour = components.hour ?? 8
                weekendWakeMinute = components.minute ?? 0
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

import SwiftUI

struct BedtimeResultsView: View {
    @Environment(SleepViewModel.self) private var viewModel
    @State private var alarmScheduler = AlarmScheduler()
    @State private var alarmResultMessage: String? = nil
    @Environment(CountdownManager.self) private var countdownManager
    @State private var reminderBedtime: Date? = nil

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private var headerEyebrow: String {
        switch viewModel.mode {
        case .wakeUp:
            return "WAKE UP AT \(Self.timeFormatter.string(from: viewModel.wakeTime).uppercased())"
        case .sleepNow:
            return "SLEEPING NOW"
        case .nap:
            return "NAPPING NOW"
        }
    }

    private var headerTitle: String {
        switch viewModel.mode {
        case .wakeUp: return "Go to bed at…"
        case .sleepNow: return "Wake up at…"
        case .nap: return "Wake up at…"
        }
    }

    private var accessibilityHeaderLabel: String {
        switch viewModel.mode {
        case .wakeUp:
            return "Wake up at \(Self.timeFormatter.string(from: viewModel.wakeTime)). \(headerTitle)"
        case .sleepNow:
            return "Sleeping now. \(headerTitle)"
        case .nap:
            return "Napping now. \(headerTitle)"
        }
    }

    private var showDialog: Binding<Bool> {
        Binding(
            get: { viewModel.selectedOption != nil },
            set: { if !$0 { viewModel.selectedOption = nil } }
        )
    }

    private var dialogTitle: String {
        guard let option = viewModel.selectedOption else { return "" }
        return "Set alarm for \(Self.timeFormatter.string(from: option.bedtime))?"
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(headerEyebrow)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.5)

                    Text(headerTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityHeaderLabel)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Cards
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.bedtimes) { option in
                            BedtimeCard(option: option) {
                                viewModel.selectedOption = option
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog(
            dialogTitle,
            isPresented: showDialog,
            titleVisibility: .visible
        ) {
            Button("Set Alarm") {
                guard let option = viewModel.selectedOption else { return }
                let alarmDate = option.bedtime
                viewModel.selectedOption = nil
                Task {
                    let result = await alarmScheduler.schedule(at: alarmDate, label: viewModel.alarmLabel)
                    switch result {
                    case .scheduled:
                        if viewModel.mode == .wakeUp {
                            reminderBedtime = alarmDate
                        } else {
                            alarmResultMessage = "Alarm set"
                        }
                    case .denied:
                        alarmResultMessage = "Alarm access denied — enable it in Settings"
                    case .unsupportedOS:
                        alarmResultMessage = "Setting alarms requires iOS 26 or later"
                    case .failed:
                        alarmResultMessage = "Could not set alarm"
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.selectedOption = nil
            }
        }
        .alert(alarmResultMessage ?? "", isPresented: .init(
            get: { alarmResultMessage != nil },
            set: { if !$0 { alarmResultMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
        .confirmationDialog(
            reminderBedtime.map { "Bedtime reminder for \(Self.timeFormatter.string(from: $0))?" } ?? "",
            isPresented: .init(
                get: { reminderBedtime != nil },
                set: { if !$0 { reminderBedtime = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remind Me") {
                guard let bedtime = reminderBedtime else { return }
                reminderBedtime = nil
                Task { await countdownManager.start(bedtime: bedtime) }
                alarmResultMessage = "Alarm set. Bedtime reminder active."
            }
            Button("Skip", role: .cancel) {
                reminderBedtime = nil
                alarmResultMessage = "Alarm set"
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appBackgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient glow
            RadialGradient(
                colors: [Color.accent.opacity(0.15), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 200
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        BedtimeResultsView()
            .environment({
                let vm = SleepViewModel()
                var c = DateComponents()
                c.hour = 8
                c.minute = 30
                vm.wakeTime = Calendar.current.date(from: c) ?? Date()
                vm.calculate()
                return vm
            }())
    }
}

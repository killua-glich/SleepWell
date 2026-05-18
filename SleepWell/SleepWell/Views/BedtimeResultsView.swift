import SwiftUI

struct BedtimeResultsView: View {
    @Environment(SleepViewModel.self) private var viewModel
    @Environment(\.openURL) private var openURL

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private var headerEyebrow: String {
        switch viewModel.mode {
        case .wakeUp:
            return "WAKE UP AT \(Self.timeFormatter.string(from: viewModel.wakeTime).uppercased())"
        case .sleepNow:
            return "SLEEPING NOW"
        }
    }

    private var headerTitle: String {
        switch viewModel.mode {
        case .wakeUp: return "Go to bed at…"
        case .sleepNow: return "Wake up at…"
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)

                    Text(headerTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
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
                if let url = URL(string: "clock-alarm://") {
                    openURL(url)
                }
                viewModel.selectedOption = nil
            }
            Button("Cancel", role: .cancel) {
                viewModel.selectedOption = nil
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

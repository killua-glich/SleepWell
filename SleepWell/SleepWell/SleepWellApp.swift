import SwiftUI

@main
struct SleepWellApp: App {
    @State private var viewModel = SleepViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WakeTimeInputView()
                    .navigationDestination(isPresented: $viewModel.showResults) {
                        BedtimeResultsView()
                    }
            }
            .environment(viewModel)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                guard url.scheme == "sleepwell", url.host == "results" else { return }
                viewModel.calculateFromEffectiveSchedule()
            }
        }
    }
}

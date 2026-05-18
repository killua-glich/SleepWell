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
        }
    }
}

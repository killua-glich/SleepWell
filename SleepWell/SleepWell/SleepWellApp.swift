// SleepWell/SleepWell/SleepWellApp.swift
import SwiftUI

@main
struct SleepWellApp: App {
    @State private var viewModel = SleepViewModel()
    @State private var countdownManager = CountdownManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Sleep", systemImage: "house") {
                    NavigationStack {
                        WakeTimeInputView()
                            .navigationDestination(isPresented: $viewModel.showResults) {
                                BedtimeResultsView()
                            }
                    }
                }

                Tab("Manager", systemImage: "clock") {
                    NavigationStack {
                        ManagerView()
                    }
                }
            }
            .environment(viewModel)
            .environment(countdownManager)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                guard url.scheme == "sleepwell", url.host == "results" else { return }
                viewModel.calculateFromEffectiveSchedule()
            }
            .task {
                await countdownManager.handleForeground()
            }
        }
    }
}

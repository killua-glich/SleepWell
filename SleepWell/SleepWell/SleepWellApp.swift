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
                guard url.scheme == "sleepwell" else { return }
                if url.host == "results" {
                    viewModel.calculateFromEffectiveSchedule()
                }
                #if DEBUG
                if url.host == "debug-countdown",
                   let minutes = Int(url.lastPathComponent), minutes > 0 {
                    let bedtime = Date().addingTimeInterval(TimeInterval(minutes * 60))
                    Task { await countdownManager.start(bedtime: bedtime) }
                }
                #endif
            }
            .task {
                await countdownManager.handleForeground()
            }
        }
    }
}

// SleepWell/SleepWell/Views/ManagerView.swift
import AlarmKit
import SwiftUI

struct ManagerView: View {
    @Environment(CountdownManager.self) private var countdownManager
    @State private var alarmScheduler = AlarmScheduler()
    @State private var alarms: [ScheduledAlarm] = []
    @State private var showCancelAllConfirm = false
    @State private var resultMessage: String? = nil

    var body: some View {
        ZStack {
            backgroundView

            if alarms.isEmpty && !countdownManager.isActive {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if countdownManager.isActive {
                            remindersSection
                        }
                        if !alarms.isEmpty {
                            alarmsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Manager")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            alarms = alarmScheduler.store.all()
            Task { await countdownManager.handleForeground() }
        }
        .alert(resultMessage ?? "", isPresented: .init(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Reminders")

            VStack(alignment: .leading, spacing: 6) {
                if let bedtime = countdownManager.targetBedtime {
                    if bedtime > Date.now {
                        Text(timerInterval: Date.now...bedtime, countsDown: true)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    } else {
                        Text("Now")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }

                    Text("Bedtime at \(shortTimeString(bedtime))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Button {
                    Task { await countdownManager.cancel() }
                } label: {
                    Text("Cancel Reminder")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "c4b5fd"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "4c1d95").opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1e1b4b"), Color(hex: "312e81")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "4f46e5").opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Alarms")

            VStack(spacing: 0) {
                ForEach(alarms) { alarm in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortTimeString(alarm.date))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(alarm.label)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Button("Cancel") {
                            Task {
                                await alarmScheduler.cancel(id: alarm.id)
                                alarms = alarmScheduler.store.all()
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.34))
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    if alarm.id != alarms.last?.id {
                        Divider().overlay(Color.white.opacity(0.08))
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

            if #available(iOS 26, *) {
                Button {
                    showCancelAllConfirm = true
                } label: {
                    Text("Cancel All Alarms")
                        .font(.body)
                        .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.34))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .confirmationDialog(
                    "Cancel all scheduled alarms?",
                    isPresented: $showCancelAllConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Cancel All", role: .destructive) {
                        Task {
                            await alarmScheduler.cancelAll()
                            alarms = alarmScheduler.store.all()
                            resultMessage = "All alarms cancelled"
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            Text("No alarms or timers")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.4))
            Text("Set an alarm or bedtime reminder\nfrom the Sleep tab.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(1.5)
            .padding(.horizontal, 4)
            .accessibilityHidden(true)
    }

    private func shortTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackground, Color.appBackgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.accent.opacity(0.12), .clear],
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
        ManagerView()
            .environment(CountdownManager())
    }
}

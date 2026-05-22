// SleepWell/SleepWell/Model/BedtimeCountdownAttributes.swift
import ActivityKit
import Foundation

enum CountdownPhase: String, Codable, Sendable {
    case active    // >1h remaining — minimal Dynamic Island presence
    case imminent  // ≤1h remaining — full lock screen countdown visible
}

struct BedtimeCountdownAttributes: ActivityAttributes {
    let targetBedtime: Date

    struct ContentState: Codable, Hashable, Sendable {
        var phase: CountdownPhase
    }
}

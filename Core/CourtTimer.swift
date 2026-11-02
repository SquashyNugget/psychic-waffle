import Foundation

/// A timer's complete, serializable state. Time is derived from wall-clock
/// timestamps rather than assuming the application stays in the foreground.
struct CourtTimer: Codable, Hashable, Identifiable {
    enum Mode: String, Codable, CaseIterable, Identifiable {
        case knockUp
        case stopwatch

        var id: Self { self }
        var label: String { self == .knockUp ? "Knock Up" : "Stopwatch" }
    }

    static let knockUpDuration: TimeInterval = 120

    let id: Int
    var mode: Mode = .knockUp
    var accumulated: TimeInterval = 0
    var startedAt: Date?
    var completedAt: Date?

    var isRunning: Bool { startedAt != nil }
    var isCompleted: Bool { completedAt != nil }

    func elapsed(at date: Date = .now) -> TimeInterval {
        accumulated + (startedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    func remaining(at date: Date = .now) -> TimeInterval {
        max(0, Self.knockUpDuration - elapsed(at: date))
    }

    /// True if this countdown has reached its deadline; the engine reconciles
    /// this state and resets it to zero the next time the app runs.
    func hasExpired(at date: Date = .now) -> Bool {
        mode == .knockUp && isRunning && elapsed(at: date) >= Self.knockUpDuration
    }

    var statusText: String {
        if isCompleted { return "Finished" }
        if isRunning { return "Running" }
        if accumulated > 0 { return "Paused" }
        return "Ready"
    }
}

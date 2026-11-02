import Foundation

/// Pure, testable operations. Never blocks or requires a background timer.
enum TimerEngine {
    static func initialCourts() -> [CourtTimer] {
        (1...4).map { CourtTimer(id: $0) }
    }

    static func setMode(_ mode: CourtTimer.Mode, for court: inout CourtTimer) {
        guard court.mode != mode else { return }
        court.mode = mode
        reset(&court)
    }

    static func reset(_ court: inout CourtTimer) {
        court.accumulated = 0
        court.startedAt = nil
        court.completedAt = nil
    }

    static func start(_ court: inout CourtTimer, now: Date = Date()) {
        guard !court.isRunning else { return }
        if court.isCompleted || (court.mode == .knockUp && court.accumulated >= CourtTimer.knockUpDuration) {
            reset(&court)
        }
        court.completedAt = nil
        court.startedAt = now
    }

    static func pause(_ court: inout CourtTimer, now: Date = Date()) {
        guard court.isRunning else { return }
        if court.hasExpired(at: now) {
            finish(&court, now: now)
            return
        }
        court.accumulated = court.elapsed(at: now)
        court.startedAt = nil
    }

    /// Returns true if a countdown was newly completed in this call.
    @discardableResult
    static func reconcile(_ court: inout CourtTimer, now: Date = Date()) -> Bool {
        guard court.hasExpired(at: now) else { return false }
        finish(&court, now: now)
        return true
    }

    private static func finish(_ court: inout CourtTimer, now: Date) {
        court.startedAt = nil
        court.accumulated = 0
        court.completedAt = now
    }

    static func clockString(for court: CourtTimer, now: Date = Date()) -> String {
        // Idle or completed Knock Up deliberately shows zero, as requested.
        let seconds: Int
        if court.mode == .knockUp {
            let remaining = court.isRunning || court.accumulated > 0
                ? court.remaining(at: now) : 0
            seconds = Int(ceil(remaining))
        } else {
            seconds = Int(floor(court.elapsed(at: now)))
        }
        if seconds >= 3600 {
            return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    static func knockUpProgress(_ court: CourtTimer, now: Date = Date()) -> Double {
        guard court.mode == .knockUp else { return 0 }
        guard court.isRunning || court.accumulated > 0 else { return 0 }
        return max(0, min(1, court.remaining(at: now) / CourtTimer.knockUpDuration))
    }
}

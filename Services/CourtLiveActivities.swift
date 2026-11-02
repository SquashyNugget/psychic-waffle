import ActivityKit
import Foundation

/// One combined Lock Screen Live Activity holds up to four running courts.
/// The widget's `Text(timerInterval:)` is system-rendered, so its digits
/// continue counting when the host app is suspended.
@MainActor
final class CourtLiveActivities {
    static let shared = CourtLiveActivities()
    private init() { }

    private var current: Activity<CourtActivityAttributes>?
    private(set) var lastError: String?

    func synchronize(_ courts: [CourtTimer], now: Date = .now) async {
        let active = courts.filter { $0.isRunning && !$0.hasExpired(at: now) }
        let live: [LiveCourt] = active.compactMap { court in
            guard let startedAt = court.startedAt else { return nil }
            if court.mode == .knockUp {
                let end = startedAt.addingTimeInterval(
                    CourtTimer.knockUpDuration - court.accumulated
                )
                return LiveCourt(id: court.id,
                                 kind: .knockUp,
                                 startDate: end.addingTimeInterval(-CourtTimer.knockUpDuration),
                                 endDate: end)
            }
            return LiveCourt(id: court.id,
                             kind: .stopwatch,
                             startDate: startedAt.addingTimeInterval(-court.accumulated),
                             endDate: nil)
        }

        // Always tidy up previously existing activities on next launch, including
        // ones left over if the application was terminated unexpectedly.
        let existing = Activity<CourtActivityAttributes>.activities
        if live.isEmpty {
            for activity in existing {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            current = nil
            lastError = nil
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            lastError = "Enable Live Activities in iPhone Settings (if available)."
            return
        }

        let newContent = ActivityContent(
            state: CourtActivityAttributes.ContentState(activeCourts: live),
            staleDate: nil
        )
        if let activity = current ?? existing.first {
            await activity.update(newContent)
            current = activity
            lastError = nil
            for extra in existing where extra.id != activity.id {
                await extra.end(nil, dismissalPolicy: .immediate)
            }
        } else {
            do {
                current = try Activity.request(
                    attributes: CourtActivityAttributes(),
                    content: newContent,
                    pushType: nil
                )
                lastError = nil
            } catch {
                lastError = error.localizedDescription
            }
        }
    }
}

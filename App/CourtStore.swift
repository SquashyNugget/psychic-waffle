import Foundation
import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class CourtStore: ObservableObject {
    @Published private(set) var courts: [CourtTimer]
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var selectedCourtID: Int?
    @Published private(set) var liveActivityError: String?

    private let persistence = CourtPersistence()
    private let notifications = CourtNotifications.shared
    private let liveActivities = CourtLiveActivities.shared
    private var backgroundSyncTask: Task<Void, Never>?

    init() {
        courts = persistence.load()
        reconcile(performSideEffects: false)
    }

    var hasRunningCourts: Bool { courts.contains(where: \.isRunning) }

    func court(_ id: Int) -> CourtTimer? { courts.first { $0.id == id } }

    func activate() async {
        notificationStatus = await notifications.permissionStatus()
        // If a timer was running when the app was force-quit, re-schedule any
        // outstanding alerts and update its Lock Screen state on reopening.
        reconcile(performSideEffects: false)
        for court in courts {
            await notifications.reschedule(for: court)
        }
        await synchronizeLiveActivity()
    }

    func askForNotifications() async {
        _ = await notifications.requestPermission()
        notificationStatus = await notifications.permissionStatus()
    }

    func refreshNotificationStatus() async {
        notificationStatus = await notifications.permissionStatus()
    }

    func startOrPause(_ id: Int) {
        guard let index = courts.firstIndex(where: { $0.id == id }) else { return }
        let now = Date.now
        if courts[index].hasExpired(at: now) {
            TimerEngine.reconcile(&courts[index], now: now)
            // Preserve the pending OS alert: its delivery may be slightly late.
            persistence.save(courts)
            Task { await synchronizeLiveActivity() }
            return
        } else if courts[index].isRunning {
            TimerEngine.pause(&courts[index], now: now)
        } else {
            TimerEngine.start(&courts[index], now: now)
        }
        commit(changedCourts: [id])
    }

    func reset(_ id: Int) {
        guard let index = courts.firstIndex(where: { $0.id == id }) else { return }
        TimerEngine.reset(&courts[index])
        commit(changedCourts: [id])
    }

    func switchMode(_ id: Int, to mode: CourtTimer.Mode) {
        guard let index = courts.firstIndex(where: { $0.id == id }) else { return }
        guard courts[index].mode != mode else { return }
        TimerEngine.setMode(mode, for: &courts[index])
        commit(changedCourts: [id])
    }

    func startAllKnockUps() {
        let now = Date.now
        var ids: [Int] = []
        for index in courts.indices {
            if courts[index].mode == .knockUp && !courts[index].isRunning {
                TimerEngine.start(&courts[index], now: now)
                ids.append(courts[index].id)
            }
        }
        if !ids.isEmpty { commit(changedCourts: ids) }
    }

    func pauseAll() {
        let now = Date.now
        var ids: [Int] = []
        for index in courts.indices where courts[index].isRunning {
            TimerEngine.pause(&courts[index], now: now)
            ids.append(courts[index].id)
        }
        if !ids.isEmpty { commit(changedCourts: ids) }
    }

    func resetAll() {
        for index in courts.indices {
            TimerEngine.reset(&courts[index])
        }
        commit(changedCourts: courts.map(\.id))
    }

    /// Called by a foreground UI ticker. Never needed for clock accuracy;
    /// it simply reconciles expired states and updates Live Activities.
    func tick(now: Date = .now) {
        reconcile(now: now, performSideEffects: true)
    }

    private func reconcile(now: Date = .now, performSideEffects: Bool) {
        var finished: [Int] = []
        for index in courts.indices {
            if TimerEngine.reconcile(&courts[index], now: now) {
                finished.append(courts[index].id)
            }
        }
        guard !finished.isEmpty else { return }
        persistence.save(courts)
        if performSideEffects {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Do NOT cancel an expiring scheduled local notification here.
            // iOS might not have presented it yet, even though our timer
            // already reached 00:00. Only explicit pause/reset cancels it.
            Task { await synchronizeLiveActivity() }
        }
    }

    private func commit(changedCourts ids: [Int]) {
        persistence.save(courts)
        // Queue state changes in order. Rapid pause/resume taps must not leave
        // an older notification scheduled after the user's latest action.
        let previous = backgroundSyncTask
        let snapshot = courts
        backgroundSyncTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            for id in ids {
                if let court = snapshot.first(where: { $0.id == id }) {
                    await self.notifications.reschedule(for: court)
                }
            }
            await self.synchronizeLiveActivity()
        }
    }

    func synchronizeLiveActivity() async {
        await liveActivities.synchronize(courts)
        liveActivityError = liveActivities.lastError
    }
}

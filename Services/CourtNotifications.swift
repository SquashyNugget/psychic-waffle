import Foundation
import UIKit
import UserNotifications

/// Local notifications are delivered by iOS itself, even when this app is
/// suspended or the phone is locked. No server or network is required.
final class CourtNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = CourtNotifications()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func permissionStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func identifier(for courtID: Int) -> String { "knock-up-court-\(courtID)" }

    func cancel(courtID: Int) {
        let identifier = identifier(for: courtID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        // Do not erase an already-delivered notification; players may need it.
    }

    func reschedule(for court: CourtTimer, now: Date = .now) async {
        cancel(courtID: court.id)
        guard court.mode == .knockUp, court.isRunning else { return }
        let seconds = court.remaining(at: now)
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Court \(court.id) — Knock Up Finished"
        content.body = "Two minutes complete. Court \(court.id) is ready to play."
        content.sound = .default
        content.threadIdentifier = "badminton-courts"
        content.userInfo = ["courtID": court.id]

        let request = UNNotificationRequest(
            identifier: identifier(for: court.id),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, seconds), repeats: false
            )
        )
        do {
            try await center.add(request)
        } catch {
            print("Couldn't schedule Court \(court.id) notification: \(error)")
        }
    }

    func scheduleTestAlert() async {
        let content = UNMutableNotificationContent()
        content.title = "Court Timer — Test Alert"
        content.body = "If you can see this, court notifications are configured."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "badminton-test-alert",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try? await center.add(request)
    }

    /// While the app is open, still allow the user to see and hear the alert.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["courtID"] as? Int {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .courtNotificationOpened, object: id)
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let courtNotificationOpened = Notification.Name("courtNotificationOpened")
}

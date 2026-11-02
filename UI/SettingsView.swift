import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: CourtStore
    @Environment(\.dismiss) private var dismiss
    @State private var testResult: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Alerts") {
                    HStack {
                        Label("Notifications", systemImage: "bell.badge")
                        Spacer()
                        Text(permissionLabel)
                            .foregroundStyle(.secondary)
                    }
                    if store.notificationStatus == .notDetermined {
                        Button("Enable Court Notifications") {
                            Task { await store.askForNotifications() }
                        }
                    } else if store.notificationStatus == .denied {
                        Button("Open iPhone Notification Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                    } else {
                        Button("Send Test Alert in 5 Seconds") {
                            Task {
                                await CourtNotifications.shared.scheduleTestAlert()
                                testResult = "Test alert scheduled for five seconds from now. Lock your iPhone to test."
                            }
                        }
                    }
                    if let testResult {
                        Text(testResult)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Lock Screen") {
                    Label("One Live Activity shows running courts.", systemImage: "circle.dotted.circle")
                    Text("The circular countdown text updates using iOS. The ring itself may not smoothly animate while the phone is locked.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("When a Knock Up finishes, its Live Activity entry is removed as soon as iOS next lets the app update it. Immediate background removal cannot be guaranteed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("How Knock Up works") {
                    Text("Tap Knock Up on any court to count down from 02:00. At the deadline, iOS sends a notification with the court number and normal notification sound. When the app runs, that court automatically returns to 00:00. Standard Stopwatch mode has no deadline.")
                        .font(.footnote)
                    Text("Vibration depends on your iPhone's sound, haptics, Focus and notification settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await store.refreshNotificationStatus() }
        }
    }

    private var permissionLabel: String {
        switch store.notificationStatus {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Blocked"
        case .notDetermined: return "Not enabled"
        @unknown default: return "Unknown"
        }
    }
}

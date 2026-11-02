import SwiftUI

@main
struct CourtManagerApp: App {
    @StateObject private var store = CourtStore()

    init() {
        // Set the delegate before any local notifications are delivered.
        _ = CourtNotifications.shared
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
                .task { await store.activate() }
        }
    }
}

import SwiftUI
import UserNotifications

struct DashboardView: View {
    @EnvironmentObject private var store: CourtStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now
    @State private var showSettings = false
    @State private var showResetConfirmation = false

    private var grid: [GridItem] {
        let number = sizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: number)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        LazyVGrid(columns: grid, spacing: 12) {
                            ForEach(store.courts) { court in
                                CourtCardView(court: court, now: now,
                                              highlighted: store.selectedCourtID == court.id)
                                    .id(court.id)
                            }
                        }
                        quickActions
                        if store.notificationStatus != .authorized &&
                            store.notificationStatus != .provisional &&
                            store.notificationStatus != .ephemeral {
                            notificationHint
                        }
                        if let error = store.liveActivityError {
                            Label(error, systemImage: "info.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text("Knock Up: 2 minutes • Local alerts • Works offline")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                    .frame(maxWidth: 1040)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .onReceive(NotificationCenter.default.publisher(for: .courtNotificationOpened)) { note in
                    guard let id = note.object as? Int else { return }
                    store.selectedCourtID = id
                    withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
            .confirmationDialog("Reset every court?", isPresented: $showResetConfirmation) {
                Button("Reset All Four", role: .destructive) { store.resetAll() }
            } message: {
                Text("All knock-up countdowns and stopwatches will return to zero.")
            }
            .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { date in
                now = date
                store.tick(now: date)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    now = .now
                    Task { await store.activate() }
                }
            }
        }
        .tint(.mint)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "figure.badminton")
                        .foregroundStyle(.mint)
                    Text("BADMINTON")
                        .tracking(2)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)

                Text("Court Manager")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text("Keep every court on time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Open settings and notification controls")
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK ACTIONS")
                .font(.caption.bold())
                .tracking(1.2)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button { store.startAllKnockUps() } label: {
                    Label("Knock Up All", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 39)
                }
                .buttonStyle(.borderedProminent)

                Button { store.pauseAll() } label: {
                    Label("Pause All", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, minHeight: 39)
                }
                .buttonStyle(.bordered)
            }
            Button(role: .destructive) { showResetConfirmation = true } label: {
                Label("Reset All Courts", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(.bordered)
        }
        .padding(15)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 19))
    }

    private var notificationHint: some View {
        Button {
            showSettings = true
        } label: {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable finish notifications")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("Get a court-specific sound and notification when Knock Up reaches two minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(15)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

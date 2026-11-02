import SwiftUI

struct CourtCardView: View {
    let court: CourtTimer
    let now: Date
    let highlighted: Bool
    @EnvironmentObject private var store: CourtStore

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.badminton")
                        .foregroundStyle(.mint)
                    Text("COURT \(court.id)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(court.isRunning ? Color.mint : Color.secondary.opacity(0.35))
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)
            }

            Picker("Court \(court.id) timer mode", selection: Binding(
                get: { court.mode },
                set: { store.switchMode(court.id, to: $0) }
            )) {
                ForEach(CourtTimer.Mode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityHint("Changing mode resets the selected court timer.")

            TimerRing(court: court, now: now)
                .padding(.vertical, 2)

            VStack(spacing: 8) {
                Button {
                    store.startOrPause(court.id)
                } label: {
                    Label(primaryTitle, systemImage: court.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 39)
                }
                .buttonStyle(.borderedProminent)
                .tint(court.isRunning ? .orange : .mint)
                .accessibilityLabel("\(primaryTitle) Court \(court.id)")

                Button {
                    store.reset(court.id)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 35)
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .accessibilityLabel("Reset Court \(court.id)")
            }

            Text(court.mode == .knockUp ? "2-minute warm-up" : "Free-running stopwatch")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(highlighted ? Color.mint : Color.primary.opacity(0.04),
                        lineWidth: highlighted ? 2 : 1)
        }
    }

    private var primaryTitle: String {
        if court.isRunning { return "Pause" }
        if court.accumulated > 0 { return "Resume" }
        return court.mode == .knockUp ? "Knock Up" : "Start"
    }
}

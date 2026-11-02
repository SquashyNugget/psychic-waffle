import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen: circular countdown for each active court.
/// iOS renders Text(timerInterval:) as a live countdown while the app sleeps.
/// The decorative ring cannot be guaranteed to animate every second.
struct CourtLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourtActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.badminton")
                        .foregroundStyle(.mint)
                    Text("BADMINTON COURTS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1)
                    Spacer()
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.mint)
                }
                HStack(alignment: .center, spacing: 9) {
                    ForEach(context.state.activeCourts) { court in
                        courtCircle(court, diameter: 66)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.06, green: 0.10, blue: 0.13))
            .activitySystemActionForegroundColor(.mint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Courts", systemImage: "figure.badminton")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 8) {
                        ForEach(context.state.activeCourts) { court in
                            courtCircle(court, diameter: 59)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Knock Up • Stopwatch")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "figure.badminton")
                    .foregroundStyle(.mint)
            } compactTrailing: {
                if let court = priorityCourt(context.state.activeCourts) {
                    countdownText(court)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 49)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.mint)
            }
        }
    }

    private func priorityCourt(_ courts: [LiveCourt]) -> LiveCourt? {
        courts.sorted { first, second in
            switch (first.endDate, second.endDate) {
            case let (a?, b?): return a < b
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return first.id < second.id
            }
        }.first
    }

    private func courtCircle(_ court: LiveCourt, diameter: CGFloat) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: court.kind == .knockUp ? 1 : 0.32)
                    .stroke(court.kind == .knockUp ? Color.mint : Color.cyan,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("C\(court.id)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    countdownText(court)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.52)
                        .lineLimit(1)
                        .frame(width: diameter - 9)
                }
            }
            .frame(width: diameter, height: diameter)
            Text(court.kind == .knockUp ? "Knock Up" : "Stopwatch")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func countdownText(_ court: LiveCourt) -> some View {
        if let end = court.endDate {
            Text(timerInterval: court.startDate...end,
                 pauseTime: end,
                 countsDown: true,
                 showsHours: false)
        } else {
            Text(court.startDate, style: .timer)
        }
    }
}

@main
struct CourtWidgets: WidgetBundle {
    var body: some Widget {
        CourtLiveActivityWidget()
    }
}

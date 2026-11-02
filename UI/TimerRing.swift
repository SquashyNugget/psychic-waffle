import SwiftUI

struct TimerRing: View {
    let court: CourtTimer
    let now: Date
    var diameter: CGFloat = 114

    private var accent: Color {
        court.mode == .knockUp ? .mint : .cyan
    }

    private var ringProgress: Double {
        if court.mode == .knockUp {
            return TimerEngine.knockUpProgress(court, now: now)
        }
        // A stopwatch has no endpoint, so the ring is purely a visual cue.
        return court.isRunning ? 1 : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.09), lineWidth: 9)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.22), value: ringProgress)
            VStack(spacing: 3) {
                Text(TimerEngine.clockString(for: court, now: now))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(court.statusText)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(court.isCompleted ? Color.green : Color.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Court \(court.id), \(court.statusText), \(TimerEngine.clockString(for: court, now: now))")
    }
}

import XCTest
@testable import BadmintonTimerLogic

final class TimerEngineTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    func testFourIndependentCourts() {
        var courts = TimerEngine.initialCourts()
        XCTAssertEqual(courts.map(\.id), [1, 2, 3, 4])
        TimerEngine.start(&courts[0], now: base)
        XCTAssertTrue(courts[0].isRunning)
        XCTAssertFalse(courts[1].isRunning)
    }

    func testCountdownFinishesAndResetsToZero() {
        var court = CourtTimer(id: 1)
        TimerEngine.start(&court, now: base)
        XCTAssertEqual(court.remaining(at: base.addingTimeInterval(50)), 70, accuracy: 0.01)
        XCTAssertFalse(TimerEngine.reconcile(&court, now: base.addingTimeInterval(119)))
        XCTAssertTrue(TimerEngine.reconcile(&court, now: base.addingTimeInterval(121)))
        XCTAssertTrue(court.isCompleted)
        XCTAssertFalse(court.isRunning)
        XCTAssertEqual(court.accumulated, 0)
        XCTAssertEqual(TimerEngine.clockString(for: court), "00:00")
    }

    func testPauseAndResumePreservesRemainingTime() {
        var court = CourtTimer(id: 2)
        TimerEngine.start(&court, now: base)
        TimerEngine.pause(&court, now: base.addingTimeInterval(34))
        XCTAssertEqual(court.remaining(at: base.addingTimeInterval(999)), 86, accuracy: 0.001)
        TimerEngine.start(&court, now: base.addingTimeInterval(1000))
        XCTAssertEqual(court.remaining(at: base.addingTimeInterval(1020)), 66, accuracy: 0.001)
    }

    func testStopwatchNeverAutomaticallyExpires() {
        var court = CourtTimer(id: 3)
        TimerEngine.setMode(.stopwatch, for: &court)
        TimerEngine.start(&court, now: base)
        XCTAssertFalse(TimerEngine.reconcile(&court, now: base.addingTimeInterval(9999)))
        XCTAssertEqual(court.elapsed(at: base.addingTimeInterval(9999)), 9999, accuracy: 0.01)
    }

    func testChangingModesStopsAndResets() {
        var court = CourtTimer(id: 4)
        TimerEngine.start(&court, now: base)
        TimerEngine.setMode(.stopwatch, for: &court)
        XCTAssertFalse(court.isRunning)
        XCTAssertEqual(court.accumulated, 0)
        XCTAssertEqual(court.mode, .stopwatch)
    }

    func testDoubleStartDoesNotChangeStartTime() {
        var court = CourtTimer(id: 1)
        TimerEngine.start(&court, now: base)
        TimerEngine.start(&court, now: base.addingTimeInterval(15))
        XCTAssertEqual(court.startedAt, base)
    }

    func testPersistsDateBasedTimerState() throws {
        var court = CourtTimer(id: 1)
        TimerEngine.start(&court, now: base)
        let data = try JSONEncoder().encode(court)
        let restored = try JSONDecoder().decode(CourtTimer.self, from: data)
        XCTAssertEqual(restored.remaining(at: base.addingTimeInterval(90)), 30, accuracy: 0.01)
    }
}

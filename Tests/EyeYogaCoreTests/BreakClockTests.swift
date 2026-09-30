import Foundation
import Testing
@testable import EyeYogaCore

private let t0 = Date(timeIntervalSince1970: 1_000_000)

@Suite struct BreakClockTests {
    private func clock(micro: TimeInterval = 20 * 60, full: TimeInterval = 60 * 60,
                       idle: TimeInterval = 5 * 60) -> BreakClock {
        BreakClock(microInterval: micro, fullInterval: full, idleResetThreshold: idle, now: t0)
    }

    @Test func dueOnlyAfterMicroInterval() {
        var clock = clock()
        #expect(clock.tick(now: t0.addingTimeInterval(19 * 60), idleSeconds: 0) == .none)
        #expect(clock.tick(now: t0.addingTimeInterval(20 * 60), idleSeconds: 0) == .due(.micro))
    }

    @Test func fullRoutineReplacesEveryThirdMicroBreak() {
        var clock = clock()
        var now = t0
        var kinds: [BreakKind] = []
        for _ in 0..<6 {
            now = clock.nextDue
            guard case .due(let kind) = clock.tick(now: now, idleSeconds: 0) else {
                Issue.record("break not due at nextDue")
                return
            }
            kinds.append(kind)
            clock.completeBreak(kind, now: now)
        }
        #expect(kinds == [.micro, .micro, .full, .micro, .micro, .full])
        #expect(now == t0.addingTimeInterval(6 * 20 * 60))
    }

    @Test func breaksPerFullRoundsTheRatio() {
        #expect(clock(micro: 30 * 60, full: 45 * 60).breaksPerFull == 2)
        #expect(clock(micro: 15 * 60, full: 90 * 60).breaksPerFull == 6)
        #expect(clock(micro: 30 * 60, full: 15 * 60).breaksPerFull == 1)
        #expect(clock(micro: 30 * 60, full: 15 * 60).upcomingKind == .full)
    }

    @Test func snoozeKeepsTheSameBreak() {
        var clock = clock()
        clock.completeBreak(.micro, now: t0)
        clock.completeBreak(.micro, now: t0)
        #expect(clock.upcomingKind == .full)
        clock.snooze(now: t0, for: 5 * 60)
        #expect(clock.remaining(now: t0) == 5 * 60)
        #expect(clock.tick(now: t0.addingTimeInterval(5 * 60), idleSeconds: 0) == .due(.full))
        #expect(clock.microInterval == 20 * 60)
    }

    @Test func skippedFullRoutineStillResetsTheCycle() {
        var clock = clock()
        clock.completeBreak(.full, now: t0)
        #expect(clock.upcomingKind == .micro)
        #expect(clock.breaksSinceFull == 0)
    }

    @Test func idleAtThresholdRestartsCountdown() {
        var clock = clock(micro: 60, full: 180, idle: 20)
        let later = t0.addingTimeInterval(59)
        #expect(clock.tick(now: later, idleSeconds: 19.9) == .none)
        #expect(clock.tick(now: later, idleSeconds: 20) == .idleReset)
        #expect(clock.nextDue == later.addingTimeInterval(60))
    }

    @Test func idleWinsOverDue() {
        var clock = clock(micro: 60, full: 180, idle: 20)
        #expect(clock.tick(now: t0.addingTimeInterval(120), idleSeconds: 30) == .idleReset)
    }

    @Test func changingIntervalsRestarts() {
        var clock = clock()
        let later = t0.addingTimeInterval(600)
        clock.setIntervals(micro: 15 * 60, full: 45 * 60, now: later)
        #expect(clock.nextDue == later.addingTimeInterval(15 * 60))
        #expect(clock.breaksPerFull == 3)
    }

    @Test func remainingNeverNegative() {
        let clock = clock(micro: 10, full: 30)
        #expect(clock.remaining(now: t0.addingTimeInterval(99)) == 0)
    }

    @Test(arguments: [
        (1082.0, "18:02"), (1081.2, "18:02"), (0.0, "00:00"), (-3.0, "00:00"), (59.5, "01:00"), (5400.0, "90:00"),
    ])
    func countdownFormat(seconds: Double, expected: String) {
        #expect(formatCountdown(seconds) == expected)
    }
}

@Suite struct LaunchOptionsTests {
    @Test func separateAndInlineValues() {
        #expect(LaunchOptions.parse(["--interval-seconds", "30", "--idle-seconds=12"])
            == LaunchOptions(intervalSeconds: 30, idleSeconds: 12))
    }

    @Test func clampsToMinimum() {
        #expect(LaunchOptions.parse(["--interval-seconds", "1"]).intervalSeconds == 5)
    }

    @Test func ignoresGarbageAndMissingValues() {
        #expect(LaunchOptions.parse(["--interval-seconds", "abc", "-NSFoo", "YES"]) == LaunchOptions())
        #expect(LaunchOptions.parse(["--interval-seconds", "--idle-seconds", "9"])
            == LaunchOptions(idleSeconds: 9))
    }
}

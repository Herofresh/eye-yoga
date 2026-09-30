import Foundation

public enum BreakKind: Sendable, Equatable {
    case micro, full
}

/// Decides when the next break is due and which kind it is. Time and idle are injected so it stays testable.
public struct BreakClock: Sendable, Equatable {
    public enum Event: Sendable, Equatable { case none, due(BreakKind), idleReset }

    public private(set) var microInterval: TimeInterval
    public private(set) var fullInterval: TimeInterval
    public var idleResetThreshold: TimeInterval
    public private(set) var nextDue: Date
    public private(set) var breaksSinceFull = 0

    public init(microInterval: TimeInterval, fullInterval: TimeInterval,
                idleResetThreshold: TimeInterval = 5 * 60, now: Date) {
        self.microInterval = microInterval
        self.fullInterval = fullInterval
        self.idleResetThreshold = idleResetThreshold
        self.nextDue = now.addingTimeInterval(microInterval)
    }

    /// The full routine takes the slot of every Nth micro break, e.g. every 3rd for 20/60 min.
    public var breaksPerFull: Int { max(1, Int((fullInterval / microInterval).rounded())) }

    public var upcomingKind: BreakKind { breaksSinceFull + 1 >= breaksPerFull ? .full : .micro }

    /// Being away from the keyboard long enough counts as a rest, so the countdown restarts.
    public mutating func tick(now: Date, idleSeconds: TimeInterval) -> Event {
        if idleSeconds >= idleResetThreshold {
            restart(now: now)
            return .idleReset
        }
        return now >= nextDue ? .due(upcomingKind) : .none
    }

    /// Done or skipped: both move the schedule on to the next slot.
    public mutating func completeBreak(_ kind: BreakKind, now: Date) {
        breaksSinceFull = kind == .full ? 0 : breaksSinceFull + 1
        restart(now: now)
    }

    public mutating func restart(now: Date) {
        nextDue = now.addingTimeInterval(microInterval)
    }

    public mutating func snooze(now: Date, for duration: TimeInterval) {
        nextDue = now.addingTimeInterval(duration)
    }

    public mutating func setIntervals(micro: TimeInterval, full: TimeInterval, now: Date) {
        microInterval = micro
        fullInterval = full
        restart(now: now)
    }

    public func remaining(now: Date) -> TimeInterval {
        max(0, nextDue.timeIntervalSince(now))
    }
}

/// "18:02" for the menu bar; rounds up so it never shows 00:00 while time is left.
public func formatCountdown(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded(.up)))
    return String(format: "%02d:%02d", total / 60, total % 60)
}

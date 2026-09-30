import AppKit
import EyeYogaCore

/// Drives BreakClock from a 1 s timer, real idle time and sleep/lock notifications.
@MainActor
final class Scheduler {
    var onDue: ((BreakKind) -> Void)?
    var onTick: (() -> Void)?

    private(set) var clock: BreakClock
    private(set) var isPaused = false
    private var isHeld = false
    private var isLocked = false
    private var isAsleep = false
    private var timer: Timer?

    init(microInterval: TimeInterval, fullInterval: TimeInterval, idleResetThreshold: TimeInterval) {
        clock = BreakClock(microInterval: microInterval, fullInterval: fullInterval,
                           idleResetThreshold: idleResetThreshold, now: Date())
    }

    func start() {
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated { self.tick() }
        }
        timer.tolerance = 0.2
        // .common keeps it running while the status menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { self.isAsleep = true }
            }
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated {
                    self.isAsleep = false
                    self.resetCountdown()
                }
            }
        }
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { self.isLocked = true }
        }
        dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                self.isLocked = false
                self.resetCountdown()
            }
        }
    }

    var remaining: TimeInterval { clock.remaining(now: Date()) }
    var upcomingKind: BreakKind { clock.upcomingKind }

    /// Stops the countdown while the pop-up is on screen.
    func hold() { isHeld = true }

    func complete(_ kind: BreakKind) {
        isHeld = false
        clock.completeBreak(kind, now: Date())
        onTick?()
    }

    func snooze() {
        isHeld = false
        clock.snooze(now: Date(), for: Settings.snoozeSeconds)
        onTick?()
    }

    func setIntervals(micro: TimeInterval, full: TimeInterval) {
        clock.setIntervals(micro: micro, full: full, now: Date())
        onTick?()
    }

    func togglePause() {
        isPaused.toggle()
        if !isPaused { resetCountdown() } else { onTick?() }
    }

    private func resetCountdown() {
        clock.restart(now: Date())
        onTick?()
    }

    private func tick() {
        guard !isPaused, !isHeld, !isLocked, !isAsleep else { return }
        if case .due(let kind) = clock.tick(now: Date(), idleSeconds: Self.idleSeconds()) {
            isHeld = true
            onDue?(kind)
        }
        onTick?()
    }

    private static func idleSeconds() -> TimeInterval {
        // ~0 is kCGAnyInputEventType, which Swift does not expose as a case.
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}

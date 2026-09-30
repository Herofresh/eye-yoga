import Foundation

public enum Motion: Sendable, Equatable {
    case blink, farGaze, nearFar, circles, figureEight, upDownSide, palming
}

/// x/y in -1...1 (y up), openness 0 closed ... 1 open, far 0 near ... 1 far.
public struct Gaze: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var openness: Double
    public var far: Double

    public init(x: Double = 0, y: Double = 0, openness: Double = 1, far: Double = 1) {
        self.x = x; self.y = y; self.openness = openness; self.far = far
    }
}

extension Motion {
    public func gaze(at t: TimeInterval, duration: TimeInterval) -> Gaze {
        let t = min(max(t, 0), duration)
        let half = duration / 2
        switch self {
        case .blink:
            let phase = t.truncatingRemainder(dividingBy: 1.2)
            let open = phase < 0.3 ? abs(phase - 0.15) / 0.15 : 1
            return Gaze(openness: open)
        case .farGaze:
            return Gaze(x: 0.35, y: 0.3)
        case .nearFar:
            let cycle = duration / 10
            let isNear = t.truncatingRemainder(dividingBy: cycle) < cycle / 2
            return Gaze(far: isNear ? 0 : 1)
        case .circles:
            let clockwise = t < half
            let local = clockwise ? t : t - half
            let angle = 2 * Double.pi * 5 * local / half
            return Gaze(x: clockwise ? sin(angle) : -sin(angle), y: cos(angle))
        case .figureEight:
            let theta = 2 * Double.pi * 8 * t / duration
            return Gaze(x: sin(theta), y: sin(2 * theta) / 2)
        case .upDownSide:
            // An even number of equal ~2 s holds per half, so each half starts fresh (up, then left).
            let hold = half / max(2, 2 * (half / 4).rounded())
            let local = t < half ? t : t - half
            let sign: Double = Int(local / hold).isMultiple(of: 2) ? 1 : -1
            return t < half ? Gaze(y: sign) : Gaze(x: -sign)
        case .palming:
            return Gaze(openness: 0)
        }
    }
}

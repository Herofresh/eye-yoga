import Foundation

public struct Exercise: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let instruction: String
    public let duration: TimeInterval
    public let motion: Motion
}

public enum Routine {
    public static let standard: [Exercise] = [
        Exercise(id: "palm", title: "PALMING",
                 instruction: "Rub your palms warm and cup them over closed eyes. Breathe.",
                 duration: 30, motion: .palming),
        Exercise(id: "blink", title: "BLINK",
                 instruction: "Blink quickly, then close your eyes softly for a moment.",
                 duration: 20, motion: .blink),
        Exercise(id: "nearfar", title: "NEAR / FAR",
                 instruction: "Focus on your thumb 25 cm away, then on something far. Switch 10 times.",
                 duration: 60, motion: .nearFar),
        Exercise(id: "circles", title: "CIRCLES",
                 instruction: "Roll your eyes in a slow circle: 5 clockwise, then 5 counter-clockwise.",
                 duration: 40, motion: .circles),
        Exercise(id: "eight", title: "FIGURE-8",
                 instruction: "Trace a big sideways 8 on the far wall with your eyes. 8 loops.",
                 duration: 30, motion: .figureEight),
        Exercise(id: "cross", title: "UP/DOWN, SIDE",
                 instruction: "Look up, then down. Then left, then right. Hold each end briefly.",
                 duration: 30, motion: .upDownSide),
        Exercise(id: "window", title: "WINDOW GAZE",
                 instruction: "Rest your eyes on the far horizon or the sky out the window.",
                 duration: 30, motion: .farGaze),
    ]

    public static let micro: [Exercise] = [
        Exercise(id: "micro", title: "20-20-20",
                 instruction: "Look out the window at something 6 m (20 ft) away. Blink slowly 10 times.",
                 duration: 20, motion: .farGaze),
    ]

    public static func exercises(for kind: BreakKind) -> [Exercise] {
        kind == .full ? standard : micro
    }

    public static func totalDuration(_ exercises: [Exercise] = standard) -> TimeInterval {
        exercises.reduce(0) { $0 + $1.duration }
    }

    public struct Position: Sendable, Equatable {
        public let index: Int
        public let local: TimeInterval
    }

    /// Nil once `elapsed` has run past the last exercise.
    public static func position(in exercises: [Exercise] = standard, at elapsed: TimeInterval) -> Position? {
        var start: TimeInterval = 0
        for (i, exercise) in exercises.enumerated() {
            if elapsed < start + exercise.duration {
                return Position(index: i, local: max(0, elapsed - start))
            }
            start += exercise.duration
        }
        return nil
    }

    public static func startTime(of index: Int, in exercises: [Exercise] = standard) -> TimeInterval {
        exercises.prefix(index).reduce(0) { $0 + $1.duration }
    }
}

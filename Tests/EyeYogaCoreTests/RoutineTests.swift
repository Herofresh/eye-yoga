import Foundation
import Testing
@testable import EyeYogaCore

@Suite struct RoutineTests {
    @Test func standardRoutineIsFourMinutes() {
        #expect(Routine.standard.count == 7)
        #expect(Routine.totalDuration() == 240)
        #expect(Set(Routine.standard.map(\.id)).count == Routine.standard.count)
    }

    @Test func standardRoutineFollowsThePlan() {
        #expect(Routine.standard.map(\.id) == ["palm", "blink", "nearfar", "circles", "eight", "cross", "window"])
        #expect(Routine.standard.map(\.duration) == [30, 20, 60, 40, 30, 30, 30])
    }

    @Test func microBreakIsTwentySecondsOfFarGaze() {
        #expect(Routine.exercises(for: .micro).count == 1)
        #expect(Routine.totalDuration(Routine.exercises(for: .micro)) == 20)
        #expect(Routine.exercises(for: .micro)[0].motion == .farGaze)
        #expect(Routine.exercises(for: .full) == Routine.standard)
    }

    @Test func upDownSideStartsUpThenLeft() {
        let m = Motion.upDownSide
        #expect(m.gaze(at: 0.5, duration: 30).y > 0)
        #expect(m.gaze(at: 2.5, duration: 30).y < 0)
        #expect(m.gaze(at: 15.1, duration: 30).x < 0)
        #expect(m.gaze(at: 17.5, duration: 30).x > 0)
    }

    @Test func positionWalksThroughExercises() {
        #expect(Routine.position(at: 0) == .init(index: 0, local: 0))
        #expect(Routine.position(at: 29.9)?.index == 0)
        #expect(Routine.position(at: 30) == .init(index: 1, local: 0))
        #expect(Routine.position(at: 239.9)?.index == 6)
        #expect(Routine.position(at: 240) == nil)
    }

    @Test func startTimesMatchPositions() {
        for i in Routine.standard.indices {
            #expect(Routine.position(at: Routine.startTime(of: i))?.index == i)
        }
    }

    @Test func gazeStaysInRange() {
        for exercise in Routine.standard + Routine.micro {
            for step in 0...200 {
                let g = exercise.motion.gaze(at: exercise.duration * Double(step) / 200, duration: exercise.duration)
                #expect((-1.0001...1.0001).contains(g.x) && (-1.0001...1.0001).contains(g.y))
                #expect((0...1).contains(g.openness) && (0...1).contains(g.far))
            }
        }
    }

    @Test func circlesReverseHalfway() {
        let m = Motion.circles
        #expect(m.gaze(at: 1, duration: 40).x > 0)
        #expect(m.gaze(at: 21, duration: 40).x < 0)
    }

    @Test func nearFarSwitchesTenTimes() {
        var switches = 0
        var last = Motion.nearFar.gaze(at: 0, duration: 60).far
        for step in 1...600 {
            let far = Motion.nearFar.gaze(at: Double(step) / 10, duration: 60).far
            if far != last { switches += 1; last = far }
        }
        #expect(switches >= 19)
    }

    @Test func framesHaveFixedSize() {
        for exercise in Routine.standard {
            for t in stride(from: 0, to: exercise.duration, by: 0.7) {
                let frame = AsciiFrame.render(motion: exercise.motion,
                                              gaze: exercise.motion.gaze(at: t, duration: exercise.duration))
                #expect(frame.count == AsciiFrame.rows)
                #expect(frame.allSatisfy { $0.count == AsciiFrame.columns })
            }
        }
    }

    @Test func closedEyesAreFlatLines() {
        let frame = AsciiFrame.render(motion: .palming, gaze: Gaze(openness: 0))
        #expect(!frame.joined().contains("@"))
        #expect(frame.joined().contains("="))
    }
}

import AppKit
import SwiftUI
import EyeYogaCore

enum PopupOutcome { case completed, snoozed, skipped }

@MainActor
@Observable
final class PopupModel {
    enum Phase { case intro, running, complete }

    private(set) var kind = BreakKind.full
    private(set) var exercises = Routine.standard
    private(set) var phase = Phase.intro
    private(set) var elapsed: TimeInterval = 0
    private(set) var clock: TimeInterval = 0
    private(set) var xp = 0

    @ObservationIgnored var settings: Settings?
    @ObservationIgnored var onFinish: ((PopupOutcome, BreakKind) -> Void)?
    @ObservationIgnored private var runStart = Date()
    @ObservationIgnored private var shownAt = Date()
    @ObservationIgnored private var lastIndex: Int?
    @ObservationIgnored private var timer: Timer?

    var position: Routine.Position? { Routine.position(in: exercises, at: elapsed) }

    func reset(kind: BreakKind) {
        self.kind = kind
        exercises = Routine.exercises(for: kind)
        phase = .intro
        elapsed = 0
        lastIndex = nil
        shownAt = Date()
        xp = settings?.xp ?? 0
        timer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common keeps the animation running while the panel is dragged.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func start() {
        runStart = Date()
        elapsed = 0
        lastIndex = 0
        phase = .running
        play("Tink")
    }

    func next() {
        guard let index = position?.index else { return }
        runStart = Date().addingTimeInterval(-Routine.startTime(of: index + 1, in: exercises))
        tick()
    }

    func finish(_ outcome: PopupOutcome) {
        timer?.invalidate()
        timer = nil
        onFinish?(outcome, kind)
    }

    private func tick() {
        clock = Date().timeIntervalSince(shownAt)
        guard phase == .running else { return }
        elapsed = Date().timeIntervalSince(runStart)
        let index = position?.index
        guard index != lastIndex else { return }
        lastIndex = index
        if index == nil {
            phase = .complete
            settings?.xp += 1
            xp = settings?.xp ?? xp + 1
            play("Glass")
        } else {
            play("Tink")
        }
    }

    func play(_ name: String) {
        guard settings?.soundEnabled ?? true else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }
}

@MainActor
final class PopupController {
    var settings: Settings? {
        get { model.settings }
        set { model.settings = newValue }
    }
    var onFinish: ((PopupOutcome, BreakKind) -> Void)?

    private let model = PopupModel()
    private var panel: NSPanel?

    init() {
        model.onFinish = { [weak self] outcome, kind in
            self?.panel?.orderOut(nil)
            self?.onFinish?(outcome, kind)
        }
    }

    func show(kind: BreakKind) {
        if let panel, panel.isVisible {
            panel.orderFrontRegardless()
            return
        }
        model.reset(kind: kind)
        let panel = self.panel ?? makePanel()
        self.panel = panel
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: visible.midX - panel.frame.width / 2,
                                         y: visible.midY - panel.frame.height / 2))
        }
        panel.orderFrontRegardless()
        model.play("Hero")
    }

    private func makePanel() -> NSPanel {
        let panel = KeyablePanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // Accessory apps are never active, so the default would hide the panel immediately.
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.contentView = FirstClickHostingView(rootView: PopupView(model: model))
        return panel
    }
}

/// Borderless panels refuse key status by default, which would leave Return/Esc dead.
/// `.nonactivatingPanel` still keeps it from stealing focus until clicked.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// The panel is not key when it appears, so the first click must reach the buttons directly.
private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

struct PopupView: View {
    let model: PopupModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("EYE YOGA").foregroundStyle(Palette.amber)
                Spacer()
                Text("XP \(model.xp)")
            }
            .font(.pixel(8))

            switch model.phase {
            case .intro: intro
            case .running: running
            case .complete: complete
            }
        }
        .foregroundStyle(Palette.phosphor)
        .padding(18)
        .frame(width: 480, height: 360)
        .background(Palette.background)
        .overlay(Scanlines())
        .clipShape(NotchedRect(block: 4))
        .overlay(PixelBorder(block: 4).fill(Palette.phosphor))
        .focusEffectDisabled()
    }

    private var summary: String {
        let total = Int(Routine.totalDuration(model.exercises))
        let count = model.exercises.count
        let moves = count == 1 ? "1 MOVE" : "\(count) MOVES"
        return total < 60 ? "\(moves) - \(total)S" : "\(moves) - ~\(total / 60) MIN"
    }

    private var intro: some View {
        VStack(spacing: 12) {
            AsciiCanvas(lines: AsciiFrame.render(
                motion: .blink, gaze: Motion.blink.gaze(at: min(model.clock.truncatingRemainder(dividingBy: 4), 0.5), duration: 30)), pixels: true)
                .frame(height: 140)
            Text(model.kind == .full ? "TIME FOR EYE YOGA!" : "20-20-20 BREAK!").font(.pixel(16))
            Text(summary).font(.pixel(8)).foregroundStyle(Palette.dim)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                Button("START") { model.start() }.buttonStyle(PixelButtonStyle(primary: true))
                    .keyboardShortcut(.defaultAction)
                Button("SNOOZE 5M") { model.finish(.snoozed) }.buttonStyle(PixelButtonStyle())
                Button("SKIP") { model.finish(.skipped) }.buttonStyle(PixelButtonStyle())
                    .keyboardShortcut(.cancelAction)
            }
        }
    }

    @ViewBuilder private var running: some View {
        if let pos = model.position {
            let exercise = model.exercises[pos.index]
            VStack(spacing: 10) {
                HStack {
                    Text("\(pos.index + 1)/\(model.exercises.count) \(exercise.title)")
                    Spacer()
                    Text("\(Int((exercise.duration - pos.local).rounded(.up)))S").foregroundStyle(Palette.amber)
                }
                .font(.pixel(16))
                AsciiCanvas(lines: AsciiFrame.render(
                    motion: exercise.motion, gaze: exercise.motion.gaze(at: pos.local, duration: exercise.duration)), pixels: true)
                    .frame(height: 140)
                Text(exercise.instruction)
                    .font(.pixel(8))
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .top)
                ProgressBlocks(fraction: pos.local / exercise.duration)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    Button("NEXT >>") { model.next() }.buttonStyle(PixelButtonStyle(primary: true))
                        .keyboardShortcut(.defaultAction)
                    Button("END") { model.finish(.skipped) }.buttonStyle(PixelButtonStyle())
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }

    private var complete: some View {
        VStack(spacing: 10) {
            AsciiCanvas(lines: Self.trophy, color: Palette.amber, pixels: true).frame(height: 130)
            Text(model.kind == .full ? "ROUTINE COMPLETE" : "BREAK COMPLETE").font(.pixel(16))
            Text("+1 XP").font(.pixel(16)).foregroundStyle(Palette.amber)
            Spacer(minLength: 0)
            Button("DONE") { model.finish(.completed) }.buttonStyle(PixelButtonStyle(primary: true))
                .keyboardShortcut(.defaultAction)
        }
    }

    private static let trophy = [
        " ############# ",
        "## #o####### ##",
        "#  #o#######  #",
        "## #o####### ##",
        " # #o####### # ",
        "   #o#######   ",
        "    #######    ",
        "     #####     ",
        "      ###      ",
        "      ###      ",
        "    #######    ",
        "   #########   ",
    ]
}

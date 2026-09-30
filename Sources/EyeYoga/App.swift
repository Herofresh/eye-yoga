import AppKit
import CoreText
import EyeYogaCore

@main
enum EyeYogaMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private let options = LaunchOptions.parse(Array(CommandLine.arguments.dropFirst()))
    private var scheduler: Scheduler!
    private var menuBar: MenuBar!
    private let popup = PopupController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isAnotherInstanceRunning() {
            NSApp.terminate(nil)
            return
        }
        PixelFont.register()

        let micro = options.intervalSeconds ?? TimeInterval(settings.microIntervalMinutes * 60)
        let full = options.intervalSeconds.map { $0 * 3 } ?? TimeInterval(settings.fullIntervalMinutes * 60)
        scheduler = Scheduler(microInterval: micro, fullInterval: full,
                              idleResetThreshold: options.idleSeconds ?? 5 * 60)
        menuBar = MenuBar(settings: settings, scheduler: scheduler, intervalOverridden: options.intervalSeconds != nil)
        menuBar.onStart = { [weak self] kind in self?.showPopup(kind) }

        scheduler.onDue = { [weak self] kind in self?.showPopup(kind) }
        scheduler.onTick = { [weak self] in self?.menuBar.refresh() }

        popup.settings = settings
        popup.onFinish = { [weak self] outcome, kind in
            guard let self else { return }
            if outcome == .snoozed { scheduler.snooze() } else { scheduler.complete(kind) }
            menuBar.refresh()
        }

        scheduler.start()
        menuBar.refresh()
    }

    private func showPopup(_ kind: BreakKind) {
        scheduler.hold()
        popup.show(kind: kind)
    }

    /// `swift run` has no bundle id, so debugging next to the installed copy still works.
    private func isAnotherInstanceRunning() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return false }
        let me = ProcessInfo.processInfo.processIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .contains { $0.processIdentifier != me }
    }
}

@MainActor
enum PixelFont {
    static let name = "PressStart2P-Regular"
    private(set) static var isAvailable = false

    static func register() {
        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "ttf"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Resources/\(name).ttf"),
        ]
        guard let url = candidates.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) })
        else { return }
        isAvailable = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func nsFont(_ size: CGFloat) -> NSFont {
        (isAvailable ? NSFont(name: name, size: size) : nil)
            ?? .monospacedSystemFont(ofSize: size, weight: .bold)
    }
}

import AppKit
import EyeYogaCore

@MainActor
final class MenuBar: NSObject, NSMenuDelegate {
    var onStart: ((BreakKind) -> Void)?

    private let settings: Settings
    private let scheduler: Scheduler
    private let intervalOverridden: Bool
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init(settings: Settings, scheduler: Scheduler, intervalOverridden: Bool) {
        self.settings = settings
        self.scheduler = scheduler
        self.intervalOverridden = intervalOverridden
        super.init()
        item.button?.image = Self.eyeIcon()
        item.button?.imagePosition = .imageLeading
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        item.menu = menu
    }

    func refresh() {
        let title = scheduler.isPaused ? " PAUSED" : " " + formatCountdown(scheduler.remaining)
        item.button?.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)]
        )
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let next = scheduler.upcomingKind == .full ? "Full routine" : "Micro break"
        let status = scheduler.isPaused ? "Paused" : "\(next) in \(formatCountdown(scheduler.remaining))"
        menu.addItem(disabled(status))
        menu.addItem(disabled("XP: \(settings.xp)"))
        menu.addItem(.separator())
        menu.addItem(action("Start Routine Now", #selector(startFull), key: "s"))
        menu.addItem(action("Start Micro Break Now", #selector(startMicro), key: "m"))
        menu.addItem(action(scheduler.isPaused ? "Resume" : "Pause", #selector(togglePause), key: "p"))
        menu.addItem(intervalMenu("Micro Break Every", choices: Settings.microChoices,
                                  current: settings.microIntervalMinutes,
                                  #selector(pickMicro(_:)), custom: #selector(customMicro)))
        menu.addItem(intervalMenu("Full Routine Every", choices: Settings.fullChoices,
                                  current: settings.fullIntervalMinutes,
                                  #selector(pickFull(_:)), custom: #selector(customFull)))

        let sound = action("Sound", #selector(toggleSound))
        sound.state = settings.soundEnabled ? .on : .off
        menu.addItem(sound)
        menu.addItem(.separator())
        menu.addItem(action("Quit Eye Yoga", #selector(quit), key: "q"))
    }

    private func intervalMenu(_ title: String, choices: [Int], current: Int,
                              _ selector: Selector, custom: Selector) -> NSMenuItem {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for minutes in choices {
            let entry = action("\(minutes) min", selector)
            entry.tag = minutes
            entry.state = !intervalOverridden && minutes == current ? .on : .off
            entry.isEnabled = !intervalOverridden
            submenu.addItem(entry)
        }
        submenu.addItem(.separator())
        let isCustom = !choices.contains(current)
        let customEntry = action(isCustom ? "Custom (\(current) min)…" : "Custom…", custom)
        customEntry.state = !intervalOverridden && isCustom ? .on : .off
        customEntry.isEnabled = !intervalOverridden
        submenu.addItem(customEntry)
        if intervalOverridden {
            submenu.addItem(.separator())
            submenu.addItem(disabled("Overridden by --interval-seconds"))
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    @objc private func startFull() { onStart?(.full) }
    @objc private func startMicro() { onStart?(.micro) }
    @objc private func togglePause() { scheduler.togglePause() }
    @objc private func toggleSound() { settings.soundEnabled.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func pickMicro(_ sender: NSMenuItem) {
        settings.microIntervalMinutes = sender.tag
        applyIntervals()
    }

    @objc private func pickFull(_ sender: NSMenuItem) {
        settings.fullIntervalMinutes = sender.tag
        applyIntervals()
    }

    @objc private func customMicro() {
        guard let minutes = askMinutes("Micro break every", current: settings.microIntervalMinutes) else { return }
        settings.microIntervalMinutes = minutes
        applyIntervals()
    }

    @objc private func customFull() {
        guard let minutes = askMinutes("Full routine every", current: settings.fullIntervalMinutes) else { return }
        settings.fullIntervalMinutes = minutes
        applyIntervals()
    }

    private func askMinutes(_ title: String, current: Int) -> Int? {
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 80, height: 24))
        field.integerValue = current
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = NSNumber(value: Settings.minutesRange.lowerBound)
        formatter.maximum = NSNumber(value: Settings.minutesRange.upperBound)
        field.formatter = formatter

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "Minutes (\(Settings.minutesRange.lowerBound)–\(Settings.minutesRange.upperBound))"
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        // Menu-bar-only apps are never frontmost, so the alert would open behind other windows.
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return min(max(field.integerValue, Settings.minutesRange.lowerBound), Settings.minutesRange.upperBound)
    }

    private func applyIntervals() {
        scheduler.setIntervals(micro: TimeInterval(settings.microIntervalMinutes * 60),
                               full: TimeInterval(settings.fullIntervalMinutes * 60))
    }

    private func action(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        entry.target = self
        return entry
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        entry.isEnabled = false
        return entry
    }

    private static func eyeIcon() -> NSImage {
        let pixels = [
            "...#####...",
            ".##.....##.",
            "#...###...#",
            "#...###...#",
            ".##.....##.",
            "...#####...",
        ]
        let px: CGFloat = 1.5
        let size = NSSize(width: CGFloat(pixels[0].count) * px, height: 18)
        let top = (size.height + CGFloat(pixels.count) * px) / 2
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            for (r, row) in pixels.enumerated() {
                for (c, ch) in row.enumerated() where ch == "#" {
                    NSRect(x: CGFloat(c) * px, y: top - CGFloat(r + 1) * px, width: px, height: px).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}

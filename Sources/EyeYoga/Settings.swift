import Foundation

@MainActor
final class Settings {
    static let microChoices = [15, 20, 30]
    static let fullChoices = [45, 60, 90]
    static let snoozeSeconds: TimeInterval = 5 * 60

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "microIntervalMinutes": 20, "fullIntervalMinutes": 60, "soundEnabled": true, "xp": 0,
        ])
    }

    var microIntervalMinutes: Int {
        get { defaults.integer(forKey: "microIntervalMinutes") }
        set { defaults.set(newValue, forKey: "microIntervalMinutes") }
    }

    var fullIntervalMinutes: Int {
        get { defaults.integer(forKey: "fullIntervalMinutes") }
        set { defaults.set(newValue, forKey: "fullIntervalMinutes") }
    }

    var soundEnabled: Bool {
        get { defaults.bool(forKey: "soundEnabled") }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }

    var xp: Int {
        get { defaults.integer(forKey: "xp") }
        set { defaults.set(newValue, forKey: "xp") }
    }
}

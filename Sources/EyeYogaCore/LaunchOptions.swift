import Foundation

/// Command-line overrides, mainly for trying the pop-up without waiting 20 minutes.
public struct LaunchOptions: Sendable, Equatable {
    public static let minimumSeconds: TimeInterval = 5

    public var intervalSeconds: TimeInterval?
    public var idleSeconds: TimeInterval?

    public init(intervalSeconds: TimeInterval? = nil, idleSeconds: TimeInterval? = nil) {
        self.intervalSeconds = intervalSeconds
        self.idleSeconds = idleSeconds
    }

    /// Accepts `--flag N` and `--flag=N`; unknown or malformed values are ignored.
    public static func parse(_ arguments: [String]) -> LaunchOptions {
        var options = LaunchOptions()
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            let (name, inline) = split(arg)
            var value = inline
            if value == nil, i + 1 < arguments.count, !arguments[i + 1].hasPrefix("--"),
               name == "--interval-seconds" || name == "--idle-seconds" {
                value = arguments[i + 1]
                i += 1
            }
            let seconds = value.flatMap(Double.init).map { max(minimumSeconds, $0) }
            switch name {
            case "--interval-seconds": options.intervalSeconds = seconds ?? options.intervalSeconds
            case "--idle-seconds": options.idleSeconds = seconds ?? options.idleSeconds
            default: break
            }
            i += 1
        }
        return options
    }

    private static func split(_ arg: String) -> (String, String?) {
        guard let eq = arg.firstIndex(of: "=") else { return (arg, nil) }
        return (String(arg[..<eq]), String(arg[arg.index(after: eq)...]))
    }
}

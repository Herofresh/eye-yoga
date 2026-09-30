import Foundation

/// Builds one animation frame as a fixed grid of characters: two eyes plus a prop strip.
public enum AsciiFrame {
    public static let columns = 40
    public static let rows = 14

    static let eyeWidth = 17
    static let eyeHeight = 9
    static let propTop = 10

    public static func render(motion: Motion, gaze: Gaze) -> [String] {
        var grid = Array(repeating: Array(repeating: Character(" "), count: columns), count: rows)
        let eye = eyeSprite(gaze: gaze)
        for left in [2, 21] {
            for r in 0..<eyeHeight {
                for c in 0..<eyeWidth where eye[r][c] != " " {
                    grid[r][left + c] = eye[r][c]
                }
            }
        }
        for (r, line) in prop(motion: motion, gaze: gaze).enumerated() where propTop + r < rows {
            let chars = Array(line)
            let left = max(0, (columns - chars.count) / 2)
            for (c, ch) in chars.enumerated() where left + c < columns {
                grid[propTop + r][left + c] = ch
            }
        }
        return grid.map { String($0) }
    }

    static func eyeSprite(gaze: Gaze) -> [[Character]] {
        let w = eyeWidth, h = eyeHeight
        let cx = Double(w - 1) / 2, cy = Double(h - 1) / 2
        var sprite = Array(repeating: Array(repeating: Character(" "), count: w), count: h)

        if gaze.openness < 0.15 {
            for c in 1..<(w - 1) { sprite[Int(cy)][c] = "=" }
            return sprite
        }

        func inside(_ r: Int, _ c: Int) -> Bool {
            guard r >= 0, r < h, c >= 0, c < w else { return false }
            let u = (Double(c) - cx) / cx
            let v = (Double(r) - cy) / cy
            return abs(v) <= (1 - u * u) * gaze.openness + 0.05
        }

        // Near focus pulls the iris in and shrinks the pupil.
        let irisX = cx + gaze.x * cx * 0.45 * (0.6 + 0.4 * gaze.far)
        let irisY = cy - gaze.y * cy * 0.45
        let irisR = 2.6
        let pupilR = gaze.far > 0.5 ? 1.3 : 0.8

        for r in 0..<h {
            for c in 0..<w where inside(r, c) {
                let edge = !inside(r - 1, c) || !inside(r + 1, c) || !inside(r, c - 1) || !inside(r, c + 1)
                if edge {
                    sprite[r][c] = "#"
                    continue
                }
                let dx = Double(c) - irisX
                let dy = (Double(r) - irisY) * 1.6
                let d = (dx * dx + dy * dy).squareRoot()
                sprite[r][c] = d <= pupilR ? "@" : d <= irisR ? "o" : "."
            }
        }
        return sprite
    }

    /// '#', '@', 'o' and '.' are drawn as pixel blocks by the app; other characters as text.
    static func prop(motion: Motion, gaze: Gaze) -> [String] {
        switch motion {
        case .farGaze:
            return ["#############", "#...@@@.....#", "#...@@@.....#", "#############"]
        case .nearFar:
            return gaze.far < 0.5
                ? ["##", "#oo#", "#oo#", "NEAR 25CM"]
                : ["  #       ", " ###    # ", "#####  ###", "FAR 6M"]
        case .palming:
            return ["ooooo    ooooo", "ooooooo  ooooooo", "", "WARM HANDS, DARK"]
        case .blink:
            return gaze.openness < 0.5 ? ["", "* BLINK *"] : []
        default:
            return []
        }
    }
}

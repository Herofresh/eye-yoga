import SwiftUI

enum Palette {
    static let background = Color(red: 0.04, green: 0.06, blue: 0.04)
    static let phosphor = Color(red: 0.22, green: 1.0, blue: 0.42)
    static let dim = Color(red: 0.12, green: 0.48, blue: 0.23)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.0)
}

extension Font {
    @MainActor static func pixel(_ size: CGFloat) -> Font { Font(PixelFont.nsFont(size) as CTFont) }
}

/// Draws a character grid on square cells so the art stays aligned with any font.
/// With `pixels`, the eye glyphs from AsciiFrame become solid blocks instead of text.
struct AsciiCanvas: View {
    let lines: [String]
    var color: Color = Palette.phosphor
    var pixels = false

    private static let blocks: [Character: Double] = ["#": 1, "@": 1, "o": 0.45, ".": 0.1]

    var body: some View {
        let rows = max(lines.count, 1)
        let columns = max(lines.map(\.count).max() ?? 1, 1)
        Canvas { context, size in
            let cell = floor(min(size.width / CGFloat(columns), size.height / CGFloat(rows)))
            let origin = CGPoint(x: (size.width - cell * CGFloat(columns)) / 2,
                                 y: (size.height - cell * CGFloat(rows)) / 2)
            // Press Start 2P is drawn on an 8 pt grid and only renders crisp at multiples of 8.
            let textSize = max(8, floor(cell / 8) * 8)
            let font = PixelFont.nsFont(PixelFont.isAvailable ? textSize : cell * 1.4)
            var glyphs: [Character: GraphicsContext.ResolvedText] = [:]
            for (r, line) in lines.enumerated() {
                for (c, ch) in line.enumerated() where ch != " " {
                    if pixels, let opacity = Self.blocks[ch] {
                        let rect = CGRect(x: origin.x + CGFloat(c) * cell, y: origin.y + CGFloat(r) * cell,
                                          width: cell, height: cell).insetBy(dx: 0.5, dy: 0.5)
                        context.fill(Path(rect), with: .color(color.opacity(opacity)))
                        continue
                    }
                    let glyph = glyphs[ch] ?? context.resolve(
                        Text(String(ch)).font(Font(font as CTFont)).foregroundStyle(color))
                    glyphs[ch] = glyph
                    context.draw(glyph, at: CGPoint(x: origin.x + (CGFloat(c) + 0.5) * cell,
                                                    y: origin.y + (CGFloat(r) + 0.5) * cell))
                }
            }
        }
    }
}

struct Scanlines: View {
    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.28)))
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

struct ProgressBlocks: View {
    let fraction: Double
    var segments = 24

    var body: some View {
        let lit = Int((fraction * Double(segments)).rounded(.down))
        HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < lit ? Palette.phosphor : Palette.dim.opacity(0.35))
                    .frame(height: 8)
            }
        }
    }
}

struct PixelButtonStyle: ButtonStyle {
    var primary = false

    func makeBody(configuration: Configuration) -> some View {
        let tint = primary ? Palette.amber : Palette.phosphor
        let pressed = configuration.isPressed
        configuration.label
            .font(.pixel(8))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(pressed ? Palette.background : tint)
            .background(pressed ? tint : Palette.background)
            .clipShape(NotchedRect(block: 2))
            .overlay(PixelBorder(block: 2).fill(tint))
            .contentShape(Rectangle())
    }
}

/// A frame of square blocks with stepped corners, like an RPG dialog box.
struct PixelBorder: Shape {
    let block: CGFloat

    func path(in rect: CGRect) -> Path {
        let b = block, w = rect.width, h = rect.height
        var path = Path()
        path.addRects([
            CGRect(x: b, y: 0, width: w - 2 * b, height: b),
            CGRect(x: b, y: h - b, width: w - 2 * b, height: b),
            CGRect(x: 0, y: b, width: b, height: h - 2 * b),
            CGRect(x: w - b, y: b, width: b, height: h - 2 * b),
            CGRect(x: b, y: b, width: b, height: b),
            CGRect(x: w - 2 * b, y: b, width: b, height: b),
            CGRect(x: b, y: h - 2 * b, width: b, height: b),
            CGRect(x: w - 2 * b, y: h - 2 * b, width: b, height: b),
        ].map { $0.offsetBy(dx: rect.minX, dy: rect.minY) })
        return path
    }
}

/// The area inside a PixelBorder, so nothing shows past its cut corners.
struct NotchedRect: Shape {
    let block: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect.insetBy(dx: block, dy: 0))
        path.addRect(rect.insetBy(dx: 0, dy: block))
        return path
    }
}

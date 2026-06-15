import SwiftUI
import CoreText

enum FishedexFont {
    private static let _register: Bool = {
        guard let url = Bundle.main.url(forResource: "Pokemon Classic", withExtension: "ttf") else { return false }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        return true
    }()

    static func pokemon(_ size: CGFloat) -> Font {
        _ = _register
        return .custom("Pokemon-Classic", size: size)
    }

    static let header:      Font = pokemon(18)
    static let title:       Font = pokemon(16)
    static let title2:      Font = pokemon(14)
    static let title3:      Font = pokemon(13)
    static let headline:    Font = pokemon(12)
    static let subheadline: Font = pokemon(10)
    static let body:        Font = pokemon(11)
    static let caption:     Font = pokemon(9)
    static let micro:       Font = pokemon(8)
}

enum FishedexTheme {
    // Base palette
    static let background  = Color.white
    static let card        = Color(red: 0.98, green: 0.98, blue: 0.97)
    static let ink         = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let muted       = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let softLine    = Color.black.opacity(0.06)
    static let cream       = Color(red: 1.0,  green: 0.96, blue: 0.82)
    static let ocean       = Color(red: 0.17, green: 0.54, blue: 0.70)
    static let coral       = Color(red: 1.0,  green: 0.40, blue: 0.48)

    // Brand / UI chrome
    static let headerRed   = Color(red: 0.82, green: 0.15, blue: 0.13)
    static let tabGreen    = Color(red: 0.26, green: 0.75, blue: 0.39)
    static let tabBlue     = Color(red: 0.24, green: 0.48, blue: 0.85)
    static let progressGreen = Color(red: 0.20, green: 0.78, blue: 0.36)
    static let progressBlue  = tabBlue
    static let progressTrack = Color(red: 0.86, green: 0.86, blue: 0.87)

    static func accent(for fish: Fish) -> Color {
        switch fish.id {
        case 1:  return Color(red: 0.26, green: 0.58, blue: 0.67)
        case 2:  return Color(red: 0.96, green: 0.42, blue: 0.58)
        case 3:  return Color(red: 0.95, green: 0.80, blue: 0.18)
        case 4:  return Color(red: 0.28, green: 0.46, blue: 0.52)
        default: return Color(red: 0.93, green: 0.70, blue: 0.18)
        }
    }
}

struct FishedexProgressBar: View {
    let progress: Double
    var height: CGFloat = 14

    private var clampedProgress: CGFloat {
        CGFloat(min(max(progress, 0), 1))
    }

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(FishedexTheme.progressTrack)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(FishedexTheme.progressBlue)
                        .frame(width: proxy.size.width * clampedProgress)
                }
        }
        .frame(height: height)
        .fishedexBorder(lineWidth: 1)
        .animation(.easeOut(duration: 0.25), value: clampedProgress)
    }
}

extension View {
    func fishedexSquare() -> some View {
        clipShape(Rectangle())
    }

    func fishedexBorder(lineWidth: CGFloat = 2, color: Color = .black) -> some View {
        overlay(Rectangle().stroke(color, lineWidth: lineWidth))
    }

    func fishedexCircle() -> some View {
        clipShape(Circle())
    }

    func fishedexCircleBorder(lineWidth: CGFloat = 2, color: Color = .black.opacity(0.5)) -> some View {
        overlay(Circle().stroke(color, lineWidth: lineWidth))
    }

    func fishedexPixelCircle(pixelSize: CGFloat = 2) -> some View {
        clipShape(PixelCircleShape(pixelSize: pixelSize))
    }

    func fishedexPixelCircleBorder(
        pixelSize: CGFloat = 2,
        color: Color = .black.opacity(0.55),
        thickness: CGFloat = 1
    ) -> some View {
        overlay {
            PixelCircleBorder(pixelSize: pixelSize, color: color, thickness: thickness)
        }
    }

    /// Stepped pixel-style border — thin outer stroke with corner accents.
    func fishedexPixelBorder(color: Color = .black.opacity(0.55)) -> some View {
        overlay {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let step: CGFloat = 3

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h - step))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: w - step, y: 0))
                    path.move(to: CGPoint(x: w, y: step))
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: step, y: h))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .square, lineJoin: .miter))

                Path { path in
                    path.move(to: CGPoint(x: w - step, y: 0))
                    path.addLine(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w, y: step))
                    path.move(to: CGPoint(x: 0, y: h - step))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: step, y: h))
                }
                .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter))
            }
        }
    }

    func fishedexCard() -> some View {
        self
            .background(FishedexTheme.card)
            .fishedexSquare()
            .fishedexBorder()
    }

    func fishedexInputText() -> some View {
        foregroundStyle(FishedexTheme.ink)
    }
}

// MARK: - Pixel toggle

struct FishedexPixelToggle: View {
    @Binding var isOn: Bool

    private let trackWidth: CGFloat = 52
    private let trackHeight: CGFloat = 28
    private let knobSize: CGFloat = 22

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: 0.12)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Rectangle()
                    .fill(FishedexTheme.progressTrack)

                Rectangle()
                    .fill(isOn ? FishedexTheme.tabGreen : Color(red: 0.78, green: 0.78, blue: 0.80))
                    .frame(width: knobSize, height: knobSize)
                    .padding(3)
            }
            .frame(width: trackWidth, height: trackHeight)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Pixel circle

struct PixelCircleShape: Shape {
    var pixelSize: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        pixelCirclePath(in: rect, pixelSize: pixelSize, thickness: nil)
    }
}

struct PixelCircleBorder: View {
    var pixelSize: CGFloat = 4
    var color: Color = .black.opacity(0.55)
    var thickness: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            Canvas { context, _ in
                let path = pixelCirclePath(
                    in: CGRect(origin: .zero, size: geo.size),
                    pixelSize: pixelSize,
                    thickness: thickness
                )
                context.fill(path, with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}

private func pixelCirclePath(in rect: CGRect, pixelSize: CGFloat, thickness: CGFloat?) -> Path {
    let cols = max(1, Int(rect.width / pixelSize))
    let rows = max(1, Int(rect.height / pixelSize))
    let centerX = CGFloat(cols) / 2
    let centerY = CGFloat(rows) / 2
    let radius = min(centerX, centerY) - 0.5
    let outerRadiusSq = radius * radius
    let innerRadiusSq = thickness.map { max($0, 0) }.map { radius - $0 }.map { $0 * $0 }

    var path = Path()
    for row in 0..<rows {
        for col in 0..<cols {
            let dx = CGFloat(col) - centerX + 0.5
            let dy = CGFloat(row) - centerY + 0.5
            let distSq = dx * dx + dy * dy

            let include: Bool
            if let innerRadiusSq {
                include = distSq <= outerRadiusSq && distSq > innerRadiusSq
            } else {
                include = distSq <= outerRadiusSq
            }

            guard include else { continue }

            path.addRect(CGRect(
                x: rect.minX + CGFloat(col) * pixelSize,
                y: rect.minY + CGFloat(row) * pixelSize,
                width: pixelSize,
                height: pixelSize
            ))
        }
    }
    return path
}

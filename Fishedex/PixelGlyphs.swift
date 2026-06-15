import SwiftUI

struct PixelCoord: Hashable {
    let x: Int
    let y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

struct PixelGlyphIcon: View {
    let pixels: Set<PixelCoord>
    var tint: Color
    var pixelSize: CGFloat = 1.5
    var gridSize: Int = 16

    var body: some View {
        Canvas { context, _ in
            for pixel in pixels {
                let rect = CGRect(
                    x: CGFloat(pixel.x) * pixelSize,
                    y: CGFloat(pixel.y) * pixelSize,
                    width: pixelSize,
                    height: pixelSize
                )
                context.fill(Path(rect), with: .color(tint))
            }
        }
        .frame(
            width: CGFloat(gridSize) * pixelSize,
            height: CGFloat(gridSize) * pixelSize
        )
        .accessibilityHidden(true)
    }
}

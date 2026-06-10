import SwiftUI

enum AppTab {
    case map, catch_, dex
}

/// Custom three-button tab bar matching the MAP / CATCH / DEX design.
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 10) {
            TabBarButton(
                title: "MAP",
                icon: .map,
                isActive: selectedTab == .map,
                activeColor: FishedexTheme.tabBlue
            ) { selectedTab = .map }

            TabBarButton(
                title: "CATCH",
                icon: .catch_,
                isActive: selectedTab == .catch_,
                activeColor: FishedexTheme.tabGreen
            ) { selectedTab = .catch_ }

            TabBarButton(
                title: "DEX",
                icon: .dex,
                isActive: selectedTab == .dex,
                activeColor: FishedexTheme.tabBlue
            ) { selectedTab = .dex }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 1)
                Color(red: 0.90, green: 0.90, blue: 0.91)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.map))
        .padding()
        .background(Color(red: 0.92, green: 0.92, blue: 0.93))
}

// MARK: - Tab bar button

private enum TabBarIcon {
    case map, catch_, dex

    @ViewBuilder
    func view(tint: Color) -> some View {
        switch self {
        case .map:
            PixelGlyphIcon(pixels: Self.mapPixels, tint: tint)
        case .catch_:
            PixelGlyphIcon(pixels: Self.rodPixels, tint: tint)
        case .dex:
            PixelGlyphIcon(pixels: Self.dexPixels, tint: tint)
        }
    }

    private static let mapPixels: Set<PixelCoord> = [
        // Folded map sheet
        PixelCoord(2, 10), PixelCoord(3, 10), PixelCoord(4, 10), PixelCoord(5, 10),
        PixelCoord(6, 10), PixelCoord(7, 10), PixelCoord(8, 10), PixelCoord(9, 10),
        PixelCoord(10, 10), PixelCoord(11, 10), PixelCoord(12, 10), PixelCoord(13, 10),
        PixelCoord(2, 11), PixelCoord(3, 11), PixelCoord(4, 11), PixelCoord(5, 11),
        PixelCoord(6, 11), PixelCoord(7, 11), PixelCoord(8, 11), PixelCoord(9, 11),
        PixelCoord(10, 11), PixelCoord(11, 11), PixelCoord(12, 11), PixelCoord(13, 11),
        PixelCoord(3, 9), PixelCoord(4, 9), PixelCoord(5, 9), PixelCoord(6, 9),
        PixelCoord(7, 9), PixelCoord(8, 9), PixelCoord(9, 9), PixelCoord(10, 9),
        PixelCoord(11, 9), PixelCoord(12, 9),
        // Fold corner
        PixelCoord(2, 9), PixelCoord(2, 8), PixelCoord(3, 8),
        // Location pin
        PixelCoord(7, 2), PixelCoord(8, 2),
        PixelCoord(6, 3), PixelCoord(7, 3), PixelCoord(8, 3), PixelCoord(9, 3),
        PixelCoord(6, 4), PixelCoord(7, 4), PixelCoord(8, 4), PixelCoord(9, 4),
        PixelCoord(7, 5), PixelCoord(8, 5),
        PixelCoord(7, 6), PixelCoord(8, 6),
        PixelCoord(5, 7), PixelCoord(6, 7), PixelCoord(7, 7), PixelCoord(8, 7),
        PixelCoord(9, 7), PixelCoord(10, 7),
    ]

    private static let dexPixels: Set<PixelCoord> = [
        // Left page
        PixelCoord(3, 3), PixelCoord(4, 3), PixelCoord(5, 3), PixelCoord(6, 3), PixelCoord(7, 3),
        PixelCoord(3, 4), PixelCoord(7, 4),
        PixelCoord(3, 5), PixelCoord(7, 5),
        PixelCoord(3, 6), PixelCoord(7, 6),
        PixelCoord(3, 7), PixelCoord(7, 7),
        PixelCoord(3, 8), PixelCoord(7, 8),
        PixelCoord(3, 9), PixelCoord(4, 9), PixelCoord(5, 9), PixelCoord(6, 9), PixelCoord(7, 9),
        PixelCoord(3, 10), PixelCoord(4, 10), PixelCoord(5, 10), PixelCoord(6, 10), PixelCoord(7, 10),
        PixelCoord(3, 11), PixelCoord(4, 11), PixelCoord(5, 11), PixelCoord(6, 11), PixelCoord(7, 11),
        // Spine
        PixelCoord(8, 2), PixelCoord(8, 3), PixelCoord(8, 4), PixelCoord(8, 5),
        PixelCoord(8, 6), PixelCoord(8, 7), PixelCoord(8, 8), PixelCoord(8, 9),
        PixelCoord(8, 10), PixelCoord(8, 11), PixelCoord(8, 12),
        // Right page
        PixelCoord(9, 3), PixelCoord(10, 3), PixelCoord(11, 3), PixelCoord(12, 3),
        PixelCoord(9, 4), PixelCoord(12, 4),
        PixelCoord(9, 5), PixelCoord(12, 5),
        PixelCoord(9, 6), PixelCoord(12, 6),
        PixelCoord(9, 7), PixelCoord(12, 7),
        PixelCoord(9, 8), PixelCoord(12, 8),
        PixelCoord(9, 9), PixelCoord(10, 9), PixelCoord(11, 9), PixelCoord(12, 9),
        PixelCoord(9, 10), PixelCoord(10, 10), PixelCoord(11, 10), PixelCoord(12, 10),
        PixelCoord(9, 11), PixelCoord(10, 11), PixelCoord(11, 11), PixelCoord(12, 11),
        // Fish silhouette on right page
        PixelCoord(10, 6), PixelCoord(11, 6),
        PixelCoord(9, 7), PixelCoord(10, 7), PixelCoord(11, 7), PixelCoord(12, 7),
        PixelCoord(10, 8), PixelCoord(11, 8),
    ]

    private static let rodPixels: Set<PixelCoord> = [
        // Stick
        PixelCoord(4, 13), PixelCoord(5, 12), PixelCoord(6, 11), PixelCoord(7, 10),
        PixelCoord(8, 9), PixelCoord(9, 8), PixelCoord(10, 7), PixelCoord(11, 6),
        PixelCoord(12, 5), PixelCoord(13, 4),
        // Reel
        PixelCoord(7, 10), PixelCoord(8, 10),
        PixelCoord(7, 11), PixelCoord(8, 11),
        // Line
        PixelCoord(13, 5), PixelCoord(13, 6), PixelCoord(13, 7), PixelCoord(13, 8),
        PixelCoord(13, 9), PixelCoord(13, 10), PixelCoord(13, 11), PixelCoord(13, 12),
    ]
}

private struct PixelCoord: Hashable {
    let x: Int
    let y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

private struct PixelGlyphIcon: View {
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

private struct TabBarButton: View {
    let title: String
    let icon: TabBarIcon
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    private var iconTint: Color {
        isActive ? .white : FishedexTheme.muted
    }

    private var shadowOffset: CGFloat {
        isActive ? 2 : 3
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.black.opacity(isActive ? 0.22 : 0.14))
                    .offset(x: shadowOffset, y: shadowOffset)

                VStack(spacing: 6) {
                    ZStack {
                        Rectangle()
                            .fill(
                                isActive
                                    ? Color.white.opacity(0.18)
                                    : activeColor.opacity(0.10)
                            )
                            .frame(width: 30, height: 30)
                            .fishedexBorder(
                                lineWidth: 1,
                                color: isActive
                                    ? Color.white.opacity(0.35)
                                    : activeColor.opacity(0.28)
                            )

                        icon.view(tint: iconTint)
                    }

                    Text(title)
                        .font(FishedexFont.subheadline)
                        .foregroundStyle(isActive ? .white : FishedexTheme.ink)
                        .kerning(0.4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background { buttonFace }
                .fishedexSquare()
                .fishedexPixelBorder(
                    color: isActive ? Color.black.opacity(0.65) : Color.black.opacity(0.42)
                )
                .offset(x: isActive ? -1 : 0, y: isActive ? -1 : 0)
            }
        }
        .buttonStyle(TabBarPressStyle())
        .animation(.easeOut(duration: 0.12), value: isActive)
    }

    @ViewBuilder
    private var buttonFace: some View {
        if isActive {
            ZStack(alignment: .top) {
                activeColor

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.white.opacity(0.06),
                        Color.clear,
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 3)
                }
            }
        } else {
            ZStack(alignment: .top) {
                Color(red: 0.99, green: 0.99, blue: 0.98)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 5)
                    Rectangle()
                        .fill(Color(red: 0.94, green: 0.94, blue: 0.95))
                        .frame(height: 3)
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 0.90, green: 0.90, blue: 0.91))
                        .frame(height: 4)
                }
            }
        }
    }
}

private struct TabBarPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(
                x: configuration.isPressed ? 1 : 0,
                y: configuration.isPressed ? 1 : 0
            )
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

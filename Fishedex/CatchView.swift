import SwiftUI

// MARK: - Catch Tab (full-screen camera UI)

struct CatchView: View {
    @State private var fishDetected = true

    var body: some View {
        ZStack {
            CameraBackground()
            CameraOverlay(fishDetected: $fishDetected)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Camera background (simulated lake scene)

private struct CameraBackground: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 0.58, green: 0.80, blue: 0.90),
                    Color(red: 0.25, green: 0.52, blue: 0.65),
                    Color(red: 0.12, green: 0.32, blue: 0.40),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Vegetation silhouette
            HStack(alignment: .bottom, spacing: -18) {
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "leaf.fill")
                        .font(.system(size: CGFloat(55 + (i % 3) * 12)))
                        .foregroundStyle(
                            Color(red: 0.28, green: 0.55, blue: 0.24)
                                .opacity(0.75 - Double(i) * 0.06)
                        )
                        .rotationEffect(.degrees(Double(i - 2) * 8))
                }
            }
            .padding(.trailing, -30)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Camera overlay elements

private struct CameraOverlay: View {
    @Binding var fishDetected: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 64)

            Spacer()

            ScanningReticle()
                .frame(width: 220, height: 178)

            Spacer()

            bottomControls
                .padding(.horizontal, 20)
                .padding(.bottom, 52)
        }
    }

    private var topBar: some View {
        HStack {
            ContextChip()
            Spacer()
            SettingsButton()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 18) {
            if fishDetected {
                FishDetectedBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            CaptureButton {
                withAnimation(.spring(response: 0.35)) {
                    fishDetected.toggle()
                }
            }
        }
    }
}

// MARK: - Context chip (time + biome)

private struct ContextChip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("TIME: MIDDAY", systemImage: "sun.max.fill")
            Label("FRESHWATER", systemImage: "water.waves")
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Settings button

private struct SettingsButton: View {
    var body: some View {
        Button {} label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scanning reticle (corner-bracket style)

private struct ScanningReticle: View {
    private let cornerLength: CGFloat = 30
    private let lineWidth: CGFloat  = 3

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { p in
                    // Top-left
                    p.move(to: .init(x: 0,           y: cornerLength))
                    p.addLine(to: .init(x: 0,         y: 0))
                    p.addLine(to: .init(x: cornerLength, y: 0))
                    // Top-right
                    p.move(to: .init(x: w - cornerLength, y: 0))
                    p.addLine(to: .init(x: w,         y: 0))
                    p.addLine(to: .init(x: w,         y: cornerLength))
                    // Bottom-left
                    p.move(to: .init(x: 0,           y: h - cornerLength))
                    p.addLine(to: .init(x: 0,         y: h))
                    p.addLine(to: .init(x: cornerLength, y: h))
                    // Bottom-right
                    p.move(to: .init(x: w - cornerLength, y: h))
                    p.addLine(to: .init(x: w,         y: h))
                    p.addLine(to: .init(x: w,         y: h - cornerLength))
                }
                .stroke(Color.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))

                // Horizontal centre line
                Path { p in
                    p.move(to:    .init(x: 0,   y: h / 2))
                    p.addLine(to: .init(x: w,   y: h / 2))
                }
                .stroke(Color.white.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
            }

            Image(systemName: "fish.hook")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.white.opacity(0.90))
        }
    }
}

// MARK: - Fish detected banner

private struct FishDetectedBanner: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("! FISH DETECTED !")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(FishedexTheme.headerRed)
                .frame(maxWidth: .infinity, alignment: .center)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.86, green: 0.86, blue: 0.87))

                    Capsule()
                        .fill(FishedexTheme.progressGreen)
                        .frame(width: geo.size.width * 0.42)
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Capture button

private struct CaptureButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.20, green: 0.20, blue: 0.20).opacity(0.72))
                    .frame(width: 76, height: 76)

                Circle()
                    .fill(FishedexTheme.coral)
                    .frame(width: 62, height: 62)

                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

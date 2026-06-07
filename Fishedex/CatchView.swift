import SwiftUI
import AVFoundation

// MARK: - Catch Screen

struct CatchView: View {
    let onBack: () -> Void

    @StateObject private var camera          = CameraManager()
    @StateObject private var locationWeather = LocationWeatherManager()
    @State private var fishDetected  = false
    @State private var showCapture   = false

    var body: some View {
        ZStack {
            // Camera feed fills the full screen including safe areas
            cameraLayer
                .ignoresSafeArea()

            // White flash on shutter
            Color.white
                .opacity(camera.flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // HUD — respects safe areas so parent layout stays intact
            CameraHUD(
                camera: camera,
                locationWeather: locationWeather,
                fishDetected: $fishDetected,
                showCapture: $showCapture,
                onBack: onBack,
                onCapture: {
                    camera.capturePhoto()
                    withAnimation(.spring(response: 0.4)) { showCapture = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation { fishDetected = true }
                    }
                }
            )
        }
        .onAppear {
            camera.requestAndSetup()
            locationWeather.start()
        }
        .onDisappear {
            camera.stopSession()
            locationWeather.stop()
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        if camera.permission == .denied {
            PermissionDeniedBackground()
        } else {
            CameraPreviewLayer(session: camera.session)
        }
    }
}

// MARK: - Permission denied fallback

private struct PermissionDeniedBackground: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "camera.slash.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.6))
                Text("CAMERA ACCESS REQUIRED")
                    .font(FishedexFont.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .kerning(1)
                Text("Enable in Settings → Fishedex")
                    .font(FishedexFont.body)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }
}

// MARK: - HUD overlay

private struct CameraHUD: View {
    @ObservedObject var camera: CameraManager
    @ObservedObject var locationWeather: LocationWeatherManager
    @Binding var fishDetected: Bool
    @Binding var showCapture: Bool
    let onBack: () -> Void
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer()

            ScanningReticle(active: camera.isCapturing || showCapture)
                .frame(width: 230, height: 185)

            Spacer()

            bottomControls
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: 10) {
            FishedexBackButton(action: onBack, style: .overlay, size: 44, iconSize: 17)

            Spacer()

            ContextChip(manager: locationWeather)

            Spacer()

            // Captured photo thumbnail — otherwise invisible spacer to keep chip centred
            if let img = camera.capturedImage {
                CapturedThumb(image: img)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }

    // MARK: Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            if fishDetected {
                FishDetectedBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            VStack(spacing: 8) {
                PixelFishingRodButton(isCapturing: camera.isCapturing, action: onCapture)
                Text("CATCH")
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
            }
        }
    }
}

// MARK: - Captured photo thumbnail

private struct CapturedThumb: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .fishedexSquare()
            .fishedexBorder()
    }
}

// MARK: - Context chip (real time + weather)

private struct ContextChip: View {
    @ObservedObject var manager: LocationWeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(manager.timeLabel,    systemImage: manager.timeIcon)
            Label(manager.weatherLabel, systemImage: manager.weatherIcon)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(.black.opacity(0.65))
        .fishedexSquare()
        .fishedexBorder()
    }
}

// MARK: - Scanning reticle

private struct ScanningReticle: View {
    let active: Bool
    private let cornerLength: CGFloat = 28
    private let lineWidth: CGFloat    = 3

    @State private var scanY: CGFloat = 0
    @State private var pulse          = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { p in
                    p.move(to: .init(x: 0, y: cornerLength)); p.addLine(to: .init(x: 0, y: 0)); p.addLine(to: .init(x: cornerLength, y: 0))
                    p.move(to: .init(x: w - cornerLength, y: 0)); p.addLine(to: .init(x: w, y: 0)); p.addLine(to: .init(x: w, y: cornerLength))
                    p.move(to: .init(x: 0, y: h - cornerLength)); p.addLine(to: .init(x: 0, y: h)); p.addLine(to: .init(x: cornerLength, y: h))
                    p.move(to: .init(x: w - cornerLength, y: h)); p.addLine(to: .init(x: w, y: h)); p.addLine(to: .init(x: w, y: h - cornerLength))
                }
                .stroke(active ? Color.green : Color.red,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))

                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, (active ? Color.green : Color.red).opacity(0.6), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 2)
                    .offset(y: scanY * h)
                    .animation(.linear(duration: 1.6).repeatForever(autoreverses: true), value: scanY)
            }

            Image(systemName: "fish.hook")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .scaleEffect(pulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { scanY = 1; pulse = true }
    }
}

// MARK: - Fish detected banner

private struct FishDetectedBanner: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("! FISH DETECTED !")
                .font(FishedexFont.title2)
                .foregroundStyle(FishedexTheme.headerRed)
                .kerning(1)
                .frame(maxWidth: .infinity, alignment: .center)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                    Rectangle()
                        .fill(FishedexTheme.progressGreen)
                        .frame(width: geo.size.width * 0.42)
                }
            }
            .frame(height: 10)

            Text("SCANNING DATABASE...")
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.95))
        .fishedexSquare()
        .fishedexBorder()
    }
}

// MARK: - Catch button

private struct PixelFishingRodButton: View {
    let isCapturing: Bool
    let action: () -> Void

    private let size: CGFloat = 96

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.white.opacity(isCapturing ? 0.12 : 0.22)

                Image("PixelFishingRod")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(size * 0.16)
            }
            .frame(width: size, height: size)
            .fishedexCircle()
            .fishedexCircleBorder(lineWidth: 2, color: .black)
        }
        .buttonStyle(.plain)
        .disabled(isCapturing)
        .scaleEffect(isCapturing ? 0.90 : 1.0)
        .animation(.easeInOut(duration: 0.10), value: isCapturing)
    }
}

// MARK: - Preview

#Preview {
    CatchView(onBack: {})
}

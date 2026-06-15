import SwiftUI
import AVFoundation
import ARKit

private enum CatchPhase {
    case measuring
    case camera
    case scanning
    case success
}

private struct CatchSuccessPayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let caughtAt: Date
    let detectionResult: FishDetectionResult?
    let measuredLengthCm: Double?
}

// MARK: - Catch Screen

struct CatchView: View {
    @EnvironmentObject private var session: SessionManager

    let onBack: () -> Void
    var onCatchLogged: () -> Void = {}

    @StateObject private var camera           = CameraManager()
    @StateObject private var locationWeather  = LocationWeatherManager()
    @StateObject private var measureController = FishMeasureController()
    @State private var phase: CatchPhase      = .measuring
    @State private var showCapture            = false
    @State private var scanProgress: CGFloat  = 0
    @State private var caughtAt               = Date()
    @State private var scanTask: Task<Void, Never>?
    @State private var detectionResult: FishDetectionResult?
    @State private var measuredLengthCm: Double?
    @State private var showMeasureAR = true
    @State private var scanImage: UIImage?
    @State private var successPayload: CatchSuccessPayload?

    private let minimumScanDuration: TimeInterval = 2
    private let fallbackScanDuration: TimeInterval = 4

    var body: some View {
        ZStack {
            captureLayer
                .ignoresSafeArea()

            Color.white
                .opacity(camera.flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if phase == .measuring {
                MeasureHUD(
                    measureController: measureController,
                    locationWeather: locationWeather,
                    onBack: onBack,
                    onSkip: advanceToCamera,
                    onContinue: advanceToCamera
                )
            } else {
                CameraHUD(
                    camera: camera,
                    locationWeather: locationWeather,
                    phase: phase,
                    showCapture: showCapture,
                    scanProgress: scanProgress,
                    onBack: handleBack,
                    onCapture: captureFish
                )
            }
        }
        .fullScreenCover(item: $successPayload, onDismiss: resetCatchFlow) { payload in
            CatchSuccessView(
                capturedImage: payload.image,
                initialLocationName: locationWeather.locationName,
                initialCoordinate: locationWeather.userCoordinate,
                caughtAt: payload.caughtAt,
                detectionResult: payload.detectionResult,
                measuredLengthCm: payload.measuredLengthCm,
                onFinished: {
                    successPayload = nil
                    resetCatchFlow()
                    onCatchLogged()
                }
            )
            .environmentObject(session)
        }
        .onAppear {
            locationWeather.start()
            camera.preparePermission()
            if phase == .camera {
                camera.requestAndSetup()
            }
        }
        .onDisappear {
            scanTask?.cancel()
            camera.stopSession()
            locationWeather.stop()
        }
    }

    @ViewBuilder
    private var captureLayer: some View {
        if phase == .measuring && showMeasureAR {
            if ARWorldTrackingConfiguration.isSupported {
                FishMeasureARView(controller: measureController)
            } else {
                FishMeasureUnavailableView()
            }
        } else if phase == .measuring {
            Color.black
        } else if phase == .scanning || phase == .success, let image = scanImage ?? camera.capturedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if camera.permission == .denied {
            PermissionDeniedBackground()
        } else {
            CameraPreviewLayer(session: camera.session)
        }
    }

    private func advanceToCamera() {
        measuredLengthCm = measureController.lengthCm
        measureController.stopSession()
        showMeasureAR = false
        phase = .camera
        camera.requestAndSetup(releaseDelay: 0.05)
    }

    private func captureFish() {
        guard phase == .camera else { return }

        camera.capturePhoto { image in
            guard let image else { return }

            scanImage = image
            caughtAt = Date()
            withAnimation(.spring(response: 0.4)) { showCapture = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation { phase = .scanning }
                startScanning(image: image)
            }
        }
    }

    private func startScanning(image: UIImage) {
        scanProgress = 0
        detectionResult = nil
        scanTask?.cancel()

        let usesAI = session.isAiFishDetectionEnabled

        scanTask = Task {
            let startedAt = Date()
            var aiResult: FishDetectionResult?

            if usesAI {
                do {
                    aiResult = try await session.classifyFish(image: image)
                } catch {
                    // Keep the catch flow moving even if classification fails.
                    print("Fish classification failed:", error.localizedDescription)
                }
            }

            let elapsed = Date().timeIntervalSince(startedAt)
            let targetDuration = usesAI
                ? max(minimumScanDuration, elapsed)
                : fallbackScanDuration
            let remaining = max(0, targetDuration - elapsed)

            if remaining > 0 {
                let steps = 20
                let stepNanos = UInt64(remaining / Double(steps) * 1_000_000_000)

                for step in 1...steps {
                    try? await Task.sleep(nanoseconds: stepNanos)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        let animationProgress = CGFloat(step) / CGFloat(steps)
                        scanProgress = usesAI && aiResult != nil
                            ? min(1, 0.7 + animationProgress * 0.3)
                            : animationProgress
                    }
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                detectionResult = aiResult
                scanProgress = 1
                camera.stopSession()
                successPayload = CatchSuccessPayload(
                    image: image,
                    caughtAt: caughtAt,
                    detectionResult: aiResult,
                    measuredLengthCm: measuredLengthCm
                )
                withAnimation { phase = .success }
            }
        }
    }

    private func handleBack() {
        guard phase != .scanning else { return }
        if phase == .success {
            successPayload = nil
            resetCatchFlow()
        } else if phase == .camera {
            camera.stopSession()
            camera.capturedImage = nil
            scanImage = nil
            showMeasureAR = true
            phase = .measuring
        } else {
            onBack()
        }
    }

    private func resetCatchFlow() {
        scanTask?.cancel()
        scanTask = nil
        scanProgress = 0
        detectionResult = nil
        measuredLengthCm = nil
        measureController.requestReset()
        showCapture = false
        showMeasureAR = true
        phase = .measuring
        successPayload = nil
        scanImage = nil
        camera.capturedImage = nil
        camera.stopSession()
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

// MARK: - Measure HUD

private struct MeasureHUD: View {
    @ObservedObject var measureController: FishMeasureController
    @ObservedObject var locationWeather: LocationWeatherManager
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                FishedexBackButton(action: onBack, style: .overlay)
                Spacer()
                ContextChip(manager: locationWeather)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            MeasureReticle(surfaceReady: measureController.surfaceDetected)
                .frame(width: 230, height: 185)

            if let lengthCm = measureController.lengthCm {
                Text(String(format: "%.1f cm", lengthCm))
                    .font(FishedexFont.pokemon(28))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.65))
                    .fishedexSquare()
                    .fishedexBorder()
                    .padding(.top, 16)
            }

            Spacer()

            VStack(spacing: 12) {
                Text(measureController.instructionText.uppercased())
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    if measureController.pointCount > 0 {
                        Button(action: measureController.requestReset) {
                            Text("RESET")
                                .font(FishedexFont.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.black.opacity(0.55))
                                .fishedexSquare()
                                .fishedexBorder()
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: measureController.isMeasurementComplete ? onContinue : onSkip) {
                        Text(measureController.isMeasurementComplete ? "TAKE PHOTO" : "SKIP")
                            .font(FishedexFont.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(measureController.isMeasurementComplete ? FishedexTheme.tabGreen : FishedexTheme.tabBlue)
                            .fishedexSquare()
                            .fishedexBorder()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct MeasureReticle: View {
    let surfaceReady: Bool
    private let cornerLength: CGFloat = 28
    private let lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let color = surfaceReady ? Color.yellow : Color.white.opacity(0.7)

                Path { p in
                    p.move(to: .init(x: 0, y: cornerLength)); p.addLine(to: .init(x: 0, y: 0)); p.addLine(to: .init(x: cornerLength, y: 0))
                    p.move(to: .init(x: w - cornerLength, y: 0)); p.addLine(to: .init(x: w, y: 0)); p.addLine(to: .init(x: w, y: cornerLength))
                    p.move(to: .init(x: 0, y: h - cornerLength)); p.addLine(to: .init(x: 0, y: h)); p.addLine(to: .init(x: cornerLength, y: h))
                    p.move(to: .init(x: w - cornerLength, y: h)); p.addLine(to: .init(x: w, y: h)); p.addLine(to: .init(x: w, y: h - cornerLength))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))
            }

            Image(systemName: "ruler")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - HUD overlay

private struct CameraHUD: View {
    @ObservedObject var camera: CameraManager
    @ObservedObject var locationWeather: LocationWeatherManager
    let phase: CatchPhase
    let showCapture: Bool
    let scanProgress: CGFloat
    let onBack: () -> Void
    let onCapture: () -> Void

    private var isScanning: Bool { phase == .scanning }

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

    private var topBar: some View {
        HStack(alignment: .center, spacing: 10) {
            FishedexBackButton(action: onBack, style: .overlay)
                .opacity(isScanning ? 0.35 : 1)
                .disabled(isScanning)

            Spacer()

            ContextChip(manager: locationWeather)

            Spacer()

            if let img = camera.capturedImage {
                CapturedThumb(image: img)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            if isScanning {
                FishDetectedBanner(progress: scanProgress)
                    .frame(maxWidth: 288)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if phase == .camera {
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
}

// MARK: - Captured photo thumbnail

private struct CapturedThumb: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 32, height: 32)
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
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("! FISH DETECTED !")
                .font(FishedexFont.title2)
                .foregroundStyle(FishedexTheme.headerRed)
                .kerning(1)
                .multilineTextAlignment(.center)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(red: 0.86, green: 0.86, blue: 0.87))
                    Rectangle()
                        .fill(FishedexTheme.progressGreen)
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                        .animation(.linear(duration: 0.08), value: progress)
                }
            }
            .frame(height: 10)

            Text(progress >= 1 ? "IDENTIFIED!" : progress >= 0.7 ? "MATCHING SPECIES..." : "ANALYZING FISH...")
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
        .environmentObject(SessionManager())
}

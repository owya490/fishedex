import SwiftUI
import AVFoundation
import ARKit

private enum CatchPhase {
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

    var fishingSpot: FishingSpot? = nil
    let onBack: () -> Void
    var onCatchLogged: () -> Void = {}

    @AppStorage("catchMeasuringEnabled") private var isMeasuringEnabled = true

    @StateObject private var camera           = CameraManager()
    @StateObject private var locationWeather  = LocationWeatherManager()
    @StateObject private var measureController = FishMeasureController()
    @State private var phase: CatchPhase      = .camera
    @State private var showCapture            = false
    @State private var scanProgress: CGFloat  = 0
    @State private var caughtAt               = Date()
    @State private var scanTask: Task<Void, Never>?
    @State private var detectionResult: FishDetectionResult?
    @State private var measuredLengthCm: Double?
    @State private var scanImage: UIImage?
    @State private var successPayload: CatchSuccessPayload?
    @State private var isCapturing = false

    private var usesARMeasuring: Bool {
        isMeasuringEnabled && ARWorldTrackingConfiguration.isSupported
    }

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

            CatchHUD(
                camera: camera,
                measureController: measureController,
                locationWeather: locationWeather,
                fishingSpot: fishingSpot,
                phase: phase,
                isMeasuringEnabled: $isMeasuringEnabled,
                isCapturing: isCapturing || camera.isCapturing,
                showCapture: showCapture,
                scanProgress: scanProgress,
                scanImage: scanImage,
                onBack: handleBack,
                onCapture: captureFish,
                onResetMeasure: measureController.requestReset
            )
        }
        .fullScreenCover(item: $successPayload, onDismiss: resetCatchFlow) { payload in
            CatchSuccessView(
                capturedImage: payload.image,
                initialLocationName: fishingSpot?.name ?? locationWeather.locationName,
                initialCoordinate: fishingSpot?.coordinate ?? locationWeather.userCoordinate,
                caughtAt: payload.caughtAt,
                detectionResult: payload.detectionResult,
                measuredLengthCm: payload.measuredLengthCm,
                fishingSpot: fishingSpot,
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
            syncCaptureSource()
        }
        .onDisappear {
            scanTask?.cancel()
            camera.stopSession()
            measureController.stopSession()
            locationWeather.stop()
        }
        .onChange(of: isMeasuringEnabled) { _, _ in
            guard phase == .camera else { return }
            syncCaptureSource()
        }
    }

    @ViewBuilder
    private var captureLayer: some View {
        if phase == .scanning || phase == .success, let image = scanImage ?? camera.capturedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if usesARMeasuring {
            FishMeasureARView(controller: measureController)
        } else if isMeasuringEnabled {
            FishMeasureUnavailableView()
        } else if camera.permission == .denied {
            PermissionDeniedBackground()
        } else {
            CameraPreviewLayer(session: camera.session)
        }
    }

    private func syncCaptureSource() {
        if usesARMeasuring {
            camera.stopSession()
            measureController.requestReset()
        } else {
            measureController.stopSession()
            camera.requestAndSetup()
        }
    }

    private func captureFish() {
        guard phase == .camera, !isCapturing else { return }

        isCapturing = true

        if usesARMeasuring {
            triggerCaptureFlash()
            measureController.capturePhoto { image in
                isCapturing = false
                guard let image else { return }
                processCapture(image: image, lengthCm: measureController.lengthCm)
            }
        } else {
            camera.capturePhoto { image in
                isCapturing = false
                guard let image else { return }
                processCapture(image: image, lengthCm: nil)
            }
        }
    }

    private func triggerCaptureFlash() {
        withAnimation(.easeIn(duration: 0.05)) { camera.flashOpacity = 1 }
        withAnimation(.easeOut(duration: 0.35).delay(0.05)) { camera.flashOpacity = 0 }
    }

    private func processCapture(image: UIImage, lengthCm: Double?) {
        measuredLengthCm = lengthCm
        scanImage = image
        caughtAt = Date()
        withAnimation(.spring(response: 0.4)) { showCapture = true }

        if usesARMeasuring {
            measureController.stopSession()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation { phase = .scanning }
            startScanning(image: image)
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
        isCapturing = false
        phase = .camera
        successPayload = nil
        scanImage = nil
        camera.capturedImage = nil
        syncCaptureSource()
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

// MARK: - Unified HUD

private struct CatchHUD: View {
    @ObservedObject var camera: CameraManager
    @ObservedObject var measureController: FishMeasureController
    @ObservedObject var locationWeather: LocationWeatherManager
    var fishingSpot: FishingSpot? = nil
    let phase: CatchPhase
    @Binding var isMeasuringEnabled: Bool
    let isCapturing: Bool
    let showCapture: Bool
    let scanProgress: CGFloat
    let scanImage: UIImage?
    let onBack: () -> Void
    let onCapture: () -> Void
    let onResetMeasure: () -> Void

    @State private var showSettings = false

    private var isScanning: Bool { phase == .scanning }
    private var showsMeasureUI: Bool {
        isMeasuringEnabled && ARWorldTrackingConfiguration.isSupported && phase == .camera
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if let fishingSpot, phase == .camera {
                FishingSpotCatchBanner(spot: fishingSpot)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            Spacer()

            if showsMeasureUI, let lengthCm = measureController.lengthCm {
                Text(String(format: "%.1f cm", lengthCm))
                    .font(FishedexFont.pokemon(28))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.65))
                    .fishedexSquare()
                    .fishedexBorder()
                    .padding(.bottom, 12)
            }

            if showsMeasureUI {
                MeasureReticle(surfaceReady: measureController.surfaceDetected)
                    .frame(width: 230, height: 185)
            } else {
                ScanningReticle(active: isCapturing || showCapture)
                    .frame(width: 230, height: 185)
            }

            Spacer()

            bottomControls
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .sheet(isPresented: $showSettings) {
            CatchSettingsSheet(isMeasuringEnabled: $isMeasuringEnabled)
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

            if let image = scanImage ?? camera.capturedImage {
                CapturedThumb(image: image)
            } else {
                CatchSettingsButton(isDisabled: isScanning) {
                    showSettings = true
                }
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
                    if showsMeasureUI {
                        HStack(spacing: 12) {
                            Text(measureController.instructionText.uppercased())
                                .font(FishedexFont.subheadline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
                                .frame(maxWidth: .infinity)

                            if measureController.pointCount > 0 {
                                Button(action: onResetMeasure) {
                                    Text("RESET")
                                        .font(FishedexFont.caption)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.black.opacity(0.55))
                                        .fishedexSquare()
                                        .fishedexBorder()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    PixelFishingRodButton(isCapturing: isCapturing, action: onCapture)
                    Text("CATCH")
                        .font(FishedexFont.subheadline)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 1)
                }
            }
        }
    }
}

// MARK: - Catch settings

private struct CatchSettingsButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.black.opacity(0.65))
                .fishedexSquare()
                .fishedexBorder()
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.35 : 1)
        .disabled(isDisabled)
    }
}

private struct CatchSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isMeasuringEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CATCH SETTINGS")
                    .font(FishedexFont.title)
                    .foregroundStyle(FishedexTheme.ink)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FishedexTheme.ink)
                        .frame(width: 28, height: 28)
                        .background(FishedexTheme.progressTrack)
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "ruler")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FishedexTheme.tabBlue)
                        .frame(width: 36, height: 36)
                        .background(FishedexTheme.tabBlue.opacity(0.12))
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("MEASURE FISH")
                            .font(FishedexFont.headline)
                            .foregroundStyle(FishedexTheme.ink)

                        Text("Use AR to measure length before catching")
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.muted)
                    }

                    Spacer(minLength: 8)

                    FishedexPixelToggle(isOn: $isMeasuringEnabled)
                }
                .padding(16)
            }
            .background(Color.white)
            .fishedexSquare()
            .fishedexBorder()
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
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

private struct FishingSpotCatchBanner: View {
    let spot: FishingSpot

    var body: some View {
        HStack(spacing: 10) {
            FishingSpotSceneImageView(scene: spot.scene)
                .frame(width: 32, height: 32)
                .clipped()
                .fishedexBorder(lineWidth: 1, color: .white.opacity(0.35))

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name.uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(.white)
                    .kerning(0.5)
                Text(spot.biomeLabel.uppercased())
                    .font(FishedexFont.micro)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.65))
        .fishedexSquare()
        .fishedexBorder()
    }
}

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

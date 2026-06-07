import AVFoundation
import SwiftUI

// MARK: - Camera permission state

enum CameraPermission {
    case unknown, granted, denied
}

// MARK: - Camera Manager

final class CameraManager: NSObject, ObservableObject {

    // Published state the UI binds to
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var permission: CameraPermission = .unknown
    @Published var flashOpacity: Double = 0

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)
    private var isConfigured = false

    // MARK: Setup

    func requestAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permission = .granted }
            configureSessionIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permission = granted ? .granted : .denied
                }
                if granted { self.configureSessionIfNeeded() }
            }
        default:
            DispatchQueue.main.async { self.permission = .denied }
        }
    }

    private func configureSessionIfNeeded() {
        sessionQueue.async {
            if self.isConfigured {
                self.startRunningIfNeeded()
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            self.isConfigured = true
            self.startRunningIfNeeded()
        }
    }

    func startSession() {
        sessionQueue.async {
            self.startRunningIfNeeded()
        }
    }

    private func startRunningIfNeeded() {
        guard isConfigured, !session.isRunning else { return }
        session.startRunning()
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // MARK: Capture

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true

        // Flash white overlay
        withAnimation(.easeIn(duration: 0.05)) { flashOpacity = 1 }
        withAnimation(.easeOut(duration: 0.35).delay(0.05)) { flashOpacity = 0 }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        defer { DispatchQueue.main.async { self.isCapturing = false } }
        guard error == nil, let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.capturedImage = image }
    }
}

// MARK: - UIKit camera preview layer (UIViewRepresentable)

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    // UIView subclass so the layer resizes automatically
    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

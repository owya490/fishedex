import ARKit
import RealityKit
import SwiftUI
import UIKit

// MARK: - Measurement state

final class FishMeasureController: ObservableObject {
    @Published var lengthCm: Double?
    @Published var pointCount = 0
    @Published var surfaceDetected = false
    @Published var instructionText = "Move iPhone slowly over a flat surface"
    @Published private(set) var resetToken = UUID()

    var isMeasurementComplete: Bool { lengthCm != nil }
    var stopSessionHandler: (() -> Void)?

    /// Pause AR immediately so AVCapture can take the camera without waiting for view teardown.
    func stopSession() {
        stopSessionHandler?()
        stopSessionHandler = nil
    }

    func requestReset() {
        lengthCm = nil
        pointCount = 0
        resetToken = UUID()
        refreshInstruction()
    }

    fileprivate func apply(pointCount: Int, lengthCm: Double?) {
        self.pointCount = pointCount
        self.lengthCm = lengthCm
        refreshInstruction()
    }

    fileprivate func setSurfaceDetected(_ detected: Bool) {
        guard surfaceDetected != detected else { return }
        surfaceDetected = detected
        refreshInstruction()
    }

    private func refreshInstruction() {
        if !surfaceDetected {
            instructionText = "Move iPhone slowly over a flat surface"
        } else if pointCount == 0 {
            instructionText = "Tap the nose of the fish"
        } else if pointCount == 1 {
            instructionText = "Tap the tail of the fish"
        } else if let lengthCm {
            instructionText = String(format: "%.1f cm — tap to measure again", lengthCm)
        } else {
            instructionText = "Tap two points to measure"
        }
    }
}

// MARK: - AR measurement view

struct FishMeasureARView: UIViewRepresentable {
    @ObservedObject var controller: FishMeasureController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        arView.session.delegate = context.coordinator
        context.coordinator.configureSession(on: arView)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        context.coordinator.attach(to: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.syncResetIfNeeded(on: uiView)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.detach(from: uiView)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {
        private let controller: FishMeasureController
        private var worldPoints: [SIMD3<Float>] = []
        private var pointEntities: [AnchorEntity] = []
        private var lineEntity: AnchorEntity?
        private var lastResetToken: UUID?
        private var hasReportedSurface = false
        weak var arView: ARView?

        init(controller: FishMeasureController) {
            self.controller = controller
            self.lastResetToken = controller.resetToken
        }

        func attach(to arView: ARView) {
            self.arView = arView
            controller.stopSessionHandler = { [weak self] in
                self?.pauseSession()
            }
            configureSession(on: arView)
        }

        func detach(from arView: ARView) {
            pauseSession(on: arView)
            if self.arView === arView {
                self.arView = nil
            }
            if controller.stopSessionHandler != nil {
                controller.stopSessionHandler = nil
            }
        }

        func configureSession(on arView: ARView) {
            guard ARWorldTrackingConfiguration.isSupported else { return }

            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        private func pauseSession(on arView: ARView? = nil) {
            let view = arView ?? self.arView
            guard let view else { return }
            view.session.delegate = nil
            view.session.pause()
            clearVisuals()
            worldPoints.removeAll()
            hasReportedSurface = false
        }

        func syncResetIfNeeded(on arView: ARView) {
            guard controller.resetToken != lastResetToken else { return }
            lastResetToken = controller.resetToken
            clearVisuals()
            worldPoints.removeAll()
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = recognizer.location(in: arView)
            guard let result = raycast(at: location, in: arView) else { return }

            let position = simd_make_float3(result.worldTransform.columns.3)

            if worldPoints.count >= 2 {
                clearVisuals()
                worldPoints.removeAll()
            }

            worldPoints.append(position)
            addDot(at: position, in: arView)

            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            if worldPoints.count == 2 {
                let meters = simd_distance(worldPoints[0], worldPoints[1])
                let cm = Double(meters * 100)
                addLine(from: worldPoints[0], to: worldPoints[1], in: arView)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { @MainActor in
                    controller.apply(pointCount: 2, lengthCm: cm)
                }
            } else {
                Task { @MainActor in
                    controller.apply(pointCount: worldPoints.count, lengthCm: nil)
                }
            }
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard anchors.contains(where: { $0 is ARPlaneAnchor }) else { return }
            reportSurfaceDetectedIfNeeded()
        }

        private func reportSurfaceDetectedIfNeeded() {
            guard !hasReportedSurface else { return }
            hasReportedSurface = true
            DispatchQueue.main.async { [controller] in
                controller.setSurfaceDetected(true)
            }
        }

        private func raycast(at point: CGPoint, in arView: ARView) -> ARRaycastResult? {
            let attempts: [(ARRaycastQuery.Target, ARRaycastQuery.TargetAlignment)] = [
                (.existingPlaneGeometry, .horizontal),
                (.estimatedPlane, .horizontal),
                (.existingPlaneGeometry, .any),
            ]

            for (target, alignment) in attempts {
                if let hit = arView.raycast(from: point, allowing: target, alignment: alignment).first {
                    return hit
                }
            }
            return nil
        }

        private func addDot(at position: SIMD3<Float>, in arView: ARView) {
            let mesh = MeshResource.generateSphere(radius: 0.006)
            let material = SimpleMaterial(color: .yellow, isMetallic: false)
            let model = ModelEntity(mesh: mesh, materials: [material])

            let anchor = AnchorEntity(world: position)
            anchor.addChild(model)
            arView.scene.addAnchor(anchor)
            pointEntities.append(anchor)
        }

        private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, in arView: ARView) {
            let distance = simd_distance(start, end)
            guard distance > 0.001 else { return }

            let midpoint = (start + end) / 2
            let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.003, 0.003, distance))
            let material = SimpleMaterial(color: .white, isMetallic: false)
            let model = ModelEntity(mesh: mesh, materials: [material])

            let anchor = AnchorEntity(world: midpoint)
            anchor.look(at: end, from: midpoint, relativeTo: nil)
            anchor.addChild(model)
            arView.scene.addAnchor(anchor)
            lineEntity = anchor
        }

        private func clearVisuals() {
            pointEntities.forEach { $0.removeFromParent() }
            pointEntities.removeAll()
            lineEntity?.removeFromParent()
            lineEntity = nil
        }
    }
}

// MARK: - Unsupported fallback

struct FishMeasureUnavailableView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "arkit")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))
                Text("AR MEASURE UNAVAILABLE")
                    .font(FishedexFont.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .kerning(1)
                Text("Use a physical iPhone to measure fish length")
                    .font(FishedexFont.body)
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

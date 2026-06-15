import ARKit
import CoreImage
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
    @Published private(set) var captureToken = UUID()

    var isMeasurementComplete: Bool { lengthCm != nil }
    var stopSessionHandler: (() -> Void)?
    fileprivate var captureCompletion: ((UIImage?) -> Void)?

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

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        captureToken = UUID()
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
        context.coordinator.syncCaptureIfNeeded(on: uiView)
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
        private var lastCaptureToken: UUID?
        private var hasReportedSurface = false
        weak var arView: ARView?

        init(controller: FishMeasureController) {
            self.controller = controller
            self.lastResetToken = controller.resetToken
            self.lastCaptureToken = controller.captureToken
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

        func syncCaptureIfNeeded(on arView: ARView) {
            guard controller.captureToken != lastCaptureToken else { return }
            lastCaptureToken = controller.captureToken

            let completion = controller.captureCompletion
            controller.captureCompletion = nil

            guard let frame = arView.session.currentFrame else {
                DispatchQueue.main.async { completion?(nil) }
                return
            }

            let image = Self.image(from: frame.capturedImage)
            DispatchQueue.main.async { completion?(image) }
        }

        private static func image(from pixelBuffer: CVPixelBuffer) -> UIImage? {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return UIImage(cgImage: cgImage, scale: 1, orientation: .right)
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
            addPin(at: position, in: arView)

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

        private func addPin(at position: SIMD3<Float>, in arView: ARView) {
            let anchor = AnchorEntity(world: position)
            anchor.addChild(MeasureVisuals.makePixelPin())
            arView.scene.addAnchor(anchor)
            pointEntities.append(anchor)
        }

        private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, in arView: ARView) {
            guard let line = MeasureVisuals.makeLine(from: start, to: end) else { return }
            arView.scene.addAnchor(line)
            lineEntity = line
        }

        private func clearVisuals() {
            pointEntities.forEach { $0.removeFromParent() }
            pointEntities.removeAll()
            lineEntity?.removeFromParent()
            lineEntity = nil
        }
    }
}

// MARK: - AR measure visuals

private enum MeasureVisuals {
  private static let voxelSize: Float = 0.005
  private static let lineThickness: Float = 0.004
  private static let surfaceLift: Float = 0.0015

  private static let pinFill = UIColor(red: 1.0, green: 0.90, blue: 0.18, alpha: 1)
  private static let pinBorder = UIColor.black
  private static let lineFill = UIColor.white
  private static let lineBorder = UIColor.black

  /// Map-pin silhouette adapted from the tab bar icon, centered on X with the tip at y = 0.
  private static let pinVoxels: Set<SIMD2<Int32>> = [
    SIMD2(0, 0),
    SIMD2(0, 1),
    SIMD2(0, 2),
    SIMD2(-1, 3), SIMD2(0, 3), SIMD2(1, 3),
    SIMD2(-1, 4), SIMD2(0, 4), SIMD2(1, 4),
    SIMD2(-2, 5), SIMD2(-1, 5), SIMD2(0, 5), SIMD2(1, 5), SIMD2(2, 5),
    SIMD2(-1, 6), SIMD2(0, 6), SIMD2(1, 6),
    SIMD2(0, 7),
  ]

  static func makePixelPin() -> Entity {
    let root = Entity()
    let borderVoxels = pinBorderVoxels3D()

    for z in -1...1 {
      for coord in pinVoxels {
        let voxel = SIMD3<Int32>(coord.x, coord.y, Int32(z))
        let color = borderVoxels.contains(voxel) ? pinBorder : pinFill
        root.addChild(voxelEntity(at: voxel, color: color))
      }
    }

    return root
  }

  static func makeLine(from start: SIMD3<Float>, to end: SIMD3<Float>) -> AnchorEntity? {
    var a = start
    var b = end
    a.y += surfaceLift
    b.y += surfaceLift

    let delta = b - a
    let length = simd_length(delta)
    guard length > 0.001 else { return nil }

    let midpoint = (a + b) * 0.5
    let direction = delta / length
    let orientation = rotationAligningZAxis(to: direction)

    let anchor = AnchorEntity(world: midpoint)
    anchor.orientation = orientation
    anchor.addChild(lineSegment(length: length, thickness: lineThickness + 0.0015, color: lineBorder))
    anchor.addChild(lineSegment(length: length, thickness: lineThickness, color: lineFill))
    return anchor
  }

  private static func pinBorderVoxels3D() -> Set<SIMD3<Int32>> {
    var solids = Set<SIMD3<Int32>>()
    for z in -1...1 {
      for coord in pinVoxels {
        solids.insert(SIMD3(coord.x, coord.y, Int32(z)))
      }
    }

    var border = Set<SIMD3<Int32>>()
    let neighbors = [
      SIMD3<Int32>(1, 0, 0), SIMD3<Int32>(-1, 0, 0),
      SIMD3<Int32>(0, 1, 0), SIMD3<Int32>(0, -1, 0),
      SIMD3<Int32>(0, 0, 1), SIMD3<Int32>(0, 0, -1),
    ]

    for voxel in solids {
      let isBorder = neighbors.contains { offset in
        !solids.contains(voxel &+ offset)
      }
      if isBorder { border.insert(voxel) }
    }
    return border
  }

  private static func voxelEntity(at coord: SIMD3<Int32>, color: UIColor) -> ModelEntity {
    let inset = voxelSize * 0.9
    let mesh = MeshResource.generateBox(size: SIMD3(repeating: inset))
    let material = SimpleMaterial(color: color, isMetallic: false)
    let model = ModelEntity(mesh: mesh, materials: [material])
    model.position = SIMD3(
      Float(coord.x) * voxelSize,
      Float(coord.y) * voxelSize + inset * 0.5,
      Float(coord.z) * voxelSize
    )
    return model
  }

  private static func lineSegment(length: Float, thickness: Float, color: UIColor) -> ModelEntity {
    let mesh = MeshResource.generateBox(size: SIMD3(thickness, thickness, length))
    let material = SimpleMaterial(color: color, isMetallic: false)
    return ModelEntity(mesh: mesh, materials: [material])
  }

  private static func rotationAligningZAxis(to direction: SIMD3<Float>) -> simd_quatf {
    let target = simd_normalize(direction)
    let source = SIMD3<Float>(0, 0, 1)

    let dot = simd_dot(source, target)
    if dot > 0.9999 { return simd_quatf(angle: 0, axis: SIMD3(0, 1, 0)) }
    if dot < -0.9999 { return simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0)) }

    let axis = simd_normalize(simd_cross(source, target))
    let angle = acos(min(max(dot, -1), 1))
    return simd_quatf(angle: angle, axis: axis)
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

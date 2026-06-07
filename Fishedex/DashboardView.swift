import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Map Tab

private let defaultMapSpan = 0.038

struct MapTabView: View {
    let fish: [Fish]
    var onLogoTap: (() -> Void)? = nil

    @StateObject private var location = LocationWeatherManager()
    @State private var selectedSpot: FishingSpot? = nil
    @State private var hasCenteredOnUser = false
    @State private var latitudeDelta = defaultMapSpan
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.867, longitude: 151.201),
            span: MKCoordinateSpan(latitudeDelta: defaultMapSpan, longitudeDelta: defaultMapSpan)
        )
    )

    private let spots = FishingSpot.samples

    private var caughtCount: Int { fish.filter(\.caught).count }
    private var progress: Double  { Double(caughtCount) / Double(max(fish.count, 1)) }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onLogoTap: onLogoTap)
            CollectionProgressCard(caughtCount: caughtCount, total: fish.count, progress: progress)
            mapSection
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear { location.start() }
        .onDisappear { location.stop() }
        .onReceive(location.$userCoordinate) { coordinate in
            centerOnUserIfNeeded(coordinate)
        }
    }

    private var pinZoomScale: CGFloat {
        let scale = defaultMapSpan / max(latitudeDelta, defaultMapSpan)
        return CGFloat(min(max(scale, 0.3), 1.0))
    }

    private func centerOnUserIfNeeded(_ coordinate: CLLocationCoordinate2D?) {
        guard let coordinate, !hasCenteredOnUser else { return }
        hasCenteredOnUser = true
        withAnimation(.easeOut(duration: 0.4)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: defaultMapSpan, longitudeDelta: defaultMapSpan)
                )
            )
        }
    }

    // MARK: Map section

    private var mapSection: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(spots) { spot in
                    Annotation("", coordinate: spot.coordinate) {
                        FishingSpotPin(
                            isSelected: selectedSpot?.id == spot.id,
                            zoomScale: pinZoomScale
                        )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSpot = selectedSpot?.id == spot.id ? nil : spot
                                }
                            }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard)
            .onMapCameraChange(frequency: .continuous) { context in
                latitudeDelta = context.region.span.latitudeDelta
            }
            .onTapGesture {
                withAnimation { selectedSpot = nil }
            }

            localWatersLabel

            if let spot = selectedSpot {
                SpotCallout(spot: spot)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var localWatersLabel: some View {
        Text("LOCAL WATERS")
            .font(FishedexFont.caption)
            .foregroundStyle(FishedexTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Collection Progress Card

private struct CollectionProgressCard: View {
    let caughtCount: Int
    let total: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("COLLECTION PROGRESS")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .kerning(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(String(format: "%.1f%%", progress * 100))
                        .font(FishedexFont.pokemon(22))
                        .foregroundStyle(FishedexTheme.ink)

                    Spacer()

                    Text("\(caughtCount) / \(total) FISH")
                        .font(FishedexFont.subheadline)
                        .foregroundStyle(FishedexTheme.muted)
                }
            }

            CollectionProgressBlocks(progress: progress)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.white)
    }
}

// MARK: - Progress blocks

private struct CollectionProgressBlocks: View {
    let progress: Double
    private let total = 12

    private var filled: Int { Int(Double(total) * min(max(progress, 0), 1)) }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? FishedexTheme.progressGreen : Color(red: 0.86, green: 0.86, blue: 0.87))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Map annotation pin

private struct FishingSpotPin: View {
    let isSelected: Bool
    var zoomScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .fishedexBorder(lineWidth: 2)

            Image(systemName: "fish.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.38))
        }
        .overlay(
            Rectangle()
                .stroke(isSelected ? FishedexTheme.ocean : Color.clear, lineWidth: 3)
        )
        .scaleEffect((isSelected ? 1.15 : 1.0) * zoomScale)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

#Preview {
    MapTabView(fish: Fish.samples)
        .environmentObject(SessionManager())
}

// MARK: - Spot callout card

private struct SpotCallout: View {
    let spot: FishingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(FishedexFont.headline)
                .foregroundStyle(FishedexTheme.ink)

            Text("Biome: \(spot.biome)")
                .font(FishedexFont.subheadline)
                .foregroundStyle(FishedexTheme.muted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }
}

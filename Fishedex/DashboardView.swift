import SwiftUI
import MapKit

// MARK: - Map Tab

struct MapTabView: View {
    let fish: [Fish]

    @State private var selectedSpot: FishingSpot? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.867, longitude: 151.201),
            span: MKCoordinateSpan(latitudeDelta: 0.038, longitudeDelta: 0.038)
        )
    )

    private let spots = FishingSpot.samples

    private var caughtCount: Int { fish.filter(\.caught).count }
    private var progress: Double  { Double(caughtCount) / Double(max(fish.count, 1)) }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView()
            CollectionProgressCard(caughtCount: caughtCount, total: fish.count, progress: progress)
            mapSection
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: Map section

    private var mapSection: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition) {
                ForEach(spots) { spot in
                    Annotation("", coordinate: spot.coordinate) {
                        FishingSpotPin(isSelected: selectedSpot?.id == spot.id)
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
            .font(.caption.weight(.bold))
            .foregroundStyle(FishedexTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
            .padding(14)
    }
}

// MARK: - Collection Progress Card

private struct CollectionProgressCard: View {
    let caughtCount: Int
    let total: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COLLECTION PROGRESS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(String(format: "%.1f%%", progress * 100))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(FishedexTheme.ink)

                Spacer()

                Text("\(caughtCount) / \(total) FISH")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(FishedexTheme.ocean)
            }

            CollectionProgressBlocks(progress: progress)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
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
                RoundedRectangle(cornerRadius: 3, style: .continuous)
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

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)

            Image(systemName: "fish.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.68, blue: 0.38))
        }
        .overlay(
            Circle()
                .stroke(isSelected ? FishedexTheme.ocean : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Spot callout card

private struct SpotCallout: View {
    let spot: FishingSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(.headline.weight(.bold))
                .foregroundStyle(FishedexTheme.ink)

            Text("Biome: \(spot.biome)")
                .font(.subheadline)
                .foregroundStyle(FishedexTheme.muted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
    }
}

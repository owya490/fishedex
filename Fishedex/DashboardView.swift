import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Map Tab

private let defaultMapSpan = 0.038

struct MapTabView: View {
    let fish: [Fish]
    var onLogoTap: (() -> Void)? = nil
    var onStartFishing: ((FishingSpot) -> Void)? = nil

    @StateObject private var location = LocationWeatherManager()
    @State private var detailSpot: FishingSpot? = nil
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
            DashboardBannerCarousel(
                caughtCount: caughtCount,
                total: fish.count,
                progress: progress,
                location: location
            )
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
                            scene: spot.scene,
                            biome: spot.biome,
                            isSelected: detailSpot?.id == spot.id,
                            zoomScale: pinZoomScale
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                detailSpot = spot
                            }
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .flat))
            .environment(\.colorScheme, .light)
            .onMapCameraChange(frequency: .continuous) { context in
                latitudeDelta = context.region.span.latitudeDelta
            }

            localWatersLabel
        }
        .frame(maxHeight: .infinity)
        .sheet(item: $detailSpot) { spot in
            FishingSpotDetailSheet(
                spot: spot,
                fish: fish,
                onStartFishing: {
                    detailSpot = nil
                    onStartFishing?(spot)
                },
                onDismiss: { detailSpot = nil }
            )
        }
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

// MARK: - Dashboard banner carousel

private struct DashboardBannerCarousel: View {
    let caughtCount: Int
    let total: Int
    let progress: Double
    @ObservedObject var location: LocationWeatherManager

    @State private var page = 0
    @State private var carouselTimer: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                WeatherInfoBanner(location: location)
                    .tag(0)

                CollectionProgressCard(
                    caughtCount: caughtCount,
                    total: total,
                    progress: progress
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 100)
            .animation(.easeInOut(duration: 0.45), value: page)

            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { index in
                    Rectangle()
                        .fill(index == page ? FishedexTheme.ocean : FishedexTheme.progressTrack)
                        .frame(width: index == page ? 14 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: page)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 6)
        }
        .background(Color.white)
        .onAppear { startCarousel() }
        .onDisappear { carouselTimer = nil }
    }

    private func startCarousel() {
        carouselTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.easeInOut(duration: 0.45)) {
                    page = (page + 1) % 2
                }
            }
    }
}

// MARK: - Weather info banner

private struct WeatherInfoBanner: View {
    @ObservedObject var location: LocationWeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FishedexTheme.ocean)

                Text(location.dateLabel)
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .kerning(0.6)

                Spacer()

                Text(location.weatherLabel)
                    .font(FishedexFont.subheadline)
                    .foregroundStyle(FishedexTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 8) {
                WeatherStatChip(
                    icon: location.windIcon,
                    title: "WIND",
                    value: location.windLabel,
                    tint: FishedexTheme.tabBlue
                )
                WeatherStatChip(
                    icon: location.pressureIcon,
                    title: "PRESSURE",
                    value: location.pressureLabel,
                    tint: FishedexTheme.ocean
                )
                WeatherStatChip(
                    icon: location.precipitationIcon,
                    title: "RAIN",
                    value: location.precipitationLabel,
                    tint: FishedexTheme.coral
                )
                WeatherStatChip(
                    icon: location.moonPhaseIcon,
                    title: "MOON",
                    value: location.moonPhaseLabel,
                    tint: Color(red: 0.45, green: 0.38, blue: 0.72)
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 0)
    }
}

private struct WeatherStatChip: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Rectangle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 30, height: 30)
                    .fishedexBorder(lineWidth: 1, color: tint.opacity(0.35))

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)

            Text(value)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
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

            FishedexProgressBar(progress: progress)
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 0)
        .background(Color.white)
    }
}

// MARK: - Map annotation pin

struct FishingSpotPin: View {
    let scene: FishingSpotScene
    let biome: FishingSpotBiome
    let isSelected: Bool
    var zoomScale: CGFloat = 1.0

    private let pinSize: CGFloat = 28
    private let imageInset: CGFloat = 2

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: pinSize, height: pinSize)
                .fishedexBorder(lineWidth: 1.5)

            FishingSpotSceneImageView(scene: scene)
                .frame(width: pinSize - imageInset * 2, height: pinSize - imageInset * 2)
                .clipped()
        }
        .overlay(
            Rectangle()
                .stroke(isSelected ? biome.accentColor : Color.black.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 0, x: 1, y: 1)
        .scaleEffect((isSelected ? 1.1 : 1.0) * zoomScale)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

#Preview {
    MapTabView(fish: Fish.samples)
        .environmentObject(SessionManager())
}

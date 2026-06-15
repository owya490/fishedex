import SwiftUI

struct FishingTimesDetailSheet: View {
    @ObservedObject var location: LocationWeatherManager
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ratingSection
                    majorSection
                    minorSection
                    sunMoonSection
                    tideSection
                    weatherSection
                    howWeCalculateSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(FishedexTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { sheetHeader }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FishedexTheme.ink)
                    .frame(width: 32, height: 32)
                    .background(FishedexTheme.card)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("FISHING TIMES")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Sections

    @ViewBuilder
    private var ratingSection: some View {
        if let forecast = location.solunarForecast {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("TODAY'S RATING")

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(SolunarCalculator.starString(rating: forecast.starRating))
                            .font(FishedexFont.pokemon(18))
                            .foregroundStyle(FishedexTheme.tabBlue)

                        Spacer()

                        Text(forecast.ratingSummary)
                            .font(FishedexFont.headline)
                            .foregroundStyle(FishedexTheme.ink)
                            .kerning(0.6)
                    }

                    if forecast.hasTideBonus {
                        HStack(spacing: 6) {
                            Image(systemName: "water.waves")
                                .font(.system(size: 11, weight: .semibold))
                            Text("TIDE OVERLAP BOOST")
                                .font(FishedexFont.micro)
                                .kerning(0.5)
                        }
                        .foregroundStyle(FishedexTheme.ocean)
                    }

                    Text("Solunar + tide rating only — check weather before you head out.")
                        .font(FishedexFont.micro)
                        .foregroundStyle(FishedexTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
            .padding(.top, 4)
        } else {
            placeholderCard("TODAY'S RATING", message: location.solunarLoading
                ? "Calculating bite times..."
                : "Enable location to see today's fishing forecast.")
        }
    }

    private var majorSection: some View {
        periodSection(
            title: "MAJOR PERIODS",
            subtitle: "Moon overhead & underfoot (~2 hr windows)",
            periods: location.solunarForecast?.majorPeriods ?? [],
            tint: FishedexTheme.tabGreen
        )
    }

    private var minorSection: some View {
        periodSection(
            title: "MINOR PERIODS",
            subtitle: "Moonrise & moonset (~2 hr windows)",
            periods: location.solunarForecast?.minorPeriods ?? [],
            tint: FishedexTheme.coral
        )
    }

    private var sunMoonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("SUN & MOON")

            if let forecast = location.solunarForecast {
                HStack(spacing: 8) {
                    FishingDetailChip(icon: "sunrise.fill", title: "SUNRISE", value: SolunarCalculator.formatTime(forecast.sunrise), tint: FishedexTheme.coral)
                    FishingDetailChip(icon: "sunset.fill", title: "SUNSET", value: SolunarCalculator.formatTime(forecast.sunset), tint: FishedexTheme.coral)
                }
                HStack(spacing: 8) {
                    FishingDetailChip(icon: forecast.moonPhase.icon, title: "MOON", value: forecast.moonPhase.shortLabel, tint: Color(red: 0.45, green: 0.38, blue: 0.72))
                    FishingDetailChip(icon: "moonrise.fill", title: "RISE", value: SolunarCalculator.formatTime(forecast.moonrise), tint: Color(red: 0.45, green: 0.38, blue: 0.72))
                    FishingDetailChip(icon: "moonset.fill", title: "SET", value: SolunarCalculator.formatTime(forecast.moonset), tint: Color(red: 0.45, green: 0.38, blue: 0.72))
                }
            } else {
                Text("—")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            }
        }
    }

    private var tideSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("TIDES")

            if location.tideSamples.count >= 2 {
                TideGraphView(
                    locationName: location.locationName,
                    samples: location.tideSamples,
                    extrema: displayedTides
                )
            } else if location.solunarLoading {
                Text("Loading tide data...")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            }

            if location.tideExtrema.isEmpty {
                if !location.solunarLoading {
                    Text("No tide data for today.")
                        .font(FishedexFont.caption)
                        .foregroundStyle(FishedexTheme.muted)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(displayedTides) { tide in
                        HStack {
                            Image(systemName: tide.isHigh ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundStyle(FishedexTheme.ocean)
                            Text(tide.isHigh ? "HIGH" : "LOW")
                                .font(FishedexFont.caption)
                                .foregroundStyle(FishedexTheme.ink)
                                .frame(width: 44, alignment: .leading)
                            Text(SolunarCalculator.formatTime(tide.time))
                                .font(FishedexFont.caption)
                                .foregroundStyle(tide.time < Date() ? FishedexTheme.muted : FishedexTheme.ink)
                            Spacer()
                            Text(String(format: "%.1f M", tide.heightMeters))
                                .font(FishedexFont.caption)
                                .foregroundStyle(FishedexTheme.ink)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .fishedexSquare()
                        .fishedexBorder(lineWidth: 1)
                        .opacity(tide.time < Date().addingTimeInterval(-30 * 60) ? 0.55 : 1)
                    }
                }
            }
        }
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("WEATHER (CHECK BEFORE YOU GO)")

            HStack(spacing: 8) {
                FishingDetailChip(icon: location.pressureIcon, title: "PRESSURE", value: location.pressureLabel, tint: FishedexTheme.ocean)
                FishingDetailChip(icon: "gauge.with.needle.fill", title: "TREND", value: location.pressureTrendLabel, tint: FishedexTheme.tabBlue)
            }
            HStack(spacing: 8) {
                FishingDetailChip(icon: location.windIcon, title: "WIND", value: location.windLabel, tint: FishedexTheme.tabBlue)
                FishingDetailChip(icon: location.precipitationIcon, title: "RAIN", value: location.precipitationLabel, tint: FishedexTheme.coral)
            }

            Text(location.weatherLabel)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)
        }
    }

    private var howWeCalculateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("HOW WE CALCULATE")

            VStack(alignment: .leading, spacing: 12) {
                infoBlock(
                    title: "QUICK ANSWER",
                    body: "The best times are when Moon Up/Down overlaps with sunrise or sunset, especially around a Full or New Moon."
                )
                infoBlock(
                    title: "MAJOR & MINOR TIMES",
                    body: "Major periods occur at moon overhead and underfoot. Minor periods occur at moonrise and moonset. Overlaps with dawn or dusk boost the day rating."
                )
                infoBlock(
                    title: "TIDES",
                    body: "When bite windows align with high or low tide (±1 hour), the day earns a bonus star — especially useful for saltwater and estuary fishing."
                )
                infoBlock(
                    title: "SOLUNAR THEORY",
                    body: "John Alden Knight's research links fish feeding to sun and moon positions. Plan around Major & Minor times, watch weather and tides, and fish with nature's rhythm."
                )
                infoBlock(
                    title: "PRO TIP",
                    body: "Plan trips around Major periods that overlap sunrise or sunset during a New or Full Moon for the hottest bite."
                )
            }
            .padding(14)
            .background(FishedexTheme.cream.opacity(0.45))
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
        }
    }

    // MARK: - Helpers

    private var displayedTides: [TideExtreme] {
        location.tideExtrema.sorted { $0.time < $1.time }
    }

    private func periodSection(title: String, subtitle: String, periods: [SolunarPeriod], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)
            Text(subtitle)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)

            if periods.isEmpty {
                Text("—")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
            } else {
                ForEach(periods) { period in
                    HStack {
                        Text(period.kind == .major ? "MAJOR" : "MINOR")
                            .font(FishedexFont.micro)
                            .foregroundStyle(tint)
                            .frame(width: 48, alignment: .leading)
                        Text(SolunarCalculator.formatPeriod(period))
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.ink)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
                }
            }
        }
    }

    private func placeholderCard(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)
            Text(message)
                .font(FishedexFont.body)
                .foregroundStyle(FishedexTheme.muted)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
        .padding(.top, 4)
    }

    private func infoBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.ink)
                .kerning(0.5)
            Text(body)
                .font(FishedexFont.body)
                .foregroundStyle(FishedexTheme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(FishedexFont.caption)
            .foregroundStyle(FishedexTheme.muted)
            .kerning(0.8)
    }
}

// MARK: - Detail chip

struct FishingDetailChip: View {
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

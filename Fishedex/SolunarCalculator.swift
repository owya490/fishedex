import Foundation

// MARK: - Moon phase

enum MoonPhase: String, Codable, Hashable {
    case new
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case full
    case waningGibbous
    case lastQuarter
    case waningCrescent

    var shortLabel: String {
        switch self {
        case .new: return "NEW"
        case .waxingCrescent: return "WAXING"
        case .firstQuarter: return "1ST QTR"
        case .waxingGibbous: return "WAX GIB"
        case .full: return "FULL"
        case .waningGibbous: return "WAN GIB"
        case .lastQuarter: return "LAST QTR"
        case .waningCrescent: return "WANING"
        }
    }

    var icon: String {
        switch self {
        case .new: return "moon.fill"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .full: return "moonphase.full.moon"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }

    var isFullOrNew: Bool { self == .full || self == .new }

    static func from(date: Date) -> MoonPhase {
        let synodicMonth = 29.530588853
        let knownNewMoon = Date(timeIntervalSince1970: 947_182_440)
        let days = date.timeIntervalSince(knownNewMoon) / 86_400.0
        let phase = (days.truncatingRemainder(dividingBy: synodicMonth)) / synodicMonth

        switch phase {
        case 0..<0.0625, 0.9375...1.0: return .new
        case 0.0625..<0.1875: return .waxingCrescent
        case 0.1875..<0.3125: return .firstQuarter
        case 0.3125..<0.4375: return .waxingGibbous
        case 0.4375..<0.5625: return .full
        case 0.5625..<0.6875: return .waningGibbous
        case 0.6875..<0.8125: return .lastQuarter
        default: return .waningCrescent
        }
    }
}

// MARK: - Models

struct TideExtreme: Identifiable, Codable, Hashable {
    let id: String
    let time: Date
    let heightMeters: Double
    let isHigh: Bool
}

struct TideSample: Identifiable, Codable, Hashable {
    let time: Date
    let heightMeters: Double

    var id: TimeInterval { time.timeIntervalSince1970 }
}

enum SolunarPeriodKind: String, Codable, Hashable {
    case major
    case minor
}

struct SolunarPeriod: Identifiable, Codable, Hashable {
    let id: String
    let kind: SolunarPeriodKind
    let start: Date
    let end: Date

    var center: Date {
        start.addingTimeInterval(end.timeIntervalSince(start) / 2)
    }
}

struct SolunarDayForecast: Codable, Hashable {
    let calendarDay: String
    let starRating: Int
    let baseStarRating: Int
    let hasTideBonus: Bool
    let majorPeriods: [SolunarPeriod]
    let minorPeriods: [SolunarPeriod]
    let sunrise: Date
    let sunset: Date
    let moonrise: Date?
    let moonset: Date?
    let moonPhase: MoonPhase
    let ratingSummary: String

    var allPeriods: [SolunarPeriod] { majorPeriods + minorPeriods }
}

// MARK: - Calculator

enum SolunarCalculator {
    private static let periodHalfDuration: TimeInterval = 60 * 60
    private static let overlapWindow: TimeInterval = 60 * 60

    static func forecast(
        latitude: Double,
        longitude: Double,
        date: Date = Date(),
        sunrise: Date,
        sunset: Date,
        tideExtrema: [TideExtreme] = [],
        timeZone: TimeZone = .current
    ) -> SolunarDayForecast {
        let moon = moonEvents(latitude: latitude, longitude: longitude, on: date, timeZone: timeZone)
        var major: [SolunarPeriod] = []
        if let overhead = moon.overhead {
            major.append(makePeriod(kind: .major, center: overhead))
        }
        if let underfoot = moon.underfoot {
            major.append(makePeriod(kind: .major, center: underfoot))
        }
        major.sort { $0.start < $1.start }
        let minor = minorPeriods(rise: moon.rise, set: moon.set)
        let all = major + minor
        let phase = MoonPhase.from(date: date)
        let base = baseStarRating(periods: all, sunrise: sunrise, sunset: sunset, moonPhase: phase)
        let tideBonus = tideOverlapBonus(periods: all, tideExtrema: tideExtrema)
        let final = min(5, base + (tideBonus ? 1 : 0))

        return SolunarDayForecast(
            calendarDay: SolunarCacheKey.calendarDayString(for: date, timeZone: timeZone),
            starRating: final,
            baseStarRating: base,
            hasTideBonus: tideBonus,
            majorPeriods: major,
            minorPeriods: minor,
            sunrise: sunrise,
            sunset: sunset,
            moonrise: moon.rise,
            moonset: moon.set,
            moonPhase: phase,
            ratingSummary: ratingLabel(for: final)
        )
    }

    static func baseStarRating(
        periods: [SolunarPeriod],
        sunrise: Date,
        sunset: Date,
        moonPhase: MoonPhase
    ) -> Int {
        var score = 1
        let dawnDusk = periods.contains { overlapsSunEvent($0, sunrise: sunrise, sunset: sunset) }
        if dawnDusk { score = 2 }
        if moonPhase.isFullOrNew { score = max(score, 3) }
        if moonPhase.isFullOrNew && dawnDusk { score = 4 }
        return score
    }

    static func tideOverlapBonus(
        periods: [SolunarPeriod],
        tideExtrema: [TideExtreme],
        windowMinutes: Int = 60
    ) -> Bool {
        guard !tideExtrema.isEmpty else { return false }
        let window = TimeInterval(windowMinutes * 60)
        for period in periods {
            for tide in tideExtrema {
                if abs(period.center.timeIntervalSince(tide.time)) <= window { return true }
                if tide.time >= period.start.addingTimeInterval(-window),
                   tide.time <= period.end.addingTimeInterval(window) { return true }
            }
        }
        return false
    }

    static func nextPeriod(from now: Date = Date(), in forecast: SolunarDayForecast) -> (major: SolunarPeriod?, minor: SolunarPeriod?) {
        let sortedMajor = forecast.majorPeriods.sorted { $0.start < $1.start }
        let sortedMinor = forecast.minorPeriods.sorted { $0.start < $1.start }
        return (
            sortedMajor.first { $0.end > now },
            sortedMinor.first { $0.end > now }
        )
    }

    static func formatPeriod(_ period: SolunarPeriod?) -> String {
        guard let period else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = .current
        let start = fmt.string(from: period.start).uppercased()
        let end = fmt.string(from: period.end).uppercased()
        return "\(start)–\(end)"
    }

    /// All periods of a kind, one per line (for dashboard banner).
    static func formatPeriodList(_ periods: [SolunarPeriod]) -> String {
        let sorted = periods.sorted { $0.start < $1.start }
        guard !sorted.isEmpty else { return "—" }
        return sorted.map { formatPeriod($0) }.joined(separator: "\n")
    }

    static func formatTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = .current
        return fmt.string(from: date).uppercased()
    }

    static func estimatedSunrise(latitude: Double, longitude: Double, date: Date, timeZone: TimeZone = .current) -> Date? {
        sunHorizonEvent(latitude: latitude, longitude: longitude, on: date, timeZone: timeZone, rising: true)
    }

    static func estimatedSunset(latitude: Double, longitude: Double, date: Date, timeZone: TimeZone = .current) -> Date? {
        sunHorizonEvent(latitude: latitude, longitude: longitude, on: date, timeZone: timeZone, rising: false)
    }

    static func starString(rating: Int) -> String {
        let clamped = max(0, min(5, rating))
        return String(repeating: "★", count: clamped) + String(repeating: "☆", count: 5 - clamped)
    }

    static func ratingLabel(for stars: Int) -> String {
        switch stars {
        case 5: return "PEAK DAY"
        case 4: return "EXCELLENT DAY"
        case 3: return "GOOD DAY"
        case 2: return "FAIR DAY"
        default: return "SLOW DAY"
        }
    }

    // MARK: - Period builders

    private static func minorPeriods(rise: Date?, set: Date?) -> [SolunarPeriod] {
        var periods: [SolunarPeriod] = []
        if let rise { periods.append(makePeriod(kind: .minor, center: rise)) }
        if let set { periods.append(makePeriod(kind: .minor, center: set)) }
        return periods.sorted { $0.start < $1.start }
    }

    private static func makePeriod(kind: SolunarPeriodKind, center: Date) -> SolunarPeriod {
        let start = center.addingTimeInterval(-periodHalfDuration)
        let end = center.addingTimeInterval(periodHalfDuration)
        let id = "\(kind.rawValue)-\(Int(center.timeIntervalSince1970))"
        return SolunarPeriod(id: id, kind: kind, start: start, end: end)
    }

    private static func overlapsSunEvent(_ period: SolunarPeriod, sunrise: Date, sunset: Date) -> Bool {
        withinWindow(period.center, of: sunrise) || withinWindow(period.center, of: sunset)
    }

    private static func withinWindow(_ date: Date, of anchor: Date) -> Bool {
        abs(date.timeIntervalSince(anchor)) <= overlapWindow
    }

    private static func sunHorizonEvent(
        latitude: Double,
        longitude: Double,
        on date: Date,
        timeZone: TimeZone,
        rising: Bool
    ) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)

        var samples: [(date: Date, alt: Double)] = []
        let step: TimeInterval = 10 * 60
        for minute in stride(from: 0, through: 24 * 60, by: 10) {
            let sampleDate = start.addingTimeInterval(TimeInterval(minute * 60))
            let alt = sunAltitude(at: sampleDate, latitude: latitude, longitude: longitude)
            samples.append((sampleDate, alt))
        }

        for i in 0..<(samples.count - 1) {
            let a = samples[i]
            let b = samples[i + 1]
            let crosses = rising ? (a.alt <= 0 && b.alt > 0) : (a.alt >= 0 && b.alt < 0)
            guard crosses else { continue }
            return refineHorizonCrossing(
                between: a.date,
                and: b.date,
                latitude: latitude,
                longitude: longitude,
                rising: rising,
                useSun: true
            )
        }
        return nil
    }

    // MARK: - Moon astronomy (Meeus-style, simplified)

    private struct MoonEvents {
        let rise: Date?
        let set: Date?
        let overhead: Date?
        let underfoot: Date?
    }

    private static func moonEvents(
        latitude: Double,
        longitude: Double,
        on date: Date,
        timeZone: TimeZone
    ) -> MoonEvents {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)
        let scanStart = dayStart.addingTimeInterval(-3600)
        let scanEnd = dayEnd.addingTimeInterval(3600)

        var rise: Date?
        var set: Date?
        var overheads: [Date] = []
        var underfoots: [Date] = []
        var prevAzimuthSign: Int?

        var t = scanStart.timeIntervalSince1970
        let step: TimeInterval = 60
        while t <= scanEnd.timeIntervalSince1970 {
            let sampleDate = Date(timeIntervalSince1970: t)
            let position = moonAzimuthAndAltitude(at: sampleDate, latitude: latitude, longitude: longitude)
            let sign = position.azimuth >= 0 ? 1 : -1

            if let prevSign = prevAzimuthSign, prevSign != sign {
                let transit = refineAzimuthCrossing(
                    between: sampleDate.addingTimeInterval(-step),
                    and: sampleDate,
                    latitude: latitude,
                    longitude: longitude
                )
                let altitude = moonAltitude(at: transit, latitude: latitude, longitude: longitude)
                if altitude >= 0 {
                    overheads.append(transit)
                } else {
                    underfoots.append(transit)
                }
            }
            prevAzimuthSign = sign

            t += step
        }

        // Moonrise / moonset can fall just outside the day boundary — scan ±1 day like reference libs.
        for dayOffset in -1...1 {
            let probeStart = calendar.date(byAdding: .day, value: dayOffset, to: dayStart) ?? dayStart
            if rise == nil {
                rise = moonHorizonEvent(
                    latitude: latitude,
                    longitude: longitude,
                    on: probeStart,
                    timeZone: timeZone,
                    rising: true
                )?.dateIf(in: dayStart..<dayEnd)
            }
            if set == nil {
                set = moonHorizonEvent(
                    latitude: latitude,
                    longitude: longitude,
                    on: probeStart,
                    timeZone: timeZone,
                    rising: false
                )?.dateIf(in: dayStart..<dayEnd)
            }
        }

        let overhead = overheads.first { (dayStart..<dayEnd).contains($0) }
            ?? overheads.min(by: { abs($0.timeIntervalSince(dayStart)) < abs($1.timeIntervalSince(dayStart)) })
        let underfoot = underfoots.first { (dayStart..<dayEnd).contains($0) }
            ?? underfoots.min(by: { abs($0.timeIntervalSince(dayStart)) < abs($1.timeIntervalSince(dayStart)) })

        return MoonEvents(rise: rise, set: set, overhead: overhead, underfoot: underfoot)
    }

    private static func moonHorizonEvent(
        latitude: Double,
        longitude: Double,
        on date: Date,
        timeZone: TimeZone,
        rising: Bool
    ) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)

        var samples: [(date: Date, alt: Double)] = []
        for minute in stride(from: 0, through: 24 * 60, by: 5) {
            let sampleDate = start.addingTimeInterval(TimeInterval(minute * 60))
            let alt = moonAltitude(at: sampleDate, latitude: latitude, longitude: longitude)
            samples.append((sampleDate, alt))
        }

        return findHorizonCrossing(
            samples: samples,
            latitude: latitude,
            longitude: longitude,
            rising: rising
        )
    }

    private static func moonAzimuthAndAltitude(
        at date: Date,
        latitude: Double,
        longitude: Double
    ) -> (azimuth: Double, altitude: Double) {
        let jd = julianDay(date)
        let (ra, dec) = moonEquatorial(jd: jd)
        let lst = localSiderealTime(jd: jd, longitude: longitude)
        let hourAngle = (lst - ra) * .pi / 180
        let latRad = latitude * .pi / 180
        let decRad = dec * .pi / 180
        let altitude = altitudeDegrees(latitude: latitude, declination: dec, hourAngle: lst - ra)

        let y = sin(hourAngle)
        let x = cos(hourAngle) * sin(latRad) - tan(decRad) * cos(latRad)
        let azimuth = atan2(y, x)
        return (azimuth, altitude)
    }

    private static func refineAzimuthCrossing(
        between start: Date,
        and end: Date,
        latitude: Double,
        longitude: Double
    ) -> Date {
        var low = start.timeIntervalSince1970
        var high = end.timeIntervalSince1970
        for _ in 0..<24 {
            let mid = (low + high) / 2
            let az = moonAzimuthAndAltitude(
                at: Date(timeIntervalSince1970: mid),
                latitude: latitude,
                longitude: longitude
            ).azimuth
            if az >= 0 {
                high = mid
            } else {
                low = mid
            }
        }
        return Date(timeIntervalSince1970: (low + high) / 2)
    }

    private static func findHorizonCrossing(
        samples: [(date: Date, alt: Double)],
        latitude: Double,
        longitude: Double,
        rising: Bool
    ) -> Date? {
        for i in 0..<(samples.count - 1) {
            let a = samples[i]
            let b = samples[i + 1]
            let crosses = rising ? (a.alt <= 0 && b.alt > 0) : (a.alt >= 0 && b.alt < 0)
            guard crosses else { continue }
            return refineHorizonCrossing(
                between: a.date,
                and: b.date,
                latitude: latitude,
                longitude: longitude,
                rising: rising,
                useSun: false
            )
        }
        return nil
    }

    private static func refineHorizonCrossing(
        between start: Date,
        and end: Date,
        latitude: Double,
        longitude: Double,
        rising: Bool,
        useSun: Bool = false
    ) -> Date {
        var low = start.timeIntervalSince1970
        var high = end.timeIntervalSince1970
        for _ in 0..<20 {
            let mid = (low + high) / 2
            let alt = useSun
                ? sunAltitude(at: Date(timeIntervalSince1970: mid), latitude: latitude, longitude: longitude)
                : moonAltitude(at: Date(timeIntervalSince1970: mid), latitude: latitude, longitude: longitude)
            if rising {
                if alt > 0 { high = mid } else { low = mid }
            } else {
                if alt < 0 { high = mid } else { low = mid }
            }
        }
        return Date(timeIntervalSince1970: (low + high) / 2)
    }

    private static func moonAltitude(at date: Date, latitude: Double, longitude: Double) -> Double {
        let jd = julianDay(date)
        let (ra, dec) = moonEquatorial(jd: jd)
        let lst = localSiderealTime(jd: jd, longitude: longitude)
        let ha = normalizeDegrees(lst - ra)
        return altitudeDegrees(latitude: latitude, declination: dec, hourAngle: ha)
    }

    private static func sunAltitude(at date: Date, latitude: Double, longitude: Double) -> Double {
        let jd = julianDay(date)
        let (ra, dec) = sunEquatorial(jd: jd)
        let lst = localSiderealTime(jd: jd, longitude: longitude)
        let ha = normalizeDegrees(lst - ra)
        return altitudeDegrees(latitude: latitude, declination: dec, hourAngle: ha)
    }

    private static func sunEquatorial(jd: Double) -> (ra: Double, dec: Double) {
        let t = (jd - 2_451_545.0) / 36_525.0
        let l0 = normalizeDegrees(280.46646 + 36_000.76983 * t)
        let m = normalizeDegrees(357.52911 + 35_999.05029 * t - 0.0001537 * t * t)
        let c = (1.914602 - 0.004817 * t) * sinDegrees(m)
            + (0.019993 - 0.000101 * t) * sinDegrees(2 * m)
            + 0.000289 * sinDegrees(3 * m)
        let sunLon = normalizeDegrees(l0 + c)
        let eps = 23.439291 - 0.0130042 * t
        let lonRad = sunLon * .pi / 180
        let epsRad = eps * .pi / 180
        let sinDec = sin(epsRad) * sin(lonRad)
        let dec = asin(sinDec) * 180 / .pi
        let y = cos(epsRad) * sin(lonRad)
        let x = cos(lonRad)
        let ra = atan2(y, x) * 180 / .pi
        return (normalizeDegrees(ra), dec)
    }

    private static func julianDay(_ date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var y = Double(c.year ?? 2000)
        var m = Double(c.month ?? 1)
        let dayFraction = (Double(c.hour ?? 0)
            + Double(c.minute ?? 0) / 60
            + Double(c.second ?? 0) / 3600) / 24
        let d = Double(c.day ?? 1) + dayFraction
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5
    }

    private static func moonEquatorial(jd: Double) -> (ra: Double, dec: Double) {
        let t = (jd - 2_451_545.0) / 36_525.0
        let lp = normalizeDegrees(218.316 + 481_267.881 * t)
        let d = normalizeDegrees(297.850 + 445_267.111 * t)
        let m = normalizeDegrees(357.529 + 35_999.050 * t)
        let mp = normalizeDegrees(134.963 + 477_198.868 * t)
        let f = normalizeDegrees(93.272 + 483_202.018 * t)

        let lon = lp
            + 6.289 * sinDegrees(mp)
            + 1.274 * sinDegrees(2 * d - mp)
            + 0.658 * sinDegrees(2 * d)
            + 0.214 * sinDegrees(2 * mp)
            - 0.186 * sinDegrees(m)
            - 0.114 * sinDegrees(2 * f)

        let lat = 5.128 * sinDegrees(f)
            + 0.281 * sinDegrees(mp + f)
            + 0.278 * sinDegrees(mp - f)
            + 0.173 * sinDegrees(2 * d - f)

        let eps = 23.439 - 0.0000004 * t
        let lonRad = lon * .pi / 180
        let latRad = lat * .pi / 180
        let epsRad = eps * .pi / 180

        let sinDec = sin(latRad) * cos(epsRad) + cos(latRad) * sin(epsRad) * sin(lonRad)
        let dec = asin(sinDec) * 180 / .pi

        let y = sin(lonRad) * cos(epsRad) - tan(latRad) * sin(epsRad)
        let x = cos(lonRad)
        let ra = atan2(y, x) * 180 / .pi

        return (normalizeDegrees(ra), dec)
    }

    private static func localSiderealTime(jd: Double, longitude: Double) -> Double {
        let t = (jd - 2_451_545.0) / 36_525.0
        let gst = normalizeDegrees(
            280.46061837
            + 360.98564736629 * (jd - 2_451_545.0)
            + 0.000387933 * t * t
            - t * t * t / 38_710_000
        )
        return normalizeDegrees(gst + longitude)
    }

    private static func altitudeDegrees(latitude: Double, declination: Double, hourAngle: Double) -> Double {
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180
        let haRad = hourAngle * .pi / 180
        let sinAlt = sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad)
        return asin(max(-1, min(1, sinAlt))) * 180 / .pi
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        var v = value.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    private static func sinDegrees(_ d: Double) -> Double { sin(d * .pi / 180) }
}

// MARK: - Tide curve

enum TideCurveBuilder {
    static func samplesForToday(
        from times: [Date],
        heights: [Double],
        calendar: Calendar = .current
    ) -> [TideSample] {
        guard times.count == heights.count else { return [] }
        return zip(times, heights)
            .compactMap { time, height in
                calendar.isDateInToday(time) ? TideSample(time: time, heightMeters: height) : nil
            }
            .sorted { $0.time < $1.time }
    }

    /// Builds a smooth 24-hour curve from high/low extrema when hourly data is unavailable.
    static func synthesizeFromExtrema(
        _ extrema: [TideExtreme],
        calendar: Calendar = .current,
        stepMinutes: Int = 15
    ) -> [TideSample] {
        let sorted = extrema.sorted { $0.time < $1.time }
        guard sorted.count >= 2 else { return [] }

        let dayStart = calendar.startOfDay(for: Date())
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)
        let anchors = sorted.map { ($0.time, $0.heightMeters) }

        var samples: [TideSample] = []
        let step = TimeInterval(stepMinutes * 60)
        var t = dayStart.timeIntervalSince1970
        while t < dayEnd.timeIntervalSince1970 {
            let time = Date(timeIntervalSince1970: t)
            let height = interpolateHeight(at: time, anchors: anchors)
            samples.append(TideSample(time: time, heightMeters: height))
            t += step
        }
        return samples
    }

    private static func interpolateHeight(at time: Date, anchors: [(Date, Double)]) -> Double {
        let t = time.timeIntervalSince1970

        if t <= anchors[0].0.timeIntervalSince1970 {
            let (t0, h0) = anchors[0]
            let (t1, h1) = anchors[1]
            let span = max(t1.timeIntervalSince(t0), 1)
            let phase = (t - t0.timeIntervalSince1970) / span
            return cosineBlend(from: h0, to: h1, phase: phase)
        }

        if t >= anchors[anchors.count - 1].0.timeIntervalSince1970 {
            let (t0, h0) = anchors[anchors.count - 2]
            let (t1, h1) = anchors[anchors.count - 1]
            let span = max(t1.timeIntervalSince(t0), 1)
            let phase = (t - t0.timeIntervalSince1970) / span
            return cosineBlend(from: h0, to: h1, phase: phase)
        }

        for index in 0..<(anchors.count - 1) {
            let (startTime, startHeight) = anchors[index]
            let (endTime, endHeight) = anchors[index + 1]
            let start = startTime.timeIntervalSince1970
            let end = endTime.timeIntervalSince1970
            guard t >= start, t <= end else { continue }
            let span = max(end - start, 1)
            let phase = (t - start) / span
            return cosineBlend(from: startHeight, to: endHeight, phase: phase)
        }

        return anchors[0].1
    }

    private static func cosineBlend(from start: Double, to end: Double, phase: Double) -> Double {
        let clamped = max(0, min(1, phase))
        let eased = 0.5 - cos(clamped * .pi) / 2
        return start + (end - start) * eased
    }
}

// MARK: - Tide parsing

enum TideParser {
    static func extrema(from hourlyTimes: [Date], heights: [Double], calendar: Calendar = .current) -> [TideExtreme] {
        guard hourlyTimes.count == heights.count, hourlyTimes.count >= 3 else { return [] }

        var extrema: [TideExtreme] = []
        for i in 1..<(hourlyTimes.count - 1) {
            let prev = heights[i - 1]
            let curr = heights[i]
            let next = heights[i + 1]
            if curr > prev && curr > next {
                let peak = interpolatePeak(times: hourlyTimes, heights: heights, index: i, isHigh: true)
                extrema.append(peak)
            } else if curr < prev && curr < next {
                let trough = interpolatePeak(times: hourlyTimes, heights: heights, index: i, isHigh: false)
                extrema.append(trough)
            }
        }
        return extrema
    }

    private static func interpolatePeak(
        times: [Date],
        heights: [Double],
        index: Int,
        isHigh: Bool
    ) -> TideExtreme {
        let t0 = times[index - 1].timeIntervalSince1970
        let t1 = times[index].timeIntervalSince1970
        let t2 = times[index + 1].timeIntervalSince1970
        let h0 = heights[index - 1]
        let h1 = heights[index]
        let h2 = heights[index + 1]

        let denom = h0 - 2 * h1 + h2
        var fraction = 0.0
        if abs(denom) > 0.0001 {
            fraction = (h0 - h2) / (2 * denom)
            fraction = max(-0.5, min(0.5, fraction))
        }
        let peakTime = Date(timeIntervalSince1970: t1 + fraction * (t2 - t0))
        let peakHeight = h1 - denom * fraction * fraction / 4

        let id = "\(isHigh ? "high" : "low")-\(Int(peakTime.timeIntervalSince1970))"
        return TideExtreme(id: id, time: peakTime, heightMeters: peakHeight, isHigh: isHigh)
    }
}

private extension Date {
    func dateIf(in range: Range<Date>) -> Date? {
        range.contains(self) ? self : nil
    }
}

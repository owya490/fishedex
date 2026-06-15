import Foundation
import CoreLocation
import Combine

// MARK: - Location + Weather manager

final class LocationWeatherManager: NSObject, ObservableObject {

    // Time
    @Published var timeLabel    = "LOADING..."
    @Published var timeIcon     = "sun.max.fill"
    @Published var dateLabel    = ""

    // Weather — starts with a placeholder so the row always renders
    @Published var weatherLabel = "LOCATING..."
    @Published var weatherIcon  = "location.fill"

    @Published var windLabel         = "—"
    @Published var windIcon          = "wind"
    @Published var pressureLabel     = "—"
    @Published var pressureIcon      = "gauge.with.dots.needle.33percent"
    @Published var pressureTrendLabel = "—"
    @Published var precipitationLabel = "0%"
    @Published var precipitationIcon = "sun.min.fill"
    @Published var moonPhaseLabel    = "—"
    @Published var moonPhaseIcon       = "moon.fill"

    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var locationName = "Locating..."

    @Published var solunarForecast: SolunarDayForecast?
    @Published var tideExtrema: [TideExtreme] = []
    @Published var tideSamples: [TideSample] = []
    @Published var solunarLoading = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var timer: AnyCancellable?
    private var lastFetchLocation: CLLocation?
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeAttemptTime: Date?
    private var solunarFetchKey: SolunarCacheKey?

    private static let geocodeMinDistance: CLLocationDistance = 5_000
    private static let geocodeMinInterval: TimeInterval = 60

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        refreshTime()
    }

    // MARK: Start / stop (call from onAppear/onDisappear)

    func start() {
        timer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refreshTime() }

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stop() {
        timer = nil
        locationManager.stopUpdatingLocation()
    }

    // MARK: Time

    private func refreshTime() {
        let hour = Calendar.current.component(.hour, from: Date())

        let label: String
        let icon: String
        switch hour {
        case 5..<12:
            label = "MORNING"; icon = "sunrise.fill"
        case 12..<14:
            label = "MIDDAY";  icon = "sun.max.fill"
        case 14..<18:
            label = "AFTERNOON"; icon = "sun.min.fill"
        case 18..<21:
            label = "EVENING"; icon = "sunset.fill"
        default:
            label = "NIGHT"; icon = "moon.stars.fill"
        }

        let now = Date()

        let clockFmt = DateFormatter()
        clockFmt.dateFormat = "h:mm a"
        let clock = clockFmt.string(from: now).uppercased()

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "EEE · d MMM yyyy"
        dateLabel = dateFmt.string(from: now).uppercased()

        timeLabel = "\(label) · \(clock)"
        timeIcon  = icon

        let moon = MoonPhase.from(date: now)
        moonPhaseLabel = moon.shortLabel
        moonPhaseIcon  = moon.icon
    }

    // MARK: Weather via Open-Meteo (free, no key required)

    private func fetchWeather(lat: Double, lon: Double) {
        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,precipitation"
            + "&hourly=precipitation_probability,surface_pressure"
            + "&daily=sunrise,sunset"
            + "&temperature_unit=celsius"
            + "&wind_speed_unit=kmh"
            + "&precipitation_unit=mm"
            + "&timezone=auto"
            + "&forecast_days=1"
        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double,
                  let code = current["weather_code"] as? Int
            else { return }

            let (label, icon) = Self.weatherInfo(code: code)
            let windSpeed = current["wind_speed_10m"] as? Double
            let windDir   = current["wind_direction_10m"] as? Double
            let pressure  = current["surface_pressure"] as? Double
            let precip    = current["precipitation"] as? Double
            let rainChance = Self.currentPrecipitationProbability(from: json)
            let trend = Self.pressureTrend(from: json)

            DispatchQueue.main.async {
                self.weatherLabel = "\(label) · \(Int(temp.rounded()))°C"
                self.weatherIcon  = icon

                if let windSpeed {
                    let compass = windDir.map { Self.compassDirection(degrees: $0) } ?? ""
                    self.windLabel = compass.isEmpty
                        ? "\(Int(windSpeed.rounded())) KM/H"
                        : "\(Int(windSpeed.rounded())) KM/H \(compass)"
                    self.windIcon = Self.windIcon(speed: windSpeed)
                }

                if let pressure {
                    self.pressureLabel = "\(Int(pressure.rounded())) HPA"
                }

                self.pressureTrendLabel = trend

                let rain = Self.precipitationInfo(
                    code: code,
                    probability: rainChance,
                    currentMm: precip ?? 0
                )
                self.precipitationLabel = rain.label
                self.precipitationIcon  = rain.icon
            }
        }.resume()
    }

    // MARK: Solunar + tides (cached per day)

    private func refreshSolunarIfNeeded(for location: CLLocation) {
        let key = SolunarCacheKey.from(coordinate: location.coordinate)

        if let cached = SolunarDayCache.load(key: key) {
            applySolunar(cached)
            if cached.tideExtrema.isEmpty || cached.tideSamples.isEmpty {
                fetchTidesOnly(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    cacheKey: key,
                    forecast: cached.forecast
                )
            }
            return
        }

        guard solunarFetchKey != key else { return }
        solunarFetchKey = key
        solunarLoading = true
        fetchSolunarData(lat: location.coordinate.latitude, lon: location.coordinate.longitude, cacheKey: key)
    }

    private func applySolunar(_ cached: CachedSolunarDay) {
        solunarForecast = cached.forecast
        tideExtrema = cached.tideExtrema
        tideSamples = cached.tideSamples.isEmpty
            ? TideCurveBuilder.synthesizeFromExtrema(cached.tideExtrema)
            : cached.tideSamples
        solunarLoading = false

        let moon = cached.forecast.moonPhase
        moonPhaseLabel = moon.shortLabel
        moonPhaseIcon = moon.icon
    }

    private func fetchSolunarData(lat: Double, lon: Double, cacheKey: SolunarCacheKey) {
        let group = DispatchGroup()
        var sunrise: Date?
        var sunset: Date?
        var tides: [TideExtreme] = []
        var samples: [TideSample] = []

        group.enter()
        fetchSunTimes(lat: lat, lon: lon) { sun, set in
            sunrise = sun
            sunset = set
            group.leave()
        }

        group.enter()
        fetchTides(lat: lat, lon: lon) { extrema, hourlySamples in
            tides = extrema
            samples = hourlySamples
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            defer { self.solunarFetchKey = nil }

            let resolvedSunrise = sunrise ?? SolunarCalculator.estimatedSunrise(
                latitude: lat, longitude: lon, date: Date()
            )
            let resolvedSunset = sunset ?? SolunarCalculator.estimatedSunset(
                latitude: lat, longitude: lon, date: Date()
            )

            guard let resolvedSunrise, let resolvedSunset else {
                self.solunarLoading = false
                return
            }

            let todayTides = Self.tidesForToday(tides)
            let todaySamples = samples.isEmpty
                ? TideCurveBuilder.synthesizeFromExtrema(tides)
                : samples
            let forecast = SolunarCalculator.forecast(
                latitude: lat,
                longitude: lon,
                sunrise: resolvedSunrise,
                sunset: resolvedSunset,
                tideExtrema: todayTides
            )

            let entry = CachedSolunarDay(
                key: cacheKey,
                forecast: forecast,
                tideExtrema: todayTides,
                tideSamples: todaySamples,
                cachedAt: Date()
            )
            SolunarDayCache.save(entry)
            self.applySolunar(entry)
        }
    }

    private func fetchSunTimes(lat: Double, lon: Double, completion: @escaping (Date?, Date?) -> Void) {
        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&daily=sunrise,sunset"
            + "&timezone=auto"
            + "&forecast_days=1"
        guard let url = URL(string: urlStr) else {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let daily = json["daily"] as? [String: Any],
                  let sunrises = daily["sunrise"] as? [String],
                  let sunsets = daily["sunset"] as? [String],
                  let riseStr = sunrises.first,
                  let setStr = sunsets.first
            else {
                DispatchQueue.main.async { completion(nil, nil) }
                return
            }

            let tzId = json["timezone"] as? String
            let rise = Self.parseOpenMeteoDate(riseStr, timeZoneId: tzId)
            let set = Self.parseOpenMeteoDate(setStr, timeZoneId: tzId)

            DispatchQueue.main.async { completion(rise, set) }
        }.resume()
    }

    private func fetchTides(lat: Double, lon: Double, completion: @escaping ([TideExtreme], [TideSample]) -> Void) {
        fetchMarineTides(lat: lat, lon: lon) { marineExtrema, marineSamples in
            if !marineExtrema.isEmpty {
                completion(marineExtrema, marineSamples)
                return
            }
            self.fetchTideTurtleTides(lat: lat, lon: lon) { extrema in
                let samples = TideCurveBuilder.synthesizeFromExtrema(extrema)
                completion(extrema, samples)
            }
        }
    }

    private func fetchTidesOnly(lat: Double, lon: Double, cacheKey: SolunarCacheKey, forecast: SolunarDayForecast) {
        fetchTides(lat: lat, lon: lon) { [weak self] extrema, samples in
            guard let self else { return }
            let todayTides = Self.tidesForToday(extrema)
            guard !todayTides.isEmpty else { return }

            let todaySamples = samples.isEmpty
                ? TideCurveBuilder.synthesizeFromExtrema(extrema)
                : samples

            let updatedForecast = SolunarCalculator.forecast(
                latitude: lat,
                longitude: lon,
                sunrise: forecast.sunrise,
                sunset: forecast.sunset,
                tideExtrema: todayTides
            )
            let entry = CachedSolunarDay(
                key: cacheKey,
                forecast: updatedForecast,
                tideExtrema: todayTides,
                tideSamples: todaySamples,
                cachedAt: Date()
            )
            SolunarDayCache.save(entry)
            self.applySolunar(entry)
        }
    }

    private func fetchMarineTides(
        lat: Double,
        lon: Double,
        completion: @escaping ([TideExtreme], [TideSample]) -> Void
    ) {
        let urlStr = "https://marine-api.open-meteo.com/v1/marine"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&hourly=sea_level_height_msl"
            + "&timezone=auto"
            + "&forecast_days=2"
        guard let url = URL(string: urlStr) else {
            completion([], [])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let series = Self.parseMarineHourlySeries(from: json)
            else {
                DispatchQueue.main.async { completion([], []) }
                return
            }

            let extrema = TideParser.extrema(from: series.times, heights: series.heights)
            let samples = TideCurveBuilder.samplesForToday(from: series.times, heights: series.heights)
            DispatchQueue.main.async { completion(extrema, samples) }
        }.resume()
    }

    private func fetchTideTurtleTides(lat: Double, lon: Double, completion: @escaping ([TideExtreme]) -> Void) {
        let urlStr = "https://tideturtle.com/api/v1/tides?lat=\(lat)&lon=\(lon)"
        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tides = json["tides"] as? [String: Any],
                  let dataObj = tides["data"] as? [String: Any],
                  let extrema = dataObj["extrema"] as? [[String: Any]]
            else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            var parsed: [TideExtreme] = []
            for item in extrema {
                guard let timeStr = item["time"] as? String,
                      let height = item["height"] as? Double,
                      let isHigh = item["isHigh"] as? Bool
                else { continue }

                var date = iso.date(from: timeStr)
                if date == nil {
                    iso.formatOptions = [.withInternetDateTime]
                    date = iso.date(from: timeStr)
                }
                guard let date else { continue }

                parsed.append(TideExtreme(
                    id: "\(isHigh ? "high" : "low")-\(Int(date.timeIntervalSince1970))",
                    time: date,
                    heightMeters: height,
                    isHigh: isHigh
                ))
            }

            DispatchQueue.main.async { completion(parsed) }
        }.resume()
    }

    private static func parseMarineHourlySeries(from json: [String: Any]) -> (times: [Date], heights: [Double])? {
        guard let hourly = json["hourly"] as? [String: Any],
              let timeStrings = hourly["time"] as? [String],
              let rawHeights = hourly["sea_level_height_msl"] as? [Any],
              !timeStrings.isEmpty
        else { return nil }

        let tzId = json["timezone"] as? String
        var times: [Date] = []
        var heights: [Double] = []

        for (timeString, raw) in zip(timeStrings, rawHeights) {
            guard let height = numericValue(raw),
                  let date = parseOpenMeteoDate(timeString, timeZoneId: tzId)
            else { continue }
            times.append(date)
            heights.append(height)
        }

        guard times.count >= 3 else { return nil }
        return (times, heights)
    }

    private static func numericValue(_ raw: Any) -> Double? {
        if let value = raw as? Double { return value }
        if let value = raw as? Int { return Double(value) }
        if let value = raw as? NSNumber { return value.doubleValue }
        return nil
    }

    private static func tidesForToday(_ extrema: [TideExtreme]) -> [TideExtreme] {
        let calendar = Calendar.current
        return extrema.filter { calendar.isDateInToday($0.time) }
    }

    /// Open-Meteo returns local times like `2026-06-16T06:58` (no seconds, no offset).
    static func parseOpenMeteoDate(_ string: String, timeZoneId: String?) -> Date? {
        let tz = TimeZone(identifier: timeZoneId ?? "") ?? .current
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
        ]
        for format in formats {
            let fmt = DateFormatter()
            fmt.dateFormat = format
            fmt.timeZone = tz
            if let date = fmt.date(from: string) { return date }
        }
        return nil
    }

    private static func pressureTrend(from json: [String: Any]) -> String {
        guard let hourly = json["hourly"] as? [String: Any],
              let times = hourly["time"] as? [String],
              let pressures = hourly["surface_pressure"] as? [Double],
              let current = json["current"] as? [String: Any],
              let nowPressure = current["surface_pressure"] as? Double,
              !times.isEmpty, !pressures.isEmpty
        else { return "—" }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        fmt.timeZone = (json["timezone"] as? String).flatMap(TimeZone.init(identifier:)) ?? .current
        let now = Date()
        let threeHoursAgo = now.addingTimeInterval(-3 * 3600)

        var closestPressure: Double?
        var closestDelta = TimeInterval.greatestFiniteMagnitude
        for (time, pressure) in zip(times, pressures) {
            guard let date = fmt.date(from: time) else { continue }
            let delta = abs(date.timeIntervalSince(threeHoursAgo))
            if delta < closestDelta {
                closestDelta = delta
                closestPressure = pressure
            }
        }

        guard let past = closestPressure else { return "—" }
        let diff = nowPressure - past
        if diff > 1.5 { return "RISING" }
        if diff < -1.5 { return "FALLING" }
        return "STEADY"
    }

    private static func currentPrecipitationProbability(from json: [String: Any]) -> Int {
        guard let hourly = json["hourly"] as? [String: Any],
              let times = hourly["time"] as? [String],
              let probs = hourly["precipitation_probability"] as? [Any],
              !times.isEmpty, !probs.isEmpty
        else { return 0 }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        fmt.timeZone = .current
        let hourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()

        var index = 0
        for (i, t) in times.enumerated() {
            guard let d = fmt.date(from: t) else { continue }
            if d >= hourStart {
                index = i
                break
            }
            index = i
        }

        guard index < probs.count else { return 0 }
        return Int((probs[index] as? Double) ?? Double(probs[index] as? Int ?? 0))
    }

    private static func precipitationInfo(code: Int, probability: Int, currentMm: Double) -> (label: String, icon: String) {
        let prob = max(0, min(100, probability))
        let label = "\(prob)%"

        if (95...99).contains(code) {
            return (label, "cloud.bolt.rain.fill")
        }
        if currentMm >= 0.1 || (51...82).contains(code) || prob >= 40 {
            return (label, "cloud.rain.fill")
        }
        return (label, "sun.min.fill")
    }

    private static func compassDirection(degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return directions[index]
    }

    private static func windIcon(speed: Double) -> String {
        speed >= 25 ? "wind.circle.fill" : "wind"
    }

    // WMO weather code → (label, SF Symbol)
    private static func weatherInfo(code: Int) -> (String, String) {
        switch code {
        case 0:       return ("CLEAR",        "sun.max.fill")
        case 1, 2:    return ("PARTLY CLOUDY","cloud.sun.fill")
        case 3:       return ("OVERCAST",     "cloud.fill")
        case 45, 48:  return ("FOG",          "cloud.fog.fill")
        case 51...67: return ("RAIN",         "cloud.rain.fill")
        case 71...77: return ("SNOW",         "snowflake")
        case 80...82: return ("SHOWERS",      "cloud.heavyrain.fill")
        case 95...99: return ("STORM",        "cloud.bolt.fill")
        default:      return ("CLEAR",        "sun.max.fill")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationWeatherManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.userCoordinate = loc.coordinate
        }
        reverseGeocodeIfNeeded(for: loc)
        refreshSolunarIfNeeded(for: loc)

        if let prev = lastFetchLocation, prev.distance(from: loc) < 5_000 { return }
        lastFetchLocation = loc
        fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
    }

    private func reverseGeocodeIfNeeded(for location: CLLocation) {
        if let last = lastGeocodedLocation,
           last.distance(from: location) < Self.geocodeMinDistance {
            return
        }
        let now = Date()
        if let lastAttempt = lastGeocodeAttemptTime,
           now.timeIntervalSince(lastAttempt) < Self.geocodeMinInterval {
            return
        }
        lastGeocodeAttemptTime = now

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let label = Self.locationLabel(from: placemarks?.first, coordinate: location.coordinate)
            DispatchQueue.main.async {
                self.locationName = label
                if placemarks?.first != nil {
                    self.lastGeocodedLocation = location
                }
            }
        }
    }

    private static func locationLabel(from placemark: CLPlacemark?, coordinate: CLLocationCoordinate2D) -> String {
        if let placemark {
            if let locality = placemark.locality, let area = placemark.administrativeArea {
                return "\(locality), \(area)"
            }
            if let name = placemark.name { return name }
            if let locality = placemark.locality { return locality }
        }
        return String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            if let loc = manager.location {
                refreshSolunarIfNeeded(for: loc)
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.weatherLabel = "NO LOCATION"
                self.weatherIcon  = "location.slash.fill"
                self.locationName = "Location unavailable"
                self.windLabel = "—"
                self.pressureLabel = "—"
                self.pressureTrendLabel = "—"
                self.precipitationLabel = "0%"
                self.precipitationIcon  = "sun.min.fill"
                self.solunarForecast = nil
                self.tideExtrema = []
                self.tideSamples = []
                self.solunarLoading = false
            }
        default:
            break
        }
    }
}

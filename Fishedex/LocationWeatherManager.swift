import Foundation
import CoreLocation
import Combine

// MARK: - Location + Weather manager

final class LocationWeatherManager: NSObject, ObservableObject {

    // Time
    @Published var timeLabel    = "LOADING..."
    @Published var timeIcon     = "sun.max.fill"

    // Weather — starts with a placeholder so the row always renders
    @Published var weatherLabel = "LOCATING..."
    @Published var weatherIcon  = "location.fill"

    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var locationName = "Locating..."

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var timer: AnyCancellable?
    private var lastFetchLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        refreshTime()
    }

    // MARK: Start / stop (call from onAppear/onDisappear)

    func start() {
        // Update time every 30 seconds
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

        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        let clock = fmt.string(from: Date()).uppercased()

        timeLabel = "\(label) · \(clock)"
        timeIcon  = icon
    }

    // MARK: Weather via Open-Meteo (free, no key required)

    private func fetchWeather(lat: Double, lon: Double) {
        let urlStr = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current_weather=true"
            + "&temperature_unit=celsius"
        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cw   = json["current_weather"] as? [String: Any],
                  let temp = cw["temperature"] as? Double,
                  let code = cw["weathercode"] as? Int
            else { return }

            let (label, icon) = Self.weatherInfo(code: code)
            DispatchQueue.main.async {
                self.weatherLabel = "\(label) · \(Int(temp.rounded()))°C"
                self.weatherIcon  = icon
            }
        }.resume()
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
        reverseGeocode(loc)
        // Only re-fetch if moved more than 5 km
        if let prev = lastFetchLocation, prev.distance(from: loc) < 5_000 { return }
        lastFetchLocation = loc
        fetchWeather(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let label = Self.locationLabel(from: placemarks?.first, coordinate: location.coordinate)
            DispatchQueue.main.async {
                self.locationName = label
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
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.weatherLabel = "NO LOCATION"
                self.weatherIcon  = "location.slash.fill"
                self.locationName = "Location unavailable"
            }
        default:
            break
        }
    }
}

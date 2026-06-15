import Foundation
import CoreLocation

struct SolunarCacheKey: Codable, Hashable {
    let calendarDay: String
    let latBucket: Double
    let lonBucket: Double

    static func from(coordinate: CLLocationCoordinate2D, date: Date = Date(), timeZone: TimeZone = .current) -> SolunarCacheKey {
        SolunarCacheKey(
            calendarDay: calendarDayString(for: date, timeZone: timeZone),
            latBucket: (coordinate.latitude * 100).rounded() / 100,
            lonBucket: (coordinate.longitude * 100).rounded() / 100
        )
    }

    static func calendarDayString(for date: Date, timeZone: TimeZone) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = timeZone
        return fmt.string(from: date)
    }
}

struct CachedSolunarDay: Codable {
    let key: SolunarCacheKey
    let forecast: SolunarDayForecast
    let tideExtrema: [TideExtreme]
    let cachedAt: Date
}

enum SolunarDayCache {
    private static let storageKey = "fishedex.solunarDayCache.v2"

    static func load(key: SolunarCacheKey) -> CachedSolunarDay? {
        guard let all = loadAll() else { return nil }
        return all.first { $0.key == key }
    }

    static func save(_ entry: CachedSolunarDay) {
        var all = loadAll() ?? []
        all.removeAll { $0.key == entry.key }
        all.append(entry)
        clearStale(in: &all)
        persist(all)
    }

    static func clearStale() {
        guard var all = loadAll() else { return }
        clearStale(in: &all)
        persist(all)
    }

    private static func clearStale(in entries: inout [CachedSolunarDay]) {
        let cutoff = Date().addingTimeInterval(-2 * 86_400)
        entries.removeAll { $0.cachedAt < cutoff }
    }

    private static func loadAll() -> [CachedSolunarDay]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode([CachedSolunarDay].self, from: data)
    }

    private static func persist(_ entries: [CachedSolunarDay]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

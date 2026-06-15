# Solunar & Fishing Times — Developer Notes

This document describes how Fishedex computes bite times, day ratings, tides, and caching. Implementation lives in `SolunarCalculator.swift`, `SolunarDayCache.swift`, and `LocationWeatherManager.swift`.

## Overview

```text
Core Location (lat/lon)
        │
        ├─► Open-Meteo Forecast ──► sunrise, sunset, live weather
        ├─► Open-Meteo Marine ────► hourly sea level → tide extrema
        └─► SolunarCalculator ────► moon events, periods, star rating
                    │
                    ▼
            SolunarDayCache (UserDefaults, per day + location)
```

Solunar data is **cached for the calendar day** at a given location bucket (~1 km). Weather stays live and is not part of the cached rating.

## Solunar periods (John Alden Knight)

Each day has four feeding windows:

| Type | Trigger | Window |
|------|---------|--------|
| **Major** | Moon overhead (transit) | ±1 hour (2 hr total) |
| **Major** | Moon underfoot (anti-transit) | ±1 hour |
| **Minor** | Moonrise | ±1 hour |
| **Minor** | Moonset | ±1 hour |

Windows match [FishingReminder](https://www.fishingreminder.com/) style (2-hour minor and major bands).

### Moon overhead / underfoot

We scan moon **azimuth** each minute (same idea as [SunCalc](https://github.com/mourner/suncalc) / [stevenmusumeche/solunar](https://github.com/stevenmusumeche/solunar)):

1. Compute moon azimuth and altitude from local Meeus-style ephemeris (`moonEquatorial`, `localSiderealTime`).
2. When azimuth changes sign (south ↔ north), the moon crosses the meridian.
3. Refine the crossing time with binary search on azimuth.
4. If altitude ≥ 0 at crossing → **overhead**; otherwise → **underfoot**.

### Moonrise / moonset

Sample moon altitude every 5 minutes across the calendar day (and ±1 day to catch edge cases). Detect horizon crossings (altitude 0°), refine with binary search.

## Day rating (1–5 stars)

Rating uses **solunar + tide only** — weather is shown separately and does not change stars.

**Base score (1–4):**

| Stars | Condition |
|-------|-----------|
| 1 | Ordinary day |
| 2 | Any period within ±1 h of sunrise or sunset |
| 3 | Full or New moon |
| 4 | Dawn/dusk overlap on Full or New moon |

**Tide bonus (+1, cap at 5):** Any major/minor period within ±1 h of a high or low tide extreme.

Labels: `SLOW DAY` → `FAIR DAY` → `GOOD DAY` → `EXCELLENT DAY` → `PEAK DAY`.

## External APIs (free, no keys)

| Data | Endpoint |
|------|----------|
| Weather, pressure, sun | `https://api.open-meteo.com/v1/forecast` |
| Tide curve | `https://marine-api.open-meteo.com/v1/marine?hourly=sea_level_height_msl` |

Open-Meteo returns local times as `yyyy-MM-dd'T'HH:mm` — parse with `LocationWeatherManager.parseOpenMeteoDate(_:timeZoneId:)`, not `ISO8601DateFormatter`.

Tide highs/lows are derived locally from hourly `sea_level_height_msl` (`TideParser.extrema`). Null or missing marine grid cells are skipped during parsing. If Open-Meteo Marine returns no usable data, [TideTurtle](https://tideturtle.com/developers) is used as a fallback (`GET /api/v1/tides?lat=&lon=`).

Cached entries with empty tides are automatically re-fetched on next launch.

If sun times fail to parse, `SolunarCalculator.estimatedSunrise/Sunset` provides a local solar fallback.

## Caching

```swift
SolunarCacheKey(calendarDay: "yyyy-MM-dd", latBucket: round(lat, 2), lonBucket: round(lon, 2))
```

Stored in UserDefaults under `fishedex.solunarDayCache.v3`. Invalidate by bumping the storage key when algorithms change.

## Key types

- `SolunarDayForecast` — periods, rating, sun/moon metadata
- `SolunarPeriod` — `kind` (major/minor), `start`, `end`
- `TideExtreme` — time, height, `isHigh`
- `CachedSolunarDay` — forecast + tides + cache key

## UI

- **Dashboard** (`FishingTimesBanner`): both major and both minor windows (two chips, stacked lines).
- **Detail sheet** (`FishingTimesDetailSheet`): full breakdown + educational copy.

## Accuracy expectations

Local astronomy is approximate vs commercial tables (FishingReminder, SunCalc). Typical drift is a few minutes. Minor times (moonrise/set) tend to match closely; transits depend on ephemeris precision.

## References

- [Solunar Theory](http://www.solunar.com/the_solunar_theory.aspx) — John Alden Knight
- [Jean Meeus, *Astronomical Algorithms*](https://www.willbell.com/math/mc1.htm) — lunar position formulas
- [Open-Meteo API](https://open-meteo.com/en/docs) — weather & sun
- [Open-Meteo Marine](https://open-meteo.com/en/docs/marine-weather-api) — sea level

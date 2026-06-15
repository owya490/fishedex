# Fishédex

Fishédex is a minimal SwiftUI iOS app for tracking fish like a Pokédex. The interface stays clean and modern while the fish artwork uses a pixel-art style.

## Getting Started

1. Open `Fishedex.xcodeproj` in Xcode.
2. Select the `Fishedex` scheme.
3. Choose an iPhone simulator.
4. Press Run.

## Current Screens

- Dashboard: A landing page with caught count, featured catch, recent catches, and lightweight fun stats.
- Fishédex List: A searchable list of available fish.
- Fish Detail: A reference-inspired detail page with a large fish hero, pill tabs, facts, stats, and moves.

## High-Level Components

- `Fishedex.xcodeproj`: The Xcode project file. It defines the app target, build settings, signing style, simulator/device support, and which source files/assets are included in the app.
- `Fishedex/FishedexApp.swift`: The app entry point. SwiftUI starts here and creates the first window for the app.
- `Fishedex/ContentView.swift`: The root tab/navigation shell. It hosts the dashboard and Fishédex list tabs and routes fish selections to the detail page.
- `Fishedex/Fish.swift`: The fish data model and current sample fish catalog.
- `Fishedex/FishedexTheme.swift`: Shared colors and card styling for the minimal UI direction.
- `Fishedex/DashboardView.swift`: Map tab, weather carousel, bite-times banner, and collection progress.
- `Fishedex/LocationWeatherManager.swift`: Location, Open-Meteo weather, and solunar cache orchestration.
- `Fishedex/SolunarCalculator.swift` + `Fishedex/SOLUNAR.md`: Local solunar bite times, ratings, and algorithm notes for developers.
- `Fishedex/FishedexListView.swift`: The searchable fish list and reusable row view.
- `Fishedex/FishDetailView.swift`: The detailed fish profile screen inspired by the uploaded reference.
- `Fishedex/FishArtworkView.swift`: Shared fish pixel-art rendering helpers.
- `Fishedex/Assets.xcassets`: The asset catalog. It contains app colors/icons and the bundled pixel fish images.
- `.gitignore`: Keeps generated Xcode, SwiftPM, and macOS files out of version control.

## Notes

- The bundle identifier is currently `com.example.fishedex`; update it in Xcode before shipping or running on a physical device.
- The deployment target is iOS 17.0.

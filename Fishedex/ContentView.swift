import SwiftUI

struct ContentView: View {
    private let fish = Fish.samples

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(fish: fish)
                    .navigationDestination(for: Fish.self) { fish in
                        FishDetailView(fish: fish)
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "heart.fill")
            }

            NavigationStack {
                CatchView()
            }
            .tabItem {
                Label("Catch", systemImage: "figure.fishing")
            }

            NavigationStack {
                FishedexListView(fish: fish)
                    .navigationDestination(for: Fish.self) { fish in
                        FishDetailView(fish: fish)
                    }
            }
            .tabItem {
                Label("Fishédex", systemImage: "list.bullet")
            }
        }
        .tint(FishedexTheme.ocean)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

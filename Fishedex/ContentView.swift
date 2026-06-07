import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .map
    private let fish = Fish.samples

    var body: some View {
        tabContent
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedTab != .catch_ {
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .map:
            MapTabView(fish: fish)
        case .catch_:
            CatchView(onBack: { selectedTab = .map })
        case .dex:
            DexView(fish: fish)
        }
    }
}

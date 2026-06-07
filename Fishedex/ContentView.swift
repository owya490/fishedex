import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var selectedTab: AppTab = .map

    var body: some View {
        Group {
            if session.isLoading {
                loadingView
            } else if session.isAuthenticated {
                authenticatedContent
            } else {
                AuthView()
            }
        }
        .sheet(isPresented: $session.showProfile) {
            ProfileView()
                .environmentObject(session)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Text("FISHÉDEX")
                .font(FishedexFont.header)
                .italic()
                .foregroundStyle(FishedexTheme.headerRed)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var authenticatedContent: some View {
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
            MapTabView(fish: session.fish)
        case .catch_:
            CatchView(onBack: { selectedTab = .map })
        case .dex:
            DexView(fish: session.fish)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}

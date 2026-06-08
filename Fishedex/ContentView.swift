import SwiftUI

private enum UnauthenticatedScreen: Equatable {
    case landing
    case login
    case signup
    case verifyEmail(email: String)
}

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var selectedTab: AppTab = .map
    @State private var hidesBottomTabBar = false
    @State private var unauthenticatedScreen: UnauthenticatedScreen = .landing

    var body: some View {
        Group {
            if session.isLoading {
                loadingView            } else if session.isAuthenticated {
                authenticatedContent
            } else {
                unauthenticatedContent
            }
        }
    }

    @ViewBuilder
    private var unauthenticatedContent: some View {
        switch unauthenticatedScreen {
        case .landing:
            LandingView(
                onLogin: { unauthenticatedScreen = .login },
                onSignUp: { unauthenticatedScreen = .signup }
            )
        case .login:
            AuthView(initialIsSignUp: false, onBack: { unauthenticatedScreen = .landing })
        case .signup:
            AuthView(
                initialIsSignUp: true,
                onBack: { unauthenticatedScreen = .landing },
                onSignUpSuccess: { email in
                    unauthenticatedScreen = .verifyEmail(email: email)
                }
            )
        case .verifyEmail(let email):
            VerifyEmailView(
                email: email,
                onBack: { unauthenticatedScreen = .signup },
                onVerified: { unauthenticatedScreen = .login }
            )
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
        ZStack {
            tabContent

            if session.showProfile {
                ProfileView()
                    .environmentObject(session)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.showProfile)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedTab != .catch_ && !session.showProfile && !hidesBottomTabBar {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }

    private func openCamera() {
        selectedTab = .catch_
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .map:
            MapTabView(fish: session.fish, onLogoTap: openCamera)
        case .catch_:
            CatchView(
                onBack: { selectedTab = .map },
                onCatchLogged: { selectedTab = .dex }
            )
        case .dex:
            DexView(
                fish: session.fish,
                hidesBottomTabBar: $hidesBottomTabBar,
                onLogoTap: openCamera
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}

import SwiftUI

private enum UnauthenticatedScreen: Equatable {
    case landing
    case login
    case signup
    case verifyEmail(email: String)
    case forgotPassword
    case forgotPasswordSent(email: String)
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
            AuthView(
                initialIsSignUp: false,
                onBack: { unauthenticatedScreen = .landing },
                onForgotPassword: { unauthenticatedScreen = .forgotPassword }
            )
        case .forgotPassword:
            ForgotPasswordView(
                onBack: { unauthenticatedScreen = .login },
                onEmailSent: { email in
                    unauthenticatedScreen = .forgotPasswordSent(email: email)
                }
            )
            .environmentObject(session)
        case .forgotPasswordSent(let email):
            ForgotPasswordSentView(
                email: email,
                onBack: { unauthenticatedScreen = .login }
            )
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

            if session.isPasswordRecoveryFlow {
                ResetPasswordView(context: .recovery)
                    .environmentObject(session)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.showProfile)
        .animation(.easeInOut(duration: 0.25), value: session.isPasswordRecoveryFlow)
        .animation(.easeOut(duration: 0.22), value: selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedTab != .catch_ && !session.showProfile && !session.isPasswordRecoveryFlow && !hidesBottomTabBar {
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
            .transition(.opacity)
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

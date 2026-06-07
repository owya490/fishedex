import SwiftUI

/// Shared red branded header used on MAP and DEX tabs.
struct AppHeaderView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        HStack(spacing: 0) {
            Text("FISHÉDEX")
                .font(FishedexFont.header)
                .italic()
                .foregroundStyle(.white)
                .kerning(0.5)

            Spacer()

            Button {
                session.showProfile = true
            } label: {
                ProfileAvatarView(urlString: session.profile?.avatarUrl, size: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open angler profile")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FishedexTheme.headerRed)
    }
}

#Preview {
    AppHeaderView()
        .environmentObject(SessionManager())
}

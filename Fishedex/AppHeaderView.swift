import SwiftUI

/// Unified red branded header used across all main screens.
struct AppHeaderView: View {
    @EnvironmentObject private var session: SessionManager

    var onBack: (() -> Void)? = nil
    var showsProfileButton: Bool = true
    var showsProfileAvatar: Bool = true

    private let slotSize: CGFloat = 36
    private let iconSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            leadingSlot
                .frame(width: leadingSlotSize, height: leadingSlotSize)

            Spacer()

            Text("FISHÉDEX")
                .font(FishedexFont.header)
                .italic()
                .foregroundStyle(.white)

            Spacer()

            trailingSlot
                .frame(width: showsProfileAvatar ? slotSize : leadingSlotSize, height: showsProfileAvatar ? slotSize : leadingSlotSize)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 6)
        .background(FishedexTheme.headerRed)
    }

    private var leadingSlotSize: CGFloat {
        onBack == nil ? iconSize : slotSize
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if let onBack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: slotSize, height: slotSize)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.black, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Go back")
        } else {
            Image("FishedexIcon")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var trailingSlot: some View {
        if showsProfileAvatar {
            let avatar = ProfileAvatarView(urlString: session.profile?.avatarUrl, size: slotSize)

            if showsProfileButton {
                Button {
                    session.showProfile = true
                } label: {
                    avatar
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open angler profile")
            } else {
                avatar
            }
        }
    }
}

#Preview("Default") {
    AppHeaderView()
        .environmentObject(SessionManager())
}

#Preview("With back") {
    AppHeaderView(onBack: {}, showsProfileButton: false)
        .environmentObject(SessionManager())
}

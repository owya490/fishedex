import SwiftUI

/// Unified red branded header used across all main screens.
struct AppHeaderView: View {
    @EnvironmentObject private var session: SessionManager

    var onBack: (() -> Void)? = nil
    var showsProfileButton: Bool = true
    var showsProfileAvatar: Bool = true

    private let slotSize: CGFloat = 32
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
        .padding(.vertical, 2)
        .background(FishedexTheme.headerRed)
    }

    private var leadingSlotSize: CGFloat {
        onBack == nil ? iconSize : slotSize
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if let onBack {
            FishedexBackButton(action: onBack, style: .header, size: slotSize)
        } else {
            Image("FishedexIcon")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: iconSize * 1.2, height: iconSize * 1.2)
                .frame(width: iconSize, height: iconSize)
                .clipped()
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

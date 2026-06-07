import SwiftUI

/// Unified red branded header used across all main screens.
struct AppHeaderView: View {
    @EnvironmentObject private var session: SessionManager

    var onBack: (() -> Void)? = nil
    var onLogoTap: (() -> Void)? = nil
    var showsProfileButton: Bool = true
    var showsProfileAvatar: Bool = true
    var isBackDisabled: Bool = false

    private let slotSize: CGFloat = 32
    private let iconSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 12) {
            leadingSlot
                .frame(width: leadingSlotWidth, height: iconSize)

            Spacer()

            Text("FISHÉDEX")
                .font(FishedexFont.header)
                .italic()
                .foregroundStyle(.white)

            Spacer()

            trailingSlot
                .frame(width: showsProfileAvatar ? slotSize : leadingSlotWidth, height: showsProfileAvatar ? slotSize : iconSize)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .background(FishedexTheme.headerRed)
    }

    private var leadingSlotWidth: CGFloat {
        onBack == nil ? iconSize : slotSize
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if let onBack {
            FishedexBackButton(action: onBack, style: .header, size: slotSize, isDisabled: isBackDisabled)
        } else if let onLogoTap {
            Button(action: onLogoTap) {
                logoImage
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open camera")
        } else {
            logoImage
        }
    }

    private var logoImage: some View {
        Image("FishedexIcon")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: iconSize * 1.2, height: iconSize * 1.2)
            .frame(width: iconSize, height: iconSize)
            .clipped()
            .accessibilityHidden(true)
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

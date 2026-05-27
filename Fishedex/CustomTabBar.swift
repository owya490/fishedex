import SwiftUI

enum AppTab {
    case map, catch_, dex
}

/// Custom three-button tab bar matching the MAP / CATCH / DEX design.
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 10) {
            TabBarButton(
                title: "MAP",
                icon: "map.fill",
                isActive: selectedTab == .map,
                activeColor: FishedexTheme.tabBlue
            ) { selectedTab = .map }

            TabBarButton(
                title: "CATCH",
                icon: "camera.fill",
                isActive: selectedTab == .catch_,
                activeColor: FishedexTheme.tabGreen,
                hasBadge: true
            ) { selectedTab = .catch_ }

            TabBarButton(
                title: "DEX",
                icon: "doc.text.fill",
                isActive: selectedTab == .dex,
                activeColor: FishedexTheme.tabBlue
            ) { selectedTab = .dex }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color(red: 0.92, green: 0.92, blue: 0.93))
    }
}

private struct TabBarButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let activeColor: Color
    var hasBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isActive ? .white : FishedexTheme.muted)

                    if hasBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                            .offset(x: 4, y: -3)
                    }
                }

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? .white : FishedexTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isActive ? activeColor : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: isActive ? activeColor.opacity(0.30) : Color.black.opacity(0.05),
                radius: 6, x: 0, y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

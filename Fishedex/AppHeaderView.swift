import SwiftUI

/// Shared red branded header used on MAP and DEX tabs.
struct AppHeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("FISHEDEX")
                .font(.system(size: 22, weight: .heavy, design: .default))
                .italic()
                .foregroundStyle(.white)
                .kerning(0.5)

            Spacer()

            LogoBadge()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FishedexTheme.headerRed)
    }
}

private struct LogoBadge: View {
    var body: some View {
        Image(systemName: "fish.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(FishedexTheme.headerRed)
            .frame(width: 44, height: 44)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

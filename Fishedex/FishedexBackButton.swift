import SwiftUI

/// Round back button used across the app.
struct FishedexBackButton: View {
    enum Style {
        case header
        case overlay

        var backgroundColor: Color {
            switch self {
            case .header:  Color.black.opacity(0.25)
            case .overlay: Color.black.opacity(0.65)
            }
        }
    }

    let action: () -> Void
    var style: Style = .header
    var size: CGFloat = 32
    var iconSize: CGFloat = 14

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(style.backgroundColor)
                .fishedexCircle()
                .fishedexCircleBorder(lineWidth: 2, color: .black)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go back")
    }
}

#Preview("Header") {
    FishedexBackButton(action: {})
        .padding()
        .background(FishedexTheme.headerRed)
}

#Preview("Overlay") {
    FishedexBackButton(action: {}, style: .overlay)
        .padding()
        .background(Color.gray)
}

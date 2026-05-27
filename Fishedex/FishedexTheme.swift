import SwiftUI

enum FishedexTheme {
    // Base palette
    static let background  = Color.white
    static let card        = Color(red: 0.98, green: 0.98, blue: 0.97)
    static let ink         = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let muted       = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let softLine    = Color.black.opacity(0.06)
    static let cream       = Color(red: 1.0,  green: 0.96, blue: 0.82)
    static let ocean       = Color(red: 0.17, green: 0.54, blue: 0.70)
    static let coral       = Color(red: 1.0,  green: 0.40, blue: 0.48)

    // Brand / UI chrome
    static let headerRed   = Color(red: 0.82, green: 0.15, blue: 0.13)
    static let tabGreen    = Color(red: 0.26, green: 0.75, blue: 0.39)
    static let tabBlue     = Color(red: 0.24, green: 0.48, blue: 0.85)
    static let progressGreen = Color(red: 0.20, green: 0.78, blue: 0.36)

    static func accent(for fish: Fish) -> Color {
        switch fish.id {
        case 1:  return Color(red: 0.26, green: 0.58, blue: 0.67)
        case 2:  return Color(red: 0.96, green: 0.42, blue: 0.58)
        case 3:  return Color(red: 0.95, green: 0.80, blue: 0.18)
        case 4:  return Color(red: 0.28, green: 0.46, blue: 0.52)
        default: return Color(red: 0.93, green: 0.70, blue: 0.18)
        }
    }
}

extension View {
    func fishedexCard(cornerRadius: CGFloat = 28) -> some View {
        self
            .background(FishedexTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 12)
    }
}

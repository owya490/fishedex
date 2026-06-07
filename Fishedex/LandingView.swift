import SwiftUI

struct LandingView: View {
    let onLogin: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            LandingHeroIllustration()
                .padding(.horizontal, 32)

            Spacer()
                .frame(height: 36)

            VStack(spacing: 14) {
                Text("CAST OFF ON YOUR\nFISHÉDEX JOURNEY")
                    .font(FishedexFont.pokemon(20))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(FishedexTheme.ink)
                    .lineSpacing(4)

                Text("Your Pokédex for fishing.\nCatch 'em all.")
                    .font(FishedexFont.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(FishedexTheme.muted)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 12) {
                LandingButton(title: "SIGN UP", style: .primary, action: onSignUp)
                LandingButton(title: "LOG IN", style: .secondary, action: onLogin)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    FishedexTheme.cream.opacity(0.55),
                    Color.white,
                    Color.white
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Hero illustration

private struct LandingHeroIllustration: View {
    var body: some View {
        ZStack {
            PixelSparkle(color: FishedexTheme.ocean.opacity(0.45), offset: CGSize(width: -118, height: -108))
            PixelSparkle(color: FishedexTheme.coral.opacity(0.5), offset: CGSize(width: 122, height: -92), size: 6)
            PixelSparkle(color: FishedexTheme.tabGreen.opacity(0.55), offset: CGSize(width: -96, height: 108), size: 5)
            PixelSparkle(color: FishedexTheme.tabBlue.opacity(0.4), offset: CGSize(width: 108, height: 100))

            WobblingFishTile(
                imageName: "AustralianSalmon",
                tint: FishedexTheme.ocean.opacity(0.22),
                size: 60,
                fishHeight: 34,
                baseOffset: CGSize(width: -92, height: -50),
                driftX: 7, driftY: 5, wobbleDegrees: 4, speed: 1.1, phase: 0
            )

            WobblingFishTile(
                imageName: "PinkSnapper",
                tint: FishedexTheme.coral.opacity(0.26),
                size: 56,
                fishHeight: 30,
                baseOffset: CGSize(width: 96, height: -56),
                driftX: 6, driftY: 6, wobbleDegrees: 5, speed: 1.35, phase: 1.4
            )

            WobblingFishTile(
                imageName: "YellowfinBream",
                tint: FishedexTheme.cream,
                size: 54,
                fishHeight: 28,
                baseOffset: CGSize(width: -84, height: 64),
                driftX: 5, driftY: 7, wobbleDegrees: 3.5, speed: 0.95, phase: 2.8
            )

            WobblingFishTile(
                imageName: "ShortFinnedEel",
                tint: FishedexTheme.tabBlue.opacity(0.18),
                size: 58,
                fishHeight: 32,
                baseOffset: CGSize(width: 88, height: 60),
                driftX: 6, driftY: 5, wobbleDegrees: 4.5, speed: 1.2, phase: 4.2
            )

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FishedexTheme.cream.opacity(0.55),
                                FishedexTheme.cream.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 68
                        )
                    )
                    .frame(width: 136, height: 136)

                Image("FishedexIcon")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 124, height: 124)
            }
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .frame(height: 280)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fishédex collection preview with pixel fish artwork")
    }
}

private struct WobblingFishTile: View {
    let imageName: String
    let tint: Color
    let size: CGFloat
    let fishHeight: CGFloat
    let baseOffset: CGSize
    let driftX: CGFloat
    let driftY: CGFloat
    let wobbleDegrees: Double
    let speed: Double
    let phase: Double

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            FishTile(
                imageName: imageName,
                tint: tint,
                size: size,
                fishHeight: fishHeight
            )
            .offset(
                x: baseOffset.width + CGFloat(sin(time * speed + phase)) * driftX,
                y: baseOffset.height + CGFloat(cos(time * speed * 0.9 + phase * 1.2)) * driftY
            )
            .rotationEffect(
                .degrees(sin(time * speed * 0.75 + phase * 0.6) * wobbleDegrees)
            )
        }
    }
}

private struct FishTile: View {
    let imageName: String
    let tint: Color
    let size: CGFloat
    let fishHeight: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(tint)
                .frame(width: size, height: size)

            Image(imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(height: fishHeight)
        }
        .shadow(color: tint.opacity(0.85), radius: 12, x: 0, y: 6)
    }
}

private struct PixelSparkle: View {
    var color: Color = FishedexTheme.tabGreen.opacity(0.55)
    var offset: CGSize
    var size: CGFloat = 7

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(offset)
    }
}

// MARK: - Buttons

private struct LandingButton: View {
    enum Style { case primary, secondary }

    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FishedexFont.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(style == .primary ? FishedexTheme.headerRed : Color.white)
                .foregroundStyle(style == .primary ? .white : FishedexTheme.ink)
                .fishedexSquare()
                .fishedexBorder()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LandingView(onLogin: {}, onSignUp: {})
}

import SwiftUI

struct VerifyEmailView: View {
    let email: String
    let onBack: () -> Void
    let onVerified: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: onBack, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("VERIFY YOUR EMAIL")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.ink)

                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(FishedexTheme.ocean)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("We sent a confirmation link to:")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)

                        Text(email)
                            .font(FishedexFont.headline)
                            .foregroundStyle(FishedexTheme.ink)
                            .textSelection(.enabled)

                        Text("Open the email from Supabase and tap the link to verify your account. If you don't see it, check your spam or junk folder.")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)
                            .lineSpacing(4)
                    }

                    Button(action: onVerified) {
                        HStack {
                            Spacer()
                            Text("I'VE VERIFIED")
                                .font(FishedexFont.headline)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(FishedexTheme.headerRed)
                        .foregroundStyle(.white)
                        .fishedexSquare()
                        .fishedexBorder()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    VerifyEmailView(email: "angler@example.com", onBack: {}, onVerified: {})
}

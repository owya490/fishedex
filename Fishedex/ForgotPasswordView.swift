import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var session: SessionManager

    let onBack: () -> Void
    let onEmailSent: (String) -> Void

    @State private var email = ""
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: onBack, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("RESET PASSWORD")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.ink)

                    Text("Enter the email for your angler account and we'll send a reset link.")
                        .font(FishedexFont.body)
                        .foregroundStyle(FishedexTheme.muted)
                        .lineSpacing(4)

                    authField("EMAIL", text: $email, contentType: .emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    if let error = session.errorMessage {
                        Text(error)
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.headerRed)
                    }

                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("SEND RESET LINK")
                                    .font(FishedexFont.headline)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(FishedexTheme.headerRed)
                        .foregroundStyle(.white)
                        .fishedexSquare()
                        .fishedexBorder()
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting || !canSubmit)
                }
                .padding(24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func authField(_ label: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            TextField("", text: text)
                .font(FishedexFont.body)
                .textContentType(contentType)
                .padding(12)
                .background(Color.white)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                try await session.requestPasswordReset(email: trimmedEmail)
                onEmailSent(trimmedEmail)
            } catch {
                session.errorMessage = error.localizedDescription
            }
        }
    }
}

struct ForgotPasswordSentView: View {
    let email: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: onBack, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("CHECK YOUR EMAIL")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.ink)

                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(FishedexTheme.ocean)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("We sent a password reset link to:")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)

                        Text(email)
                            .font(FishedexFont.headline)
                            .foregroundStyle(FishedexTheme.ink)
                            .textSelection(.enabled)

                        Text("Open the email and tap the link to reset your password. The link will open Fishedex so you can choose a new password.")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)
                            .lineSpacing(4)
                    }
                }
                .padding(24)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    ForgotPasswordView(onBack: {}, onEmailSent: { _ in })
        .environmentObject(SessionManager())
}

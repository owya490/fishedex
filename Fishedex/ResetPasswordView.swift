import SwiftUI

enum PasswordResetContext {
    case recovery
    case settings
}

struct ResetPasswordView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    let context: PasswordResetContext
    var onComplete: (() -> Void)? = nil

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var didSucceed = false

    var body: some View {
        VStack(spacing: 0) {
            if context == .settings {
                AppHeaderView(onBack: { dismiss() }, showsProfileButton: false, showsProfileAvatar: false)
            } else {
                AppHeaderView(showsProfileButton: false, showsProfileAvatar: false)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if context == .recovery {
                        Text("CHOOSE NEW PASSWORD")
                            .font(FishedexFont.title)
                            .foregroundStyle(FishedexTheme.ink)

                        Text("You're almost back on the water. Enter a new password for your account.")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)
                            .lineSpacing(4)
                    } else {
                        Text("CHANGE PASSWORD")
                            .font(FishedexFont.title)
                            .foregroundStyle(FishedexTheme.ink)

                        Text("Pick a new password with at least 6 characters.")
                            .font(FishedexFont.body)
                            .foregroundStyle(FishedexTheme.muted)
                            .lineSpacing(4)
                    }

                    authField("NEW PASSWORD", text: $password, contentType: .newPassword)
                        .textInputAutocapitalization(.never)

                    authField("CONFIRM PASSWORD", text: $confirmPassword, contentType: .newPassword)
                        .textInputAutocapitalization(.never)

                    if let error = session.errorMessage {
                        Text(error)
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.headerRed)
                    }

                    if didSucceed {
                        Text("Password updated successfully.")
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.ocean)
                    }

                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(context == .recovery ? "UPDATE PASSWORD" : "SAVE PASSWORD")
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
        .background(context == .recovery ? Color.white.ignoresSafeArea() : Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(context == .settings)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var canSubmit: Bool {
        password.count >= 6 && password == confirmPassword
    }

    private func authField(_ label: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            SecureField("", text: text)
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
                try await session.updatePassword(password)
                didSucceed = true
                if context == .recovery {
                    session.completePasswordRecovery()
                    onComplete?()
                } else {
                    try? await Task.sleep(for: .milliseconds(600))
                    dismiss()
                }
            } catch {
                session.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ResetPasswordView(context: .recovery)
        .environmentObject(SessionManager())
}

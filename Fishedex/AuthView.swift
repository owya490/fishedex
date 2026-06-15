import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var session: SessionManager

    var initialIsSignUp: Bool = false
    var onBack: (() -> Void)? = nil
    var onSignUpSuccess: ((String) -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: onBack, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(isSignUp ? "CREATE ANGLER ID" : "ANGLER LOGIN")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.ink)

                    if isSignUp {
                        authField("DISPLAY NAME", text: $displayName, contentType: .name)
                    }

                    authField("EMAIL", text: $email, contentType: .emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    authField("PASSWORD", text: $password, contentType: .password)
                        .textInputAutocapitalization(.never)

                    if !isSignUp {
                        Button {
                            session.errorMessage = nil
                            onForgotPassword?()
                        } label: {
                            Text("Forgot password?")
                                .font(FishedexFont.caption)
                                .foregroundStyle(FishedexTheme.ocean)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

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
                                Text(isSignUp ? "SIGN UP" : "SIGN IN")
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

                    Button {
                        isSignUp.toggle()
                        session.errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign in" : "New angler? Create account")
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.ocean)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            isSignUp = initialIsSignUp
        }
        .onChange(of: initialIsSignUp) { _, newValue in
            isSignUp = newValue
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && (!isSignUp || !displayName.isEmpty)
    }

    private func authField(_ label: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            TextField("", text: text)
                .font(FishedexFont.body)
                .fishedexInputText()
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
                if isSignUp {
                    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    try await session.signUp(
                        email: trimmedEmail,
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    onSignUpSuccess?(trimmedEmail)
                } else {
                    try await session.signIn(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                }
            } catch {
                session.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionManager())
}

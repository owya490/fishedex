import SwiftUI

private enum AccountSettingsDestination: Hashable {
    case changePassword
    case deleteAccount
}

struct AccountSettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var destination: AccountSettingsDestination?

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() }, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Text("ACCOUNT")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    settingsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $destination) { item in
            switch item {
            case .changePassword:
                ResetPasswordView(context: .settings)
                    .environmentObject(session)
            case .deleteAccount:
                DeleteAccountView()
                    .environmentObject(session)
            }
        }
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingsRow(
                title: "CHANGE PASSWORD",
                subtitle: "Update your sign-in password",
                icon: "lock.rotation",
                isDestructive: false
            ) {
                destination = .changePassword
            }

            divider

            settingsRow(
                title: "DELETE ACCOUNT",
                subtitle: "Permanently remove your angler profile",
                icon: "trash",
                isDestructive: true
            ) {
                destination = .deleteAccount
            }
        }
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var divider: some View {
        Rectangle()
            .fill(FishedexTheme.muted.opacity(0.2))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        icon: String,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isDestructive ? FishedexTheme.headerRed : FishedexTheme.ocean)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FishedexFont.headline)
                        .foregroundStyle(isDestructive ? FishedexTheme.headerRed : FishedexTheme.ink)
                    Text(subtitle)
                        .font(FishedexFont.caption)
                        .foregroundStyle(FishedexTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FishedexTheme.muted)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

struct DeleteAccountView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showFinalAlert = false

    private let requiredConfirmation = "DELETE"

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(onBack: { dismiss() }, showsProfileButton: false, showsProfileAvatar: false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("DELETE ACCOUNT")
                        .font(FishedexFont.title)
                        .foregroundStyle(FishedexTheme.headerRed)

                    Text("This permanently deletes your profile, catches, photos, achievements, and friendships. This cannot be undone.")
                        .font(FishedexFont.body)
                        .foregroundStyle(FishedexTheme.muted)
                        .lineSpacing(4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TYPE \"\(requiredConfirmation)\" TO CONFIRM")
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.muted)

                        TextField("", text: $confirmationText)
                            .font(FishedexFont.body)
                            .fishedexInputText()
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color.white)
                            .fishedexSquare()
                            .fishedexBorder(lineWidth: 1)
                    }

                    if let error = session.errorMessage {
                        Text(error)
                            .font(FishedexFont.caption)
                            .foregroundStyle(FishedexTheme.headerRed)
                    }

                    Button {
                        showFinalAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView().tint(.white)
                            } else {
                                Text("DELETE MY ACCOUNT")
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
                    .disabled(isDeleting || confirmationText != requiredConfirmation)
                }
                .padding(24)
            }
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Delete account?", isPresented: $showFinalAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Your account and all associated data will be permanently removed.")
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            defer { isDeleting = false }
            await session.deleteAccount()
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
            .environmentObject(SessionManager())
    }
}

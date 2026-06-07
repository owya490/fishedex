import SwiftUI

@main
struct FishedexApp: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .task { await session.bootstrap() }
                .onOpenURL { url in
                    Task {
                        do {
                            try await supabase.auth.session(from: url)
                            await session.refreshUserData()
                        } catch {
                            session.errorMessage = error.localizedDescription
                        }
                    }
                }
        }
    }
}

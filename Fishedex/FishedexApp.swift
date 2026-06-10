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
                    Task { await session.handleAuthDeepLink(url) }
                }
        }
    }
}

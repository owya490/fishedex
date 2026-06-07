import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://kfjmzsukylthtstjmmcz.supabase.co")!
    static let publishableKey = "sb_publishable_QDS05gsNaqGrU3KYQbjBwA_VZRvHZbu"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.publishableKey,
    options: SupabaseClientOptions(
        auth: .init(
            redirectToURL: URL(string: "fishedex://login-callback"),
            flowType: .pkce
        )
    )
)

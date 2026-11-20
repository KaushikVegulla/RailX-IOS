import Foundation

/// Connection details for the shared RailX Supabase backend.
/// These are the SAME defaults RailX Android ships with (see
/// app/build.gradle.kts in the Android repo): the publishable key is
/// client configuration, safe to ship because Row Level Security
/// protects every table. The secret / service_role key must NEVER
/// be put in this app.
public struct RailXBackendConfig: Sendable {
    public let url: URL
    public let publishableKey: String

    public init(url: URL, publishableKey: String) {
        self.url = url
        self.publishableKey = publishableKey
    }

    public var isConfigured: Bool { !publishableKey.isEmpty }

    /// The live RailX project (etaaufimazvjdmpladom, ap-northeast-2) —
    /// same project, tables, RLS policies and users as Android.
    public static let live = RailXBackendConfig(
        url: URL(string: "https://etaaufimazvjdmpladom.supabase.co")!,
        publishableKey: "sb_publishable_XmViLB5DeAomuqBFzv4R8A_UFQNOZYY"
    )

    /// For tests / previews: an unconfigured backend.
    public static let unconfigured = RailXBackendConfig(
        url: URL(string: "https://etaaufimazvjdmpladom.supabase.co")!,
        publishableKey: ""
    )
}

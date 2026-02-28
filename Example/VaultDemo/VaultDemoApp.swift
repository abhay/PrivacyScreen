import SwiftUI
import PrivacyScreen

// MARK: - VaultDemoApp

@main
struct VaultDemoApp: App {
    @StateObject private var privacyManager = PrivacyManager()
    @StateObject private var powerThrottler = PowerThrottler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(privacyManager)
                .environmentObject(powerThrottler)
                .onAppear {
                    privacyManager.startMonitoring(externalMotion: true)
                    powerThrottler.attach(to: privacyManager, arSession: privacyManager.arSession)
                    powerThrottler.start()
                }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var privacyManager: PrivacyManager

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    DashboardView()
                        .navigationTitle("Dashboard")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

                NavigationStack {
                    AccountsView()
                        .navigationTitle("Accounts")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Accounts", systemImage: "building.columns.fill")
                }

                NavigationStack {
                    TransactionsView()
                        .navigationTitle("Activity")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Activity", systemImage: "arrow.left.arrow.right")
                }

                NavigationStack {
                    CardView()
                        .navigationTitle("Cards")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }

                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .tint(VaultTheme.accent)

            // Privacy overlays
            PrivacyShieldOverlay()

            if privacyManager.showDebugOverlay {
                PrivacyDebugOverlay()
                PowerDebugView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

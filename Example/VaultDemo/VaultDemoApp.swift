import PrivacyScreen
import SwiftUI

// MARK: - VaultDemoApp

@main
struct VaultDemoApp: App {
    @StateObject private var privacyManager = PrivacyManager()
    @StateObject private var powerThrottler = PowerThrottler()
    @StateObject private var demoRunner = DemoRunner()

    private var launchArgs: Set<String> {
        Set(ProcessInfo.processInfo.arguments)
    }

    private var isDemoMode: Bool {
        launchArgs.contains("-demo")
    }

    private var isScreenshotMode: Bool {
        launchArgs.contains("-screenshots")
    }

    var body: some Scene {
        WindowGroup {
            if isDemoMode || isScreenshotMode {
                DemoContentView()
                    .environmentObject(privacyManager)
                    .environmentObject(demoRunner)
                    .onAppear {
                        demoRunner.showCaptions = !isScreenshotMode
                        demoRunner.start(privacyManager: privacyManager)
                    }
            } else {
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
}

// MARK: - DemoContentView

/// Demo-mode root view: dashboard only, no tab bar or debug overlays, plus caption overlay.
struct DemoContentView: View {
    @EnvironmentObject private var privacyManager: PrivacyManager
    @EnvironmentObject private var demoRunner: DemoRunner

    var body: some View {
        ZStack {
            NavigationStack {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }

            PrivacyShieldOverlay()
            DemoCaptionOverlay(caption: demoRunner.caption)
        }
        .preferredColorScheme(.dark)
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

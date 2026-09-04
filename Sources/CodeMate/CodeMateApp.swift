import SwiftUI
import SwiftData

@main
struct CodeMateApp: App {
    @State private var preferences = AppPreferences()
    @State private var licenseManager = LicenseManager()
    @State private var practiceCall = PracticeCallCoordinator()
    // StoreManager is kept in the project but left unwired for now -- it's
    // only meaningful for a Mac App Store-distributed build (StoreKit needs
    // an App Store receipt). This build is sold directly, so LicenseManager
    // is the real entitlement source. Wire StoreManager back in (and swap
    // Paywall/gating to it) if/when there's a separate App Store SKU.

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ProblemProgress.self, WhiteboardDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create CodeMate's local data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 1040, minHeight: 720)
                .environment(preferences)
                .environment(licenseManager)
                .environment(practiceCall)
        }
        .modelContainer(sharedModelContainer)
        .windowResizability(.automatic)
        .defaultSize(width: 1360, height: 840)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .frame(width: 520, height: 660)
                .environment(preferences)
                .environment(licenseManager)
        }
    }
}

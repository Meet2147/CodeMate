import SwiftUI
import SwiftData

@main
struct CodeMateApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ProblemProgress.self])
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
                .frame(width: 480, height: 420)
        }
    }
}

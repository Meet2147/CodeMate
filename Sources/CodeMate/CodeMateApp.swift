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
                .frame(minWidth: 1180, minHeight: 760)
        }
        .modelContainer(sharedModelContainer)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .frame(width: 480, height: 420)
        }
    }
}

import SwiftUI
import SwiftData

@main
struct ResonanceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PlayEvent.self,
            DailySnapshot.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let tracker: PlaybackTracker

    init() {
        tracker = PlaybackTracker(modelContainer: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await tracker.start() }
        }
        .modelContainer(sharedModelContainer)
    }
}
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

    #if targetEnvironment(simulator)
    private let tracker: MockPlaybackTracker
    #else
    private let tracker: PlaybackTracker
    #endif

    init() {
        #if targetEnvironment(simulator)
        tracker = MockPlaybackTracker(modelContainer: sharedModelContainer)
        #else
        tracker = PlaybackTracker(modelContainer: sharedModelContainer)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await tracker.start() }
        }
        .modelContainer(sharedModelContainer)
    }
}

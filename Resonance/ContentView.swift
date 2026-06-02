import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \PlayEvent.playedAt, order: .reverse) private var events: [PlayEvent]
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            NavigationStack {
                ScrollView {
                    ListeningHeatmapView(cells: viewModel.heatmap)
                        .padding()
                }
                .navigationTitle("Heatmap")
            }
            .tabItem {
                Label("Heatmap", systemImage: "calendar")
            }

            TimeMachineView()
                .tabItem {
                    Label("Time Machine", systemImage: "clock")
                }

            WrappedView()
                .tabItem {
                    Label("Wrapped", systemImage: "gift")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note")
                }
        }
        .environment(viewModel)
        .task {
            await viewModel.load(events: events)
        }
        .onChange(of: events.count) {
            Task { await viewModel.load(events: events) }
        }
    }
}

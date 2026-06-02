//
//  AnalyticsViewModel.swift
//  Resonance
//

import Foundation
import Observation

@MainActor
@Observable
final class AnalyticsViewModel {

    // MARK: - Exposed state
    //
    // @Observable tracks every stored var automatically; @Published is a
    // Combine/ObservableObject concept and is not used with this macro.
    // private(set) keeps writes internal while views observe reads freely.

    private(set) var topArtists:            [(name: String, count: Int)] = []
    private(set) var topGenres:             [(name: String, count: Int)] = []
    private(set) var heatmap:               [HeatmapCell]                = []
    private(set) var totalListeningSeconds: Double                        = 0
    private(set) var isLoading:             Bool                          = false

    // MARK: - Engine

    private var engine: AnalyticsEngine?

    // MARK: - Load

    /// Rebuilds the engine from `events`, runs all analytics in parallel,
    /// and publishes results. Safe to call repeatedly; each call replaces the
    /// previous engine and overwrites the previous results.
    func load(events: [PlayEvent]) async {
        isLoading = true

        // Capture locally so a re-entrant load call can't swap engine mid-flight.
        let current = AnalyticsEngine(events: events)
        engine = current

        let result = await current.computeAll()

        topArtists            = result.topArtists
        topGenres             = result.topGenres
        heatmap               = result.heatmap
        totalListeningSeconds = result.totalListeningSeconds
        isLoading             = false
    }
}

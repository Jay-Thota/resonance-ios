//
//  AnalyticsEngine.swift
//  Resonance
//

import Foundation

// MARK: - Public output types

struct HeatmapCell: Sendable, Identifiable {
    let weekday: Int    // 1 (Sun) … 7 (Sat), matching Calendar's weekday component
    let hour: Int       // 0 … 23
    let intensity: Double  // 0.0 … 1.0, normalised across all 168 cells

    var id: String { "\(weekday)-\(hour)" }
}

struct AnalyticsResult: Sendable {
    let topArtists: [(name: String, count: Int)]
    let topGenres: [(name: String, count: Int)]
    let heatmap: [HeatmapCell]
    let totalListeningSeconds: Double
}

// MARK: - Actor

actor AnalyticsEngine {

    // Sendable snapshot extracted from PlayEvent at init time, before actor isolation begins.
    private struct EventRecord: Sendable {
        let artistName: String
        let genreName: String
        let playedAt: Date
        let durationSeconds: Int

        init(_ event: PlayEvent) {
            artistName      = event.artistName
            genreName       = event.genreName
            playedAt        = event.playedAt
            durationSeconds = event.durationSeconds
        }
    }

    // Discriminated-union used to collect TaskGroup results in order-independent fashion.
    private enum ComputeResult: Sendable {
        case artists([(name: String, count: Int)])
        case genres([(name: String, count: Int)])
        case heatmap([HeatmapCell])
        case totalSeconds(Double)
    }

    private let events: [EventRecord]

    init(events: [PlayEvent]) {
        // Extraction is synchronous here; no actor boundary is crossed yet.
        self.events = events.map(EventRecord.init)
    }

    // MARK: - Individual async methods

    func topArtists(limit: Int = 10) async -> [(name: String, count: Int)] {
        Self.computeTopArtists(events: events, limit: limit)
    }

    func topGenres(limit: Int = 10) async -> [(name: String, count: Int)] {
        Self.computeTopGenres(events: events, limit: limit)
    }

    func listeningHeatmap() async -> [HeatmapCell] {
        Self.computeHeatmap(events: events)
    }

    func totalListeningSeconds() async -> Double {
        Self.computeTotalSeconds(events: events)
    }

    // MARK: - Parallel aggregate

    /// Runs all four computations concurrently via TaskGroup and returns them bundled.
    /// TaskGroup child tasks receive a Sendable [EventRecord] snapshot and call
    /// static (non-actor-isolated) helpers, so they genuinely execute in parallel.
    func computeAll(artistLimit: Int = 10, genreLimit: Int = 10) async -> AnalyticsResult {
        let snap = events   // copy out of actor isolation before entering the group

        return await withTaskGroup(of: ComputeResult.self) { group in
            group.addTask { .artists(Self.computeTopArtists(events: snap, limit: artistLimit)) }
            group.addTask { .genres(Self.computeTopGenres(events: snap, limit: genreLimit)) }
            group.addTask { .heatmap(Self.computeHeatmap(events: snap)) }
            group.addTask { .totalSeconds(Self.computeTotalSeconds(events: snap)) }

            var artists:      [(name: String, count: Int)] = []
            var genres:       [(name: String, count: Int)] = []
            var heatmap:      [HeatmapCell]                = []
            var totalSeconds: Double                        = 0

            for await partial in group {
                switch partial {
                case .artists(let v):      artists      = v
                case .genres(let v):       genres       = v
                case .heatmap(let v):      heatmap      = v
                case .totalSeconds(let v): totalSeconds = v
                }
            }

            return AnalyticsResult(
                topArtists: artists,
                topGenres: genres,
                heatmap: heatmap,
                totalListeningSeconds: totalSeconds
            )
        }
    }

    // MARK: - Static compute functions
    // These are not actor-isolated, which is what allows TaskGroup to run them in parallel.

    private static func computeTopArtists(
        events: [EventRecord], limit: Int
    ) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for e in events where !e.artistName.isEmpty {
            counts[e.artistName, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
    }

    private static func computeTopGenres(
        events: [EventRecord], limit: Int
    ) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for e in events where !e.genreName.isEmpty {
            counts[e.genreName, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (name: $0.key, count: $0.value) }
    }

    private static func computeHeatmap(events: [EventRecord]) -> [HeatmapCell] {
        struct GridKey: Hashable { let weekday: Int; let hour: Int }

        var counts: [GridKey: Int] = [:]
        let calendar = Calendar.current

        for event in events {
            let comps = calendar.dateComponents([.weekday, .hour], from: event.playedAt)
            guard let weekday = comps.weekday, let hour = comps.hour else { continue }
            counts[GridKey(weekday: weekday, hour: hour), default: 0] += 1
        }

        let maxCount = counts.values.max().map(Double.init) ?? 1

        // Always return all 168 cells so callers can render a complete grid.
        var cells: [HeatmapCell] = []
        cells.reserveCapacity(168)
        for weekday in 1...7 {
            for hour in 0...23 {
                let raw = counts[GridKey(weekday: weekday, hour: hour)] ?? 0
                cells.append(HeatmapCell(
                    weekday: weekday,
                    hour: hour,
                    intensity: Double(raw) / maxCount
                ))
            }
        }
        return cells
    }

    private static func computeTotalSeconds(events: [EventRecord]) -> Double {
        Double(events.reduce(0) { $0 + $1.durationSeconds })
    }
}

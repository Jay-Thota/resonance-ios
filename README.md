# Resonance

Resonance is a native SwiftUI iOS app that surfaces personalized Apple Music listening insights. It instruments every track change through the system music player, persists play history locally, and transforms that data into rich analytics — including top artists and genres, a 7×24 listening heatmap, a searchable listening library with per-track play counts, a chronological time machine of your play history, and a Spotify Wrapped-style yearly recap — all without relying on Apple Music's own statistics APIs.

---

## Screenshots

`[Dashboard]` &nbsp; `[Heatmap]` &nbsp; `[Library]` &nbsp; `[Time Machine]` &nbsp; `[Wrapped]`

---

## Technical Highlights

### Play Count Instrumentation

MusicKit does not expose per-track play counts. Resonance solves this with a custom `PlaybackTracker` actor that subscribes to `MPNowPlayingInfoCenter` via `NotificationCenter` and writes a `PlayEvent` record to SwiftData on every track change. A `TrackSnapshot` value type captures the `MPMediaItem` properties on the main thread before crossing the actor boundary, satisfying Swift 6 strict concurrency without data races.

### Multi-layer Caching

`CacheManager` is an actor that maintains two cache layers: an `NSCache<NSString, AnyObject>` for fast in-session reads with automatic memory-pressure eviction, and `UserDefaults` with per-entry TTL timestamps for lightweight cross-session persistence. SwiftData is the authoritative source of truth and is queried directly when both cache layers miss or expire.

### Swift Concurrency

`AnalyticsEngine` is an actor that accepts a snapshot of `PlayEvent` records and fans out four independent computations — `topArtists`, `topGenres`, `listeningHeatmap`, and `totalListeningSeconds` — as child tasks inside a `withTaskGroup` block. The compute functions are `static` (non-actor-isolated) and operate on `Sendable` value snapshots, so the task group achieves genuine parallelism without re-acquiring the actor executor between tasks.

### MVVM + Observation

`AnalyticsViewModel` is marked `@MainActor @Observable`, eliminating the `ObservableObject`/`@Published` boilerplate of Combine while preserving automatic view invalidation. Views receive the model via `@Environment(AnalyticsViewModel.self)` injection, and SwiftData collections are bound directly to views with `@Query` for reactive, predicate-filtered reads that update on every store write.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│               SwiftUI Views                 │
│  DashboardView · ListeningHeatmapView       │
│  TimeMachineView · WrappedView              │
│  LibraryView                                │
├─────────────────────────────────────────────┤
│          @MainActor ViewModels              │
│          AnalyticsViewModel                 │
├─────────────────────────────────────────────┤
│                 Actors                      │
│  AnalyticsEngine · PlaybackTracker          │
│  CacheManager                               │
├─────────────────────────────────────────────┤
│            SwiftData Models                 │
│        PlayEvent · DailySnapshot            │
├─────────────────────────────────────────────┤
│               External                      │
│         MusicKit · MediaPlayer              │
└─────────────────────────────────────────────┘
```

---

## Requirements

| | |
|---|---|
| **iOS** | 17.0+ |
| **Xcode** | 15.0+ |
| **Apple Music** | Optional — mock data is included for full Simulator use without an account |

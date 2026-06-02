//
//  PlaybackTracker.swift
//  Resonance
//

import Foundation
import SwiftData
@preconcurrency import MediaPlayer

actor PlaybackTracker {
    private let modelContainer: ModelContainer
    private lazy var context = ModelContext(modelContainer)
    private var observer: (any NSObjectProtocol)?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func start() {
        let player = MPMusicPlayerController.systemMusicPlayer

        observer = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: .main   // guaranteed main-thread delivery; safe to read nowPlayingItem here
        ) { [weak self] _ in
            guard let item = player.nowPlayingItem else {
                // Notification fired with no active track (e.g. playback stopped).
                return
            }
            let snapshot = TrackSnapshot(item)
            Task { [weak self] in await self?.persist(snapshot) }
        }

        // beginGeneratingPlaybackNotifications must be called on the main thread.
        Task { @MainActor in
            player.beginGeneratingPlaybackNotifications()
        }
    }

    func stop() {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
            observer = nil
        }
        Task { @MainActor in
            MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
        }
    }

    private func persist(_ snap: TrackSnapshot) {
        context.insert(PlayEvent(
            trackID: snap.trackID,
            trackTitle: snap.title,
            artistName: snap.artist,
            albumName: snap.album,
            genreName: snap.genre,
            playedAt: .now,
            durationSeconds: snap.durationSeconds
        ))
        do {
            try context.save()
        } catch {
            print("[PlaybackTracker] Failed to persist PlayEvent: \(error)")
        }
    }
}

// Sendable struct that captures all needed values on the main thread before
// crossing into the actor, avoiding direct MPMediaItem use across boundaries.
private struct TrackSnapshot: Sendable {
    let trackID: String
    let title: String
    let artist: String
    let album: String
    let genre: String
    let durationSeconds: Int

    init(_ item: MPMediaItem) {
        trackID         = String(item.persistentID)
        title           = item.title            ?? ""
        artist          = item.artist           ?? ""
        album           = item.albumTitle       ?? ""
        genre           = item.genre            ?? ""
        durationSeconds = Int(item.playbackDuration)
    }
}

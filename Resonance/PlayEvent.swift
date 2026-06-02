//
//  PlayEvent.swift
//  Resonance
//

import Foundation
import SwiftData

@Model
final class PlayEvent {
    #Index<PlayEvent>([\.playedAt])

    var trackID: String
    var trackTitle: String
    var artistName: String
    var albumName: String
    var genreName: String
    var playedAt: Date
    var durationSeconds: Int

    init(
        trackID: String,
        trackTitle: String,
        artistName: String,
        albumName: String,
        genreName: String,
        playedAt: Date,
        durationSeconds: Int
    ) {
        self.trackID = trackID
        self.trackTitle = trackTitle
        self.artistName = artistName
        self.albumName = albumName
        self.genreName = genreName
        self.playedAt = playedAt
        self.durationSeconds = durationSeconds
    }
}

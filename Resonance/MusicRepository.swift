//
//  MusicRepository.swift
//  Resonance
//

import Foundation
import MusicKit

// MARK: - Domain value types

struct Track: Sendable, Identifiable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String
    let genreName: String
    let durationSeconds: Int
}

// Named LibraryAlbum to avoid shadowing MusicKit.Album within this module.
struct LibraryAlbum: Sendable, Identifiable {
    let id: String
    let title: String
    let artistName: String
    let releaseDate: Date?
}

// MARK: - Errors

enum MusicRepositoryError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        "Apple Music access is required. Please grant permission in Settings."
    }
}

// MARK: - Repository

final class MusicRepository: Sendable {

    /// Returns up to `limit` recently played songs in reverse-chronological order.
    func recentlyPlayedTracks(limit: Int = 25) async throws -> [Track] {
        try await requireAuthorization()

        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = limit

        let response = try await request.response()
        return response.items.map(Track.init)
    }

    /// Returns up to `limit` albums from the user's music library.
    func libraryAlbums(limit: Int = 100) async throws -> [LibraryAlbum] {
        try await requireAuthorization()

        var request = MusicLibraryRequest<MusicKit.Album>()
        request.limit = limit

        let response = try await request.response()
        return response.items.map(LibraryAlbum.init)
    }

    // MARK: - Private

    private func requireAuthorization() async throws {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            throw MusicRepositoryError.notAuthorized
        }
    }
}

// MARK: - MusicKit → domain mapping

private extension Track {
    init(_ song: Song) {
        id              = song.id.rawValue
        title           = song.title
        artistName      = song.artistName
        albumTitle      = song.albumTitle ?? ""
        genreName       = song.genreNames.first ?? ""
        durationSeconds = Int(song.duration ?? 0)
    }
}

private extension LibraryAlbum {
    init(_ album: MusicKit.Album) {
        id          = album.id.rawValue
        title       = album.title
        artistName  = album.artistName
        releaseDate = album.releaseDate
    }
}

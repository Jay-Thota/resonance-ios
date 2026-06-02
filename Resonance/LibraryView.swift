//
//  LibraryView.swift
//  Resonance
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \PlayEvent.playedAt, order: .reverse) private var events: [PlayEvent]
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .mostPlayed

    enum SortOrder { case mostPlayed, recentlyPlayed }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Library Yet",
                        systemImage: "music.note.list",
                        description: Text("Tracks you play will appear here.")
                    )
                } else if displayedTracks.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(displayedTracks) { track in
                        TrackRow(track: track)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Tracks or artists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            Label("Most Played", systemImage: "play.circle.fill")
                                .tag(SortOrder.mostPlayed)
                            Label("Recently Played", systemImage: "clock")
                                .tag(SortOrder.recentlyPlayed)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }

    // MARK: - Data pipeline

    // Events arrive newest-first from @Query, so the first occurrence of each
    // trackID in the loop is already its most recent play — no max() needed.
    private var groupedTracks: [LibraryTrack] {
        struct Accumulator {
            var title: String
            var artistName: String
            var albumName: String
            var playCount: Int
            var lastPlayedAt: Date
        }

        var dict: [String: Accumulator] = [:]
        for event in events {
            let key = event.trackID.isEmpty
                ? "\(event.trackTitle)|\(event.artistName)"
                : event.trackID
            if dict[key] != nil {
                dict[key]!.playCount += 1
            } else {
                dict[key] = Accumulator(
                    title: event.trackTitle,
                    artistName: event.artistName,
                    albumName: event.albumName,
                    playCount: 1,
                    lastPlayedAt: event.playedAt
                )
            }
        }

        return dict.map { key, acc in
            LibraryTrack(
                id: key,
                title: acc.title,
                artistName: acc.artistName,
                albumName: acc.albumName,
                playCount: acc.playCount,
                lastPlayedAt: acc.lastPlayedAt
            )
        }
    }

    private var sortedTracks: [LibraryTrack] {
        switch sortOrder {
        case .mostPlayed:
            return groupedTracks.sorted {
                $0.playCount != $1.playCount
                    ? $0.playCount > $1.playCount
                    : $0.title.localizedCompare($1.title) == .orderedAscending
            }
        case .recentlyPlayed:
            return groupedTracks.sorted { $0.lastPlayedAt > $1.lastPlayedAt }
        }
    }

    private var displayedTracks: [LibraryTrack] {
        guard !searchText.isEmpty else { return sortedTracks }
        let query = searchText.lowercased()
        return sortedTracks.filter {
            $0.title.lowercased().contains(query) ||
            $0.artistName.lowercased().contains(query)
        }
    }
}

// MARK: - Track model

private struct LibraryTrack: Identifiable {
    let id: String
    let title: String
    let artistName: String
    let albumName: String
    let playCount: Int
    let lastPlayedAt: Date
}

// MARK: - Row

private struct TrackRow: View {
    let track: LibraryTrack

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.body)
                    .lineLimit(1)
                Text("\(track.artistName) · \(track.albumName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(track.playCount)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(track.playCount > 1 ? Color.accentColor : .secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    track.playCount > 1
                        ? Color.accentColor.opacity(0.12)
                        : Color(.tertiarySystemFill),
                    in: Capsule()
                )
        }
    }
}

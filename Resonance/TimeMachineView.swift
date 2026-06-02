//
//  TimeMachineView.swift
//  Resonance
//

import SwiftUI
import SwiftData

struct TimeMachineView: View {
    @Query(sort: \PlayEvent.playedAt, order: .reverse) private var events: [PlayEvent]
    @State private var expandedDates: Set<Date> = []

    var body: some View {
        NavigationStack {
            Group {
                if dayGroups.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Your play history will appear here.")
                    )
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            DayRow(
                                group: group,
                                isExpanded: expandedDates.contains(group.date)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedDates.contains(group.date) {
                                        expandedDates.remove(group.date)
                                    } else {
                                        expandedDates.insert(group.date)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Time Machine")
        }
    }

    // MARK: - Grouping

    private var dayGroups: [DayGroup] {
        var dict: [Date: [PlayEvent]] = [:]
        let cal = Calendar.current
        for event in events {
            let day = cal.startOfDay(for: event.playedAt)
            dict[day, default: []].append(event)
        }
        return dict
            .map { date, dayEvents in
                // @Query already delivers events sorted newest-first within each day.
                DayGroup(
                    date: date,
                    tracks: dayEvents.map { DayGroup.Track(title: $0.trackTitle, artist: $0.artistName) }
                )
            }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Day group model

private struct DayGroup: Identifiable {
    struct Track {
        let title: String
        let artist: String
    }
    let date: Date
    let tracks: [Track]
    var id: Date { date }
}

// MARK: - Day row

private struct DayRow: View {
    let group: DayGroup
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // ── Date header ──────────────────────────────────────────────
                HStack(alignment: .firstTextBaseline) {
                    Text(group.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(group.tracks.count) play\(group.tracks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if group.tracks.count > 3 {
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }

                // ── Track list ───────────────────────────────────────────────
                let displayed = isExpanded ? group.tracks : Array(group.tracks.prefix(3))
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(displayed.enumerated()), id: \.offset) { _, track in
                        TrackLine(title: track.title, artist: track.artist)
                    }
                    if !isExpanded && group.tracks.count > 3 {
                        Text("+ \(group.tracks.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 22)
                    }
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Track line

private struct TrackLine: View {
    let title: String
    let artist: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

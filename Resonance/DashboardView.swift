//
//  DashboardView.swift
//  Resonance
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(AnalyticsViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            scrollContent
                .opacity(viewModel.isLoading ? 0 : 1)

            if viewModel.isLoading {
                ProgressView("Analysing…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // ── Header ───────────────────────────────────────────────
                Text("Resonance")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                // ── Stat cards ───────────────────────────────────────────
                HStack(spacing: 12) {
                    StatCard(
                        icon: "headphones",
                        label: "Hours",
                        value: String(format: "%.1f", viewModel.totalListeningSeconds / 3600)
                    )
                    StatCard(
                        icon: "music.mic",
                        label: "Top Artist",
                        value: viewModel.topArtists.first?.name ?? "—"
                    )
                    StatCard(
                        icon: "tag",
                        label: "Top Genre",
                        value: viewModel.topGenres.first?.name ?? "—"
                    )
                }
                .padding(.horizontal)

                // ── Top Artists bar chart ─────────────────────────────────
                SectionHeader(title: "Top Artists")
                    .padding(.horizontal)

                let topFive = Array(viewModel.topArtists.prefix(5))

                if topFive.isEmpty {
                    emptyPlaceholder("No play history yet.")
                        .padding(.horizontal)
                } else {
                    Chart(topFive, id: \.name) { artist in
                        BarMark(
                            x: .value("Artist", artist.name),
                            y: .value("Plays", artist.count)
                        )
                        .foregroundStyle(Color.accentColor)
                        .annotation(position: .top, alignment: .center) {
                            Text("\(artist.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let name = value.as(String.self) {
                                    Text(name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                }

                // ── Top Genres pills ──────────────────────────────────────
                SectionHeader(title: "Top Genres")
                    .padding(.horizontal)

                if viewModel.topGenres.isEmpty {
                    emptyPlaceholder("No genre data yet.")
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.topGenres, id: \.name) { genre in
                                GenrePill(name: genre.name, count: genre.count)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private func emptyPlaceholder(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Genre pill

private struct GenrePill: View {
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
            Text("·")
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
    }
}

// MARK: - Section header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.bold())
    }
}

//
//  WrappedView.swift
//  Resonance
//

import SwiftUI
import SwiftData

struct WrappedView: View {
    @Environment(AnalyticsViewModel.self) private var viewModel
    @Query(sort: \PlayEvent.playedAt) private var events: [PlayEvent]
    @State private var visibleCard: Int? = 0

    // Evaluated once per session — year won't change mid-use.
    private static let currentYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        hoursCard
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(0)
                        artistCard
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(1)
                        genreCard
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(2)
                        peakHourCard
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(3)
                        streakCard
                            .frame(width: geo.size.width, height: geo.size.height)
                            .id(4)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $visibleCard)
                .scrollIndicators(.hidden)
                .ignoresSafeArea()

                // Page indicator (right edge)
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(visibleCard == i ? Color.white : Color.white.opacity(0.38))
                            .frame(width: 4, height: visibleCard == i ? 22 : 7)
                            .animation(.easeInOut(duration: 0.2), value: visibleCard)
                    }
                }
                .padding(.trailing, 14)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Cards

    private var hoursCard: some View {
        WrappedCard(
            icon: "headphones",
            stat: String(format: "%.1f h", thisYearHours),
            subtitle: "Listening time in \(Self.currentYear)",
            colors: [.orange, Color(red: 1.0, green: 0.18, blue: 0.50)],
            showSwipeHint: true
        )
    }

    private var artistCard: some View {
        let artist = viewModel.topArtists.first
        return WrappedCard(
            icon: "music.mic",
            stat: artist?.name ?? "—",
            subtitle: artist.map { "× \($0.count) plays · Your top artist" } ?? "No plays recorded yet",
            colors: [Color(red: 0.44, green: 0.10, blue: 0.88), Color(red: 0.18, green: 0.28, blue: 0.92)]
        )
    }

    private var genreCard: some View {
        let genre = viewModel.topGenres.first
        return WrappedCard(
            icon: "tag",
            stat: genre?.name ?? "—",
            subtitle: "Your most played genre",
            colors: [Color(red: 0.05, green: 0.72, blue: 0.48), Color(red: 0.00, green: 0.46, blue: 0.82)]
        )
    }

    private var peakHourCard: some View {
        WrappedCard(
            icon: "clock",
            stat: peakHourLabel,
            subtitle: "Your most active listening hour",
            colors: [Color(red: 0.06, green: 0.06, blue: 0.34), Color(red: 0.34, green: 0.06, blue: 0.56)]
        )
    }

    private var streakCard: some View {
        let n = longestStreak
        return WrappedCard(
            icon: "flame",
            stat: "\(n) day\(n == 1 ? "" : "s")",
            subtitle: "Longest consecutive listening streak",
            colors: [Color(red: 1.00, green: 0.54, blue: 0.00), Color(red: 0.94, green: 0.10, blue: 0.28)]
        )
    }

    // MARK: - Computed stats

    private var thisYearHours: Double {
        let cal = Calendar.current
        let yr = Self.currentYear
        return events
            .filter { cal.component(.year, from: $0.playedAt) == yr }
            .reduce(0.0) { $0 + Double($1.durationSeconds) }
            / 3600
    }

    private var peakHourLabel: String {
        guard let peak = viewModel.heatmap.max(by: { $0.intensity < $1.intensity }),
              peak.intensity > 0 else { return "—" }
        return hourLabel(peak.hour)
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let days = Set(events.map { cal.startOfDay(for: $0.playedAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<days.count {
            let gap = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:       return "12 AM"
        case 1...11:  return "\(hour) AM"
        case 12:      return "12 PM"
        default:      return "\(hour - 12) PM"
        }
    }
}

// MARK: - Card view

private struct WrappedCard: View {
    let icon: String
    let stat: String
    let subtitle: String
    let colors: [Color]
    var showSwipeHint: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: icon)
                    .font(.system(size: 54))
                    .foregroundStyle(.white.opacity(0.88))

                Text(stat)
                    .font(.system(size: 70, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)
                    .lineLimit(2)
                    .padding(.horizontal, 36)

                Text(subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 52)
            }

            if showSwipeHint {
                VStack {
                    Spacer()
                    VStack(spacing: 5) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Swipe up")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.60))
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

//
//  ListeningHeatmapView.swift
//  Resonance
//

import SwiftUI

struct ListeningHeatmapView: View {

    // Pre-indexed as [hour 0-23][weekday col 0-6] so body never does a dictionary lookup.
    private let grid: [[Double]]

    private static let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    // Fixed geometry that fits comfortably on every current iPhone (SE = 375 pt).
    // Total width: labelW(38) + 7×cell(36) + 6×gap(4) = 310 pt + 32 pt padding = 342 pt.
    private let cellSize: CGFloat    = 36
    private let cellRadius: CGFloat  =  5
    private let gap: CGFloat         =  4
    private let labelWidth: CGFloat  = 38

    // MARK: - Init

    init(cells: [HeatmapCell]) {
        var g = Array(repeating: Array(repeating: 0.0, count: 7), count: 24)
        for cell in cells
            where (0..<24).contains(cell.hour) && (1...7).contains(cell.weekday) {
            g[cell.hour][cell.weekday - 1] = cell.intensity
        }
        self.grid = g
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dayHeaderRow
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<24, id: \.self) { hour in
                    hourRow(hour: hour)
                }
            }
        }
    }

    // MARK: - Sub-views

    private var dayHeaderRow: some View {
        HStack(spacing: gap) {
            // Corner spacer aligns day labels with the cell columns.
            Color.clear
                .frame(width: labelWidth, height: 1)

            ForEach(Array(Self.dayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: cellSize, alignment: .center)
            }
        }
    }

    private func hourRow(hour: Int) -> some View {
        HStack(spacing: gap) {
            Text(hourLabel(hour))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .trailing)

            ForEach(0..<7, id: \.self) { col in
                cell(intensity: grid[hour][col], weekday: col + 1, hour: hour)
            }
        }
    }

    private func cell(intensity: Double, weekday: Int, hour: Int) -> some View {
        RoundedRectangle(cornerRadius: cellRadius)
            .fill(cellColor(intensity: intensity))
            .frame(width: cellSize, height: cellSize)
            .accessibilityLabel(accessibilityLabel(weekday: weekday, hour: hour, intensity: intensity))
    }

    // MARK: - Helpers

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:       return "12am"
        case 1...11:  return "\(hour)am"
        case 12:      return "12pm"
        default:      return "\(hour - 12)pm"
        }
    }

    /// Interpolates from near-white (0) through pale lavender to deep purple (1).
    ///
    /// At intensity = 0  → Color(.systemGray6)  (no-data grey, matches dark/light mode)
    /// At intensity > 0  → HSB hue 0.75 (purple), saturation/brightness scaled by intensity
    ///   intensity = 0.01 → sat 0.20, bri 0.94  (pale lavender)
    ///   intensity = 0.50 → sat 0.60, bri 0.72  (medium purple)
    ///   intensity = 1.00 → sat 1.00, bri 0.50  (deep purple)
    private func cellColor(intensity: Double) -> Color {
        guard intensity > 0 else { return Color(.systemGray6) }
        let sat = 0.20 + intensity * 0.80   // 0.20 → 1.00
        let bri = 0.94 - intensity * 0.44   // 0.94 → 0.50
        return Color(hue: 0.75, saturation: sat, brightness: bri)
    }

    private func accessibilityLabel(weekday: Int, hour: Int, intensity: Double) -> String {
        let day = weekday <= Self.dayLabels.count ? Self.dayLabels[weekday - 1] : "Unknown"
        let hourText = hourLabel(hour)
        if intensity == 0 { return "\(day) \(hourText): no plays" }
        let pct = Int(intensity * 100)
        return "\(day) \(hourText): \(pct)% intensity"
    }
}

// MARK: - Preview

#Preview {
    let sample: [HeatmapCell] = (1...7).flatMap { weekday in
        (0..<24).map { hour in
            let raw = weekday == 1 && hour == 8 ? 1.0
                    : weekday == 3 && hour == 18 ? 0.8
                    : Double.random(in: 0...0.4)
            return HeatmapCell(weekday: weekday, hour: hour, intensity: raw)
        }
    }
    ScrollView {
        ListeningHeatmapView(cells: sample)
            .padding()
    }
}

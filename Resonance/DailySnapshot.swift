//
//  DailySnapshot.swift
//  Resonance
//

import Foundation
import SwiftData

@Model
final class DailySnapshot {
    #Index<DailySnapshot>([\.date])
    #Unique<DailySnapshot>([\.date])

    var date: Date
    var topTrackIDs: [String]
    var topArtistNames: [String]

    init(date: Date, topTrackIDs: [String] = [], topArtistNames: [String] = []) {
        self.date = date
        self.topTrackIDs = topTrackIDs
        self.topArtistNames = topArtistNames
    }
}

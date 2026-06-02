//
//  MockPlaybackTracker.swift
//  Resonance
//
//  Seeded once per install. Guards against re-seeding on subsequent launches
//  by checking whether PlayEvent rows already exist before inserting anything.
//

import Foundation
import SwiftData

actor MockPlaybackTracker {
    private let modelContainer: ModelContainer
    private lazy var context = ModelContext(modelContainer)

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func start() {
        let existing = (try? context.fetchCount(FetchDescriptor<PlayEvent>())) ?? 0
        guard existing == 0 else { return }
        Self.sampleEvents().forEach { context.insert($0) }
        try? context.save()
    }

    func stop() { /* no-op – mirrors PlaybackTracker API */ }

    // MARK: - Sample data

    private static func sampleEvents() -> [PlayEvent] {

        // (title, artist, album, genre, seconds)
        let catalog: [(String, String, String, String, Int)] = [
            ("Anti-Hero",                     "Taylor Swift",      "Midnights",                     "Pop",         200),
            ("Cruel Summer",                  "Taylor Swift",      "Lover",                         "Pop",         178),
            ("Karma",                         "Taylor Swift",      "Midnights",                     "Pop",         201),
            ("Shake It Off",                  "Taylor Swift",      "1989",                          "Pop",         219),
            ("Blinding Lights",               "The Weeknd",        "After Hours",                   "R&B",         200),
            ("Starboy",                       "The Weeknd",        "Starboy",                       "R&B",         230),
            ("Save Your Tears",               "The Weeknd",        "After Hours",                   "R&B",         215),
            ("God's Plan",                    "Drake",             "Scorpion",                      "Hip-Hop",     198),
            ("One Dance",                     "Drake",             "Views",                         "Hip-Hop",     173),
            ("Rich Flex",                     "Drake",             "Her Loss",                      "Hip-Hop",     210),
            ("HUMBLE.",                       "Kendrick Lamar",    "DAMN.",                         "Hip-Hop",     177),
            ("LOVE.",                         "Kendrick Lamar",    "DAMN.",                         "Hip-Hop",     213),
            ("bad guy",                       "Billie Eilish",     "WHEN WE ALL FALL ASLEEP",       "Alternative", 194),
            ("Happier Than Ever",             "Billie Eilish",     "Happier Than Ever",             "Alternative", 298),
            ("Mia",                           "Bad Bunny",         "Un Verano Sin Ti",              "Latin",       214),
            ("Tití Me Preguntó",              "Bad Bunny",         "Un Verano Sin Ti",              "Latin",       295),
            ("As It Was",                     "Harry Styles",      "Harry's House",                 "Pop",         167),
            ("Watermelon Sugar",              "Harry Styles",      "Fine Line",                     "Pop",         174),
            ("Grapejuice",                    "Harry Styles",      "Harry's House",                 "Pop",         208),
            ("good 4 u",                      "Olivia Rodrigo",    "SOUR",                          "Pop",         178),
            ("drivers license",               "Olivia Rodrigo",    "SOUR",                          "Pop",         242),
            ("Vampire",                       "Olivia Rodrigo",    "GUTS",                          "Pop",         219),
            ("Say So",                        "Doja Cat",          "Hot Pink",                      "R&B",         237),
            ("Need to Know",                  "Doja Cat",          "Planet Her",                    "R&B",         253),
            ("Circles",                       "Post Malone",       "Hollywood's Bleeding",          "Pop",         215),
            ("Rockstar",                      "Post Malone",       "beerbongs & bentleys",          "Hip-Hop",     218),
            ("Kill Bill",                     "SZA",               "SOS",                           "R&B",         153),
            ("Good Days",                     "SZA",               "SZA Singles",                   "R&B",         278),
            ("EARFQUAKE",                     "Tyler, the Creator","IGOR",                          "Hip-Hop",     211),
            ("SWEET / I THOUGHT YOU WANTED TO DANCE", "Tyler, the Creator", "Call Me If You Get Lost", "Hip-Hop", 334),
            ("505",                           "Arctic Monkeys",    "Favourite Worst Nightmare",     "Indie Rock",  253),
            ("R U Mine?",                     "Arctic Monkeys",    "AM",                            "Indie Rock",  202),
            ("Do I Wanna Know?",              "Arctic Monkeys",    "AM",                            "Indie Rock",  272),
            ("Pink + White",                  "Frank Ocean",       "Blonde",                        "R&B",         217),
            ("Nights",                        "Frank Ocean",       "Blonde",                        "R&B",         307),
            ("Summertime Sadness",            "Lana Del Rey",      "Born to Die",                   "Indie Pop",   265),
            ("Young and Beautiful",           "Lana Del Rey",      "Born to Die",                   "Indie Pop",   230),
            ("Levitating",                    "Dua Lipa",          "Future Nostalgia",              "Pop",         203),
            ("Physical",                      "Dua Lipa",          "Future Nostalgia",              "Pop",         193),
            ("Heat Waves",                    "Glass Animals",     "Dreamland",                     "Indie Pop",   238),
            ("Flowers",                       "Miley Cyrus",       "Endless Summer Vacation",       "Pop",         200),
            ("Industry Baby",                 "Lil Nas X",         "MONTERO",                       "Hip-Hop",     212),
            ("MONTERO",                       "Lil Nas X",         "MONTERO",                       "Hip-Hop",     137),
            ("Essence",                       "Wizkid",            "Made in Lagos",                 "Afrobeats",   225),
            ("Peaches",                       "Justin Bieber",     "Justice",                       "R&B",         197),
            ("positions",                     "Ariana Grande",     "Positions",                     "R&B",         172),
            ("34+35",                         "Ariana Grande",     "Positions",                     "R&B",         173),
            ("abcdefu",                       "GAYLE",             "a study of the human experience","Pop",        176),
            ("Señorita",                      "Shawn Mendes",      "Shawn Mendes Singles",          "Pop",         189),
            ("Attention",                     "Charlie Puth",      "Voicenotes",                    "Pop",         208),
        ]

        // Hour weights that reflect realistic daily listening patterns.
        // Higher weight = more likely to appear in the generated events.
        let weightedHours: [Int] = [
             7,  7,  7,               // early morning commute
             8,  8,  8,  8,  8,
             9,  9,  9,
            12, 12, 12, 12,           // lunch
            13, 13,
            17, 17, 17,               // evening commute
            18, 18, 18,  18,
            19, 19, 19,
            20, 20, 21, 21,
            22, 22, 23,               // late night
             0,  1,                   // past midnight
        ]

        let now   = Date()
        let cal   = Calendar.current

        return catalog.enumerated().map { index, entry in
            let (title, artist, album, genre, duration) = entry

            // Spread events across the last 30 days.
            let daysAgo = index % 30
            let hour    = weightedHours[index % weightedHours.count]
            let minute  = (index * 13) % 60   // deterministic spread, not all at :00

            var comps      = cal.dateComponents([.year, .month, .day], from: now)
            comps.day      = (comps.day ?? 0) - daysAgo
            comps.hour     = hour
            comps.minute   = minute
            comps.second   = 0
            let playedAt   = cal.date(from: comps) ?? now

            return PlayEvent(
                trackID:         UUID().uuidString,
                trackTitle:      title,
                artistName:      artist,
                albumName:       album,
                genreName:       genre,
                playedAt:        playedAt,
                durationSeconds: duration
            )
        }
    }
}

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

        // (title, artist, album, genre, durationSeconds, plays)
        // trackID is derived from catalog index so repeated plays of the same
        // track share an ID, enabling correct grouping in LibraryView.
        // plays > 1 reflects realistic repeated listening behaviour.
        let catalog: [(String, String, String, String, Int, Int)] = [
            ("Anti-Hero",                              "Taylor Swift",       "Midnights",                       "Pop",         200, 5),
            ("Cruel Summer",                           "Taylor Swift",       "Lover",                           "Pop",         178, 4),
            ("Karma",                                  "Taylor Swift",       "Midnights",                       "Pop",         201, 3),
            ("Shake It Off",                           "Taylor Swift",       "1989",                            "Pop",         219, 3),
            ("Blinding Lights",                        "The Weeknd",         "After Hours",                     "R&B",         200, 4),
            ("Starboy",                                "The Weeknd",         "Starboy",                         "R&B",         230, 3),
            ("Save Your Tears",                        "The Weeknd",         "After Hours",                     "R&B",         215, 2),
            ("God's Plan",                             "Drake",              "Scorpion",                        "Hip-Hop",     198, 3),
            ("One Dance",                              "Drake",              "Views",                           "Hip-Hop",     173, 2),
            ("Rich Flex",                              "Drake",              "Her Loss",                        "Hip-Hop",     210, 2),
            ("HUMBLE.",                                "Kendrick Lamar",     "DAMN.",                           "Hip-Hop",     177, 3),
            ("LOVE.",                                  "Kendrick Lamar",     "DAMN.",                           "Hip-Hop",     213, 2),
            ("bad guy",                                "Billie Eilish",      "WHEN WE ALL FALL ASLEEP",         "Alternative", 194, 3),
            ("Happier Than Ever",                      "Billie Eilish",      "Happier Than Ever",               "Alternative", 298, 2),
            ("Mia",                                    "Bad Bunny",          "Un Verano Sin Ti",                "Latin",       214, 2),
            ("Tití Me Preguntó",                       "Bad Bunny",          "Un Verano Sin Ti",                "Latin",       295, 2),
            ("As It Was",                              "Harry Styles",       "Harry's House",                   "Pop",         167, 3),
            ("Watermelon Sugar",                       "Harry Styles",       "Fine Line",                       "Pop",         174, 2),
            ("Grapejuice",                             "Harry Styles",       "Harry's House",                   "Pop",         208, 2),
            ("good 4 u",                               "Olivia Rodrigo",     "SOUR",                            "Pop",         178, 2),
            ("drivers license",                        "Olivia Rodrigo",     "SOUR",                            "Pop",         242, 3),
            ("Vampire",                                "Olivia Rodrigo",     "GUTS",                            "Pop",         219, 2),
            ("Say So",                                 "Doja Cat",           "Hot Pink",                        "R&B",         237, 2),
            ("Need to Know",                           "Doja Cat",           "Planet Her",                      "R&B",         253, 2),
            ("Circles",                                "Post Malone",        "Hollywood's Bleeding",            "Pop",         215, 2),
            ("Rockstar",                               "Post Malone",        "beerbongs & bentleys",            "Hip-Hop",     218, 1),
            ("Kill Bill",                              "SZA",                "SOS",                             "R&B",         153, 3),
            ("Good Days",                              "SZA",                "SZA Singles",                     "R&B",         278, 2),
            ("EARFQUAKE",                              "Tyler, the Creator", "IGOR",                            "Hip-Hop",     211, 2),
            ("SWEET / I THOUGHT YOU WANTED TO DANCE", "Tyler, the Creator", "Call Me If You Get Lost",         "Hip-Hop",     334, 1),
            ("505",                                    "Arctic Monkeys",     "Favourite Worst Nightmare",       "Indie Rock",  253, 2),
            ("R U Mine?",                              "Arctic Monkeys",     "AM",                              "Indie Rock",  202, 2),
            ("Do I Wanna Know?",                       "Arctic Monkeys",     "AM",                              "Indie Rock",  272, 2),
            ("Pink + White",                           "Frank Ocean",        "Blonde",                          "R&B",         217, 2),
            ("Nights",                                 "Frank Ocean",        "Blonde",                          "R&B",         307, 1),
            ("Summertime Sadness",                     "Lana Del Rey",       "Born to Die",                     "Indie Pop",   265, 2),
            ("Young and Beautiful",                    "Lana Del Rey",       "Born to Die",                     "Indie Pop",   230, 1),
            ("Levitating",                             "Dua Lipa",           "Future Nostalgia",                "Pop",         203, 2),
            ("Physical",                               "Dua Lipa",           "Future Nostalgia",                "Pop",         193, 1),
            ("Heat Waves",                             "Glass Animals",      "Dreamland",                       "Indie Pop",   238, 2),
            ("Flowers",                                "Miley Cyrus",        "Endless Summer Vacation",         "Pop",         200, 2),
            ("Industry Baby",                          "Lil Nas X",          "MONTERO",                         "Hip-Hop",     212, 2),
            ("MONTERO",                                "Lil Nas X",          "MONTERO",                         "Hip-Hop",     137, 1),
            ("Essence",                                "Wizkid",             "Made in Lagos",                   "Afrobeats",   225, 2),
            ("Peaches",                                "Justin Bieber",      "Justice",                         "R&B",         197, 1),
            ("positions",                              "Ariana Grande",      "Positions",                       "R&B",         172, 2),
            ("34+35",                                  "Ariana Grande",      "Positions",                       "R&B",         173, 1),
            ("abcdefu",                                "GAYLE",              "a study of the human experience", "Pop",         176, 1),
            ("Señorita",                               "Shawn Mendes",       "Shawn Mendes Singles",            "Pop",         189, 1),
            ("Attention",                              "Charlie Puth",       "Voicenotes",                      "Pop",         208, 1),
        ]

        // Hour weights biased toward realistic daily listening patterns.
        let weightedHours: [Int] = [
             7,  7,  7,
             8,  8,  8,  8,  8,
             9,  9,  9,
            12, 12, 12, 12,
            13, 13,
            17, 17, 17,
            18, 18, 18, 18,
            19, 19, 19,
            20, 20, 21, 21,
            22, 22, 23,
             0,  1,
        ]

        let now = Date()
        let cal = Calendar.current

        var result: [PlayEvent] = []
        var eventIndex = 0

        for (catalogIdx, entry) in catalog.enumerated() {
            let (title, artist, album, genre, duration, plays) = entry

            for _ in 0..<plays {
                // Spread events across the last 45 days so every day has ≥ 1 play,
                // producing a clean 45-day streak in the Wrapped card.
                let daysAgo = eventIndex % 45
                let hour    = weightedHours[eventIndex % weightedHours.count]
                let minute  = (eventIndex * 17) % 60

                var comps      = cal.dateComponents([.year, .month, .day], from: now)
                comps.day      = (comps.day ?? 0) - daysAgo
                comps.hour     = hour
                comps.minute   = minute
                comps.second   = 0
                let playedAt   = cal.date(from: comps) ?? now

                result.append(PlayEvent(
                    trackID:         "mock-\(catalogIdx)",
                    trackTitle:      title,
                    artistName:      artist,
                    albumName:       album,
                    genreName:       genre,
                    playedAt:        playedAt,
                    durationSeconds: duration
                ))
                eventIndex += 1
            }
        }

        return result
    }
}

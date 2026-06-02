//
//  CacheManager.swift
//  Resonance
//

import Foundation

// MARK: - Cache key

enum CacheKey: String, CaseIterable {
    case recentTracks  = "resonance.cache.recentTracks"
    case topArtists    = "resonance.cache.topArtists"
    case libraryAlbums = "resonance.cache.libraryAlbums"
}

// MARK: - Actor

actor CacheManager {

    static let shared = CacheManager()

    // Session-scoped: fast, evictable, lives only in memory.
    private let memory = NSCache<NSString, AnyObject>()
    // Cross-session: survives app restarts, stored in UserDefaults.
    private let defaults = UserDefaults.standard

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        memory.countLimit    = 50          // max objects before LRU eviction
        memory.totalCostLimit = 5_242_880  // ~5 MB soft cap
    }

    // MARK: - Read

    /// Returns a decoded value if a non-expired entry exists for `key`, otherwise `nil`.
    /// Checks the memory layer first; falls back to `UserDefaults` and promotes on hit.
    func get<T: Codable>(_ key: CacheKey, ttl: TimeInterval) -> T? {
        // 1. Memory layer
        if let data  = memoryData(for: key),
           let entry = decode(CacheEntry<T>.self, from: data),
           !entry.isExpired(ttl: ttl) {
            return entry.value
        }

        // 2. Persistent layer — re-populate memory so the next hit is fast
        if let data  = defaults.data(forKey: key.rawValue),
           let entry = decode(CacheEntry<T>.self, from: data),
           !entry.isExpired(ttl: ttl) {
            writeToMemory(data, for: key)
            return entry.value
        }

        return nil
    }

    // MARK: - Write

    /// Encodes `value` with the current timestamp and writes it to both layers.
    func set<T: Codable>(_ value: T, for key: CacheKey) throws {
        let data = try encoder.encode(CacheEntry(value: value, storedAt: Date()))
        writeToMemory(data, for: key)
        defaults.set(data, forKey: key.rawValue)
    }

    // MARK: - Invalidation

    /// Wipes both cache layers for every known key.
    func clearAll() {
        memory.removeAllObjects()
        CacheKey.allCases.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }

    // MARK: - Private helpers

    private func memoryData(for key: CacheKey) -> Data? {
        guard let raw = memory.object(forKey: key.rawValue as NSString) as? NSData else { return nil }
        return Data(referencing: raw)
    }

    private func writeToMemory(_ data: Data, for key: CacheKey) {
        memory.setObject(data as NSData, forKey: key.rawValue as NSString)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? decoder.decode(type, from: data)
    }
}

// MARK: - Envelope

/// Wraps a cached value with its storage timestamp so TTL can be checked at read time.
private struct CacheEntry<T: Codable>: Codable {
    let value: T
    let storedAt: Date

    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(storedAt) > ttl
    }
}

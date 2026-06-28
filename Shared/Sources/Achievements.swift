//
//  Achievements.swift
//  Salvager — Shared
//
//  Permanent achievements that reward Cores on unlock. Each achievement carries
//  a predicate evaluated against the live GameState; the engine checks the
//  catalog after meaningful changes and unlocks any newly-earned ones (see
//  GameEngine.checkAchievements). Unlocked ids live in GameState so they sync
//  and survive Deep Jumps.
//

import Foundation

public struct Achievement: Identifiable {
    public var id: String
    public var name: String
    public var detail: String
    public var symbolName: String
    public var coreReward: Int
    /// True when this achievement's condition is met by the given state.
    public var isEarned: (GameState) -> Bool

    public init(id: String, name: String, detail: String, symbolName: String,
                coreReward: Int, isEarned: @escaping (GameState) -> Bool) {
        self.id = id
        self.name = name
        self.detail = detail
        self.symbolName = symbolName
        self.coreReward = coreReward
        self.isEarned = isEarned
    }
}

extension Achievement: Equatable {
    public static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

public extension Achievement {
    static let catalog: [Achievement] = [
        // Depth milestones
        Achievement(id: "ach.depth5", name: "Breaking In", detail: "Reach Depth 5",
                    symbolName: "arrow.down.to.line", coreReward: 5) { $0.currentLevel >= 5 },
        Achievement(id: "ach.depth25", name: "Deep Diver", detail: "Reach Depth 25",
                    symbolName: "arrow.down.to.line.compact", coreReward: 15) { $0.currentLevel >= 25 },
        Achievement(id: "ach.depth50", name: "Hull Crawler", detail: "Reach Depth 50",
                    symbolName: "square.3.layers.3d.down.right", coreReward: 30) { $0.currentLevel >= 50 },
        Achievement(id: "ach.depth100", name: "Into the Dark", detail: "Reach Depth 100",
                    symbolName: "moon.stars.fill", coreReward: 75) { $0.currentLevel >= 100 },

        // Deep Jumps (prestige)
        Achievement(id: "ach.jump1", name: "First Jump", detail: "Deep Jump once",
                    symbolName: "arrow.triangle.2.circlepath", coreReward: 25) { $0.prestigeCount >= 1 },
        Achievement(id: "ach.jump5", name: "Drifter", detail: "Deep Jump 5 times",
                    symbolName: "infinity", coreReward: 60) { $0.prestigeCount >= 5 },

        // Scrap salvaged (lifetime)
        Achievement(id: "ach.scrap10k", name: "Scrapper", detail: "Salvage 10K scrap",
                    symbolName: "cube.fill", coreReward: 10) { $0.lifetimeGoldEarned >= 10_000 },
        Achievement(id: "ach.scrap1m", name: "Hoarder", detail: "Salvage 1M scrap",
                    symbolName: "cube.box.fill", coreReward: 40) { $0.lifetimeGoldEarned >= 1_000_000 },
        Achievement(id: "ach.scrap1b", name: "Tycoon", detail: "Salvage 1B scrap",
                    symbolName: "building.columns.fill", coreReward: 120) { $0.lifetimeGoldEarned >= 1_000_000_000 },

        // Salvage caches
        Achievement(id: "ach.cache1", name: "Lucky Find", detail: "Crack a Salvage Cache",
                    symbolName: "shippingbox.fill", coreReward: 10) { $0.lifetimeCachesCollected >= 1 },
        Achievement(id: "ach.cache25", name: "Cache Hunter", detail: "Crack 25 caches",
                    symbolName: "shippingbox.and.arrow.backward.fill", coreReward: 35) { $0.lifetimeCachesCollected >= 25 },

        // Hazards cleared
        Achievement(id: "ach.kill100", name: "Exterminator", detail: "Clear 100 hazards",
                    symbolName: "bolt.shield.fill", coreReward: 15) { $0.lifetimeMonstersDefeated >= 100 },
        Achievement(id: "ach.kill1000", name: "Sector Sweeper", detail: "Clear 1,000 hazards",
                    symbolName: "bolt.shield", coreReward: 50) { $0.lifetimeMonstersDefeated >= 1000 },

        // Cutter strikes (taps)
        Achievement(id: "ach.tap1000", name: "Trigger Finger", detail: "Fire the cutter 1,000 times",
                    symbolName: "hand.point.up.left.fill", coreReward: 20) { $0.lifetimeTaps >= 1000 }
    ]

    static func byID(_ id: String) -> Achievement? { catalog.first { $0.id == id } }
}

//
//  Models.swift
//  RuneClicker — Shared
//
//  Core data models shared between the watchOS game and the iOS companion app.
//  These are plain Codable structs so they can be persisted (UserDefaults /
//  iCloud KV store) and sent across the WatchConnectivity link as dictionaries.
//

import Foundation

// MARK: - GameState

/// The complete, serializable state of a player's game.
/// This is the single source of truth that syncs between Watch and Phone.
public struct GameState: Codable, Equatable {
    public var currentLevel: Int
    public var monstersDefeatedThisLevel: Int
    public var gold: Double
    public var crystals: Int
    public var prestigeCount: Int

    /// Owned runes (upgradeable on the Watch with gold).
    public var runes: [Rune]
    /// Owned artifacts (bought on the Phone with crystals or IAP currency).
    public var ownedArtifactIDs: [String]
    /// Owned equipment items (bought / found, equipped on the Phone).
    public var ownedEquipmentIDs: [String]
    /// Currently equipped weapon / armor (nil = empty slot).
    public var equippedWeaponID: String?
    public var equippedArmorID: String?

    /// Last-cast Unix timestamp per spell id. Drives active/cooldown state
    /// (a spell is active while now < cast+duration, on cooldown until
    /// now < cast+cooldown). See `Spell`.
    public var spellCastTimes: [String: TimeInterval]

    // Lifetime stats (shown on the Stats screen; never reset by prestige).
    public var lifetimeGoldEarned: Double
    public var lifetimeMonstersDefeated: Int
    public var lifetimeTaps: Int
    public var lifetimeCachesCollected: Int

    /// Permanently unlocked achievement ids (see Achievements.swift).
    public var unlockedAchievementIDs: [String]

    // Daily Salvage Bonus tracking.
    public var lastDailyClaimTimestamp: TimeInterval
    public var dailyStreak: Int

    /// Unix timestamp (seconds) of the last time the engine saved state.
    /// Used to compute offline/idle earnings when the app re-opens.
    public var lastSeenTimestamp: TimeInterval

    public init(
        currentLevel: Int = 1,
        monstersDefeatedThisLevel: Int = 0,
        gold: Double = 0,
        crystals: Int = 0,
        prestigeCount: Int = 0,
        runes: [Rune] = Rune.starterRunes,
        ownedArtifactIDs: [String] = [],
        ownedEquipmentIDs: [String] = [],
        equippedWeaponID: String? = nil,
        equippedArmorID: String? = nil,
        spellCastTimes: [String: TimeInterval] = [:],
        lifetimeGoldEarned: Double = 0,
        lifetimeMonstersDefeated: Int = 0,
        lifetimeTaps: Int = 0,
        lifetimeCachesCollected: Int = 0,
        unlockedAchievementIDs: [String] = [],
        lastDailyClaimTimestamp: TimeInterval = 0,
        dailyStreak: Int = 0,
        lastSeenTimestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.currentLevel = currentLevel
        self.monstersDefeatedThisLevel = monstersDefeatedThisLevel
        self.gold = gold
        self.crystals = crystals
        self.prestigeCount = prestigeCount
        self.runes = runes
        self.ownedArtifactIDs = ownedArtifactIDs
        self.ownedEquipmentIDs = ownedEquipmentIDs
        self.equippedWeaponID = equippedWeaponID
        self.equippedArmorID = equippedArmorID
        self.spellCastTimes = spellCastTimes
        self.lifetimeGoldEarned = lifetimeGoldEarned
        self.lifetimeMonstersDefeated = lifetimeMonstersDefeated
        self.lifetimeTaps = lifetimeTaps
        self.lifetimeCachesCollected = lifetimeCachesCollected
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.lastDailyClaimTimestamp = lastDailyClaimTimestamp
        self.dailyStreak = dailyStreak
        self.lastSeenTimestamp = lastSeenTimestamp
    }
}

// MARK: - Derived stats

public extension GameState {
    /// How many monster kills are required to advance a level.
    static let killsPerLevel = 10

    /// Every 5th level is a Guardian boss fight.
    var isBossLevel: Bool { currentLevel % 5 == 0 }

    /// Permanent multiplier earned from prestiging (Desolation): +10% per prestige.
    var prestigeMultiplier: Double { 1.0 + 0.10 * Double(prestigeCount) }

    /// Total tap damage = base + rune tap bonuses + equipment, scaled by prestige.
    func tapDamage(artifacts: [Artifact], equipment: [Equipment]) -> Double {
        let runeBonus = runes.reduce(0.0) { $0 + $1.totalTapBonus }
        let weaponBonus = equippedWeapon(equipment)?.tapBonus ?? 0
        let base = (1.0 + runeBonus + weaponBonus)
        let artifactMult = ownedArtifacts(artifacts).reduce(1.0) { $0 * $1.tapMultiplier }
        return base * artifactMult * prestigeMultiplier
    }

    /// Total damage-per-second from runes + equipment + artifacts, scaled by prestige.
    func dps(artifacts: [Artifact], equipment: [Equipment]) -> Double {
        let runeBonus = runes.reduce(0.0) { $0 + $1.totalDpsBonus }
        let armorBonus = equippedArmor(equipment)?.dpsBonus ?? 0
        let base = runeBonus + armorBonus
        let artifactMult = ownedArtifacts(artifacts).reduce(1.0) { $0 * $1.dpsMultiplier }
        return base * artifactMult * prestigeMultiplier
    }

    func ownedArtifacts(_ all: [Artifact]) -> [Artifact] {
        all.filter { ownedArtifactIDs.contains($0.id) }
    }

    func equippedWeapon(_ all: [Equipment]) -> Equipment? {
        all.first { $0.id == equippedWeaponID }
    }

    func equippedArmor(_ all: [Equipment]) -> Equipment? {
        all.first { $0.id == equippedArmorID }
    }
}

// MARK: - Monster (a salvage hazard / hostile machine in a derelict)

public struct Monster: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var symbolName: String   // SF Symbol used as the "sprite"
    public var maxHP: Double
    public var hp: Double
    public var goldReward: Double    // scrap awarded on destruction
    public var isBoss: Bool          // a Sentinel (derelict defense core)
    public var isRare: Bool          // a glittering salvage cache (high reward)

    public init(id: String = UUID().uuidString,
                name: String,
                symbolName: String,
                maxHP: Double,
                goldReward: Double,
                isBoss: Bool = false,
                isRare: Bool = false) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.maxHP = maxHP
        self.hp = maxHP
        self.goldReward = goldReward
        self.isBoss = isBoss
        self.isRare = isRare
    }

    public var isDead: Bool { hp <= 0 }
    public var healthFraction: Double { max(0, min(1, hp / maxHP)) }
}

// MARK: - Monster generation

public enum Bestiary {
    // Hostile salvage hazards encountered while stripping a derelict.
    static let regularNames = [
        ("Scrap Drone", "fanblades.fill"),
        ("Corrosion Swarm", "aqi.medium"),
        ("Recon Skitter", "ant.fill"),
        ("Husk Bot", "figure.walk"),
        ("Arc Wraith", "bolt.horizontal.fill"),
        ("Spark Mite", "sparkle")
    ]

    // Sentinels — a derelict's automated defense cores (boss every 5 depths).
    static let bossNames = [
        ("Defense Sentinel", "shield.lefthalf.filled"),
        ("Cryo Warden", "snowflake"),
        ("Reactor Core", "atom"),
        ("Hull Sentinel", "cpu.fill")
    ]

    /// Build the hazard for a given depth. HP & scrap scale with depth.
    public static func monster(forLevel level: Int) -> Monster {
        let isBoss = level % 5 == 0
        // Exponential-ish HP curve, gentle early on.
        let hp = 10.0 * pow(1.18, Double(level)) * (isBoss ? 6.0 : 1.0)
        let reward = 2.0 * pow(1.15, Double(level)) * (isBoss ? 10.0 : 1.0)

        if isBoss {
            let (name, symbol) = bossNames[(level / 5 - 1) % bossNames.count]
            return Monster(name: name, symbolName: symbol,
                           maxHP: hp.rounded(), goldReward: reward.rounded(), isBoss: true)
        } else {
            let (name, symbol) = regularNames[level % regularNames.count]
            return Monster(name: name, symbolName: symbol,
                           maxHP: hp.rounded(), goldReward: reward.rounded(), isBoss: false)
        }
    }

    /// A rare "glittering cache": low HP, big scrap payout. Spawned by chance,
    /// boosted during certain World Events. (See WorldEvents / GameEngine.)
    public static func rareCache(forLevel level: Int) -> Monster {
        let hp = 10.0 * pow(1.18, Double(level)) * 0.5   // quick to crack
        let reward = 2.0 * pow(1.15, Double(level)) * 25.0
        return Monster(name: "Salvage Cache", symbolName: "shippingbox.fill",
                       maxHP: hp.rounded(), goldReward: reward.rounded(),
                       isBoss: false, isRare: true)
    }
}

// MARK: - Rune → "Rig Module" (upgraded on the Watch with scrap)
// NOTE: the Swift type stays `Rune` for internal stability; everything the
// player sees calls these "Modules". Same pattern for Artifact/Spell below.

public struct Rune: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var symbolName: String
    public var level: Int
    /// Per-level bonus to tap damage.
    public var tapBonusPerLevel: Double
    /// Per-level bonus to DPS.
    public var dpsBonusPerLevel: Double
    /// Gold cost of the *first* upgrade; scales with level.
    public var baseCost: Double

    public init(id: String, name: String, symbolName: String,
                level: Int = 0,
                tapBonusPerLevel: Double, dpsBonusPerLevel: Double,
                baseCost: Double) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.level = level
        self.tapBonusPerLevel = tapBonusPerLevel
        self.dpsBonusPerLevel = dpsBonusPerLevel
        self.baseCost = baseCost
    }

    public var totalTapBonus: Double { tapBonusPerLevel * Double(level) }
    public var totalDpsBonus: Double { dpsBonusPerLevel * Double(level) }

    /// Cost to buy the next level (grows 15% each level).
    public var nextUpgradeCost: Double {
        (baseCost * pow(1.15, Double(level))).rounded()
    }

    /// The starter rig modules (renamed runes).
    public static let starterRunes: [Rune] = [
        Rune(id: "module.cutter", name: "Cutter Module", symbolName: "bolt.fill",
             tapBonusPerLevel: 1.0, dpsBonusPerLevel: 0, baseCost: 10),
        Rune(id: "module.reclaimer", name: "Reclaimer Module", symbolName: "arrow.triangle.2.circlepath",
             tapBonusPerLevel: 0, dpsBonusPerLevel: 0.5, baseCost: 15),
        Rune(id: "module.overdrive", name: "Overdrive Module", symbolName: "gauge.high",
             tapBonusPerLevel: 2.0, dpsBonusPerLevel: 1.0, baseCost: 100)
    ]
}

// MARK: - Artifact → "Salvaged Tech" (bought on the Phone with Cores)

public struct Artifact: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var description: String
    public var symbolName: String
    public var tapMultiplier: Double
    public var dpsMultiplier: Double
    public var crystalCost: Int      // priced in Cores

    public init(id: String, name: String, description: String, symbolName: String,
                tapMultiplier: Double, dpsMultiplier: Double, crystalCost: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.symbolName = symbolName
        self.tapMultiplier = tapMultiplier
        self.dpsMultiplier = dpsMultiplier
        self.crystalCost = crystalCost
    }

    /// The Salvage Exchange catalog sold in the iOS app (priced in Cores).
    public static let catalog: [Artifact] = [
        Artifact(id: "tech.plasmacore", name: "Plasma Core",
                 description: "+50% cutter power", symbolName: "burst.fill",
                 tapMultiplier: 1.5, dpsMultiplier: 1.0, crystalCost: 50),
        Artifact(id: "tech.coolantcell", name: "Coolant Cell",
                 description: "+50% auto-salvage", symbolName: "thermometer.snowflake",
                 tapMultiplier: 1.0, dpsMultiplier: 1.5, crystalCost: 50),
        Artifact(id: "tech.coprocessor", name: "AI Coprocessor",
                 description: "+100% cutter & auto", symbolName: "cpu.fill",
                 tapMultiplier: 2.0, dpsMultiplier: 2.0, crystalCost: 250),
        Artifact(id: "tech.singularity", name: "Singularity Drive",
                 description: "+200% auto-salvage", symbolName: "circle.dotted",
                 tapMultiplier: 1.0, dpsMultiplier: 3.0, crystalCost: 500)
    ]
}

// MARK: - Equipment (weapon / armor slots, equipped on Phone)

public enum EquipmentSlot: String, Codable {
    case weapon
    case armor
}

public enum Rarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary

    public var colorName: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

public struct Equipment: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var slot: EquipmentSlot
    public var rarity: Rarity
    public var symbolName: String
    /// Flat bonus to tap damage (weapons).
    public var tapBonus: Double
    /// Flat bonus to DPS (armor).
    public var dpsBonus: Double

    public init(id: String, name: String, slot: EquipmentSlot, rarity: Rarity,
                symbolName: String, tapBonus: Double = 0, dpsBonus: Double = 0) {
        self.id = id
        self.name = name
        self.slot = slot
        self.rarity = rarity
        self.symbolName = symbolName
        self.tapBonus = tapBonus
        self.dpsBonus = dpsBonus
    }

    /// Full gear catalog: Cutters (weapon slot) and Plating (armor slot).
    public static let catalog: [Equipment] = [
        // Cutters (boost cutter / tap power)
        Equipment(id: "eq.arccutter", name: "Arc Cutter", slot: .weapon,
                  rarity: .common, symbolName: "scissors", tapBonus: 2),
        Equipment(id: "eq.plasmacutter", name: "Plasma Cutter", slot: .weapon,
                  rarity: .rare, symbolName: "flame", tapBonus: 6),
        Equipment(id: "eq.ionlance", name: "Ion Lance", slot: .weapon,
                  rarity: .epic, symbolName: "bolt", tapBonus: 15),
        Equipment(id: "eq.antimatter", name: "Antimatter Cutter", slot: .weapon,
                  rarity: .legendary, symbolName: "bolt.trianglebadge.exclamationmark",
                  tapBonus: 40),
        // Plating (boost auto-salvage / DPS)
        Equipment(id: "eq.scrapplate", name: "Scrap Plating", slot: .armor,
                  rarity: .common, symbolName: "square.split.bottomrightquarter", dpsBonus: 1),
        Equipment(id: "eq.alloyplate", name: "Alloy Plating", slot: .armor,
                  rarity: .rare, symbolName: "shield.lefthalf.filled", dpsBonus: 4),
        Equipment(id: "eq.ablative", name: "Ablative Shield", slot: .armor,
                  rarity: .epic, symbolName: "shield.fill", dpsBonus: 10),
        Equipment(id: "eq.aegisfield", name: "Aegis Field", slot: .armor,
                  rarity: .legendary, symbolName: "checkmark.shield.fill", dpsBonus: 25)
    ]
}

// MARK: - IAP Products (Core packs)

/// Core pack definitions. The `id` here MUST match the product IDs you
/// register in App Store Connect and in the local Products.storekit file.
public struct CrystalPack: Identifiable {
    public let id: String
    public let displayName: String
    public let crystals: Int      // number of Cores granted

    public static let all: [CrystalPack] = [
        CrystalPack(id: "com.salvager.cores.small",  displayName: "Core Cache",   crystals: 100),
        CrystalPack(id: "com.salvager.cores.medium", displayName: "Core Crate",   crystals: 500),
        CrystalPack(id: "com.salvager.cores.large",  displayName: "Core Vault",   crystals: 1200)
    ]

    public static func crystals(forProductID id: String) -> Int {
        all.first { $0.id == id }?.crystals ?? 0
    }
}

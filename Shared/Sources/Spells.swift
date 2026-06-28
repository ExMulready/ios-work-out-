//
//  Spells.swift
//  Salvager — Shared
//
//  Timed buff "Overclocks": trigger one to multiply your cutter (tap) and/or
//  auto-salvage (DPS) for a short window, then wait out a cooldown. State is
//  tracked by a single "last cast" timestamp per overclock in
//  GameState.spellCastTimes. (Swift type stays `Spell` for internal stability.)
//

import Foundation

public struct Spell: Codable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var symbolName: String
    /// Tap-damage multiplier while the spell is active.
    public var tapMultiplier: Double
    /// DPS multiplier while the spell is active.
    public var dpsMultiplier: Double
    /// How long the buff lasts, in seconds.
    public var duration: TimeInterval
    /// Time from cast until it can be cast again (>= duration), in seconds.
    public var cooldown: TimeInterval
    /// Gold cost to cast.
    public var goldCost: Double

    public init(id: String, name: String, symbolName: String,
                tapMultiplier: Double, dpsMultiplier: Double,
                duration: TimeInterval, cooldown: TimeInterval, goldCost: Double) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tapMultiplier = tapMultiplier
        self.dpsMultiplier = dpsMultiplier
        self.duration = duration
        self.cooldown = cooldown
        self.goldCost = goldCost
    }

    /// The Overclocks available on the Watch (renamed spells).
    public static let catalog: [Spell] = [
        Spell(id: "overclock.frenzy", name: "Cutter Overclock", symbolName: "bolt.fill",
              tapMultiplier: 3.0, dpsMultiplier: 1.0,
              duration: 15, cooldown: 60, goldCost: 50),
        Spell(id: "overclock.surge", name: "Reactor Surge", symbolName: "waveform.path.ecg",
              tapMultiplier: 1.0, dpsMultiplier: 4.0,
              duration: 20, cooldown: 90, goldCost: 120),
        Spell(id: "overclock.meltdown", name: "Core Meltdown", symbolName: "burst.fill",
              tapMultiplier: 5.0, dpsMultiplier: 5.0,
              duration: 10, cooldown: 180, goldCost: 500)
    ]
}

/// Runtime status of a spell, computed from `cast` time vs `now`.
public enum SpellStatus: Equatable {
    case ready
    case active(remaining: TimeInterval)
    case cooldown(remaining: TimeInterval)

    public var isActive: Bool {
        if case .active = self { return true }
        return false
    }
}

public extension Spell {
    /// Resolve this spell's status from a cast timestamp (nil = never cast).
    func status(cast: TimeInterval?, now: TimeInterval = Date().timeIntervalSince1970) -> SpellStatus {
        guard let cast else { return .ready }
        if now < cast + duration { return .active(remaining: cast + duration - now) }
        if now < cast + cooldown { return .cooldown(remaining: cast + cooldown - now) }
        return .ready
    }
}

public extension GameState {
    /// Combined tap multiplier from all currently-active spells.
    func activeSpellTapMultiplier(now: TimeInterval = Date().timeIntervalSince1970) -> Double {
        Spell.catalog.reduce(1.0) { acc, spell in
            spell.status(cast: spellCastTimes[spell.id], now: now).isActive
                ? acc * spell.tapMultiplier : acc
        }
    }

    /// Combined DPS multiplier from all currently-active spells.
    func activeSpellDpsMultiplier(now: TimeInterval = Date().timeIntervalSince1970) -> Double {
        Spell.catalog.reduce(1.0) { acc, spell in
            spell.status(cast: spellCastTimes[spell.id], now: now).isActive
                ? acc * spell.dpsMultiplier : acc
        }
    }
}

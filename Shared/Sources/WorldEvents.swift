//
//  WorldEvents.swift
//  Salvager — Shared
//
//  The game's signature mechanic: the live state of the sector changes with the
//  real-world clock. The hour of day and day of week deterministically select
//  an active "World Event" that modifies scrap payouts, enemy toughness, rare
//  cache odds, and what the Salvage Exchange stocks.
//
//  Deterministic from the clock = identical on Watch, Phone, and the
//  complication with NO server. Players learn the rhythm ("the Ion Storm hits
//  in the evening") and come back at specific times — that recurring,
//  time-driven loop is what makes this more than a generic idle clicker.
//

import Foundation

public struct WorldEvent: Identifiable, Equatable {
    public var id: String
    public var name: String
    public var blurb: String
    public var symbolName: String
    public var colorName: String      // maps to a SwiftUI Color in the UI

    /// Multiplier applied to all scrap rewards while active.
    public var scrapMultiplier: Double
    /// Multiplier applied to enemy HP while active (risk/reward).
    public var enemyHPMultiplier: Double
    /// Added to the base chance that a spawn is a rare Salvage Cache (0...1).
    public var rareCacheBonus: Double
    /// Artifact ids the Exchange "features" (discounted) during this event.
    public var featuredTechIDs: [String]
    /// Rare, dramatic event tier — gets special pulsing UI treatment.
    public var isAnomaly: Bool

    public init(id: String, name: String, blurb: String, symbolName: String,
                colorName: String, scrapMultiplier: Double = 1, enemyHPMultiplier: Double = 1,
                rareCacheBonus: Double = 0, featuredTechIDs: [String] = [],
                isAnomaly: Bool = false) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.symbolName = symbolName
        self.colorName = colorName
        self.scrapMultiplier = scrapMultiplier
        self.enemyHPMultiplier = enemyHPMultiplier
        self.rareCacheBonus = rareCacheBonus
        self.featuredTechIDs = featuredTechIDs
        self.isAnomaly = isAnomaly
    }
}

// MARK: - Catalog

public extension WorldEvent {
    static let deadCalm = WorldEvent(
        id: "evt.deadcalm", name: "Dead Calm", blurb: "The sector is quiet. Standard salvage.",
        symbolName: "moon.stars.fill", colorName: "gray")

    static let ionStorm = WorldEvent(
        id: "evt.ionstorm", name: "Ion Storm", blurb: "Charged debris everywhere — scrap payouts surge.",
        symbolName: "bolt.fill", colorName: "yellow",
        scrapMultiplier: 1.5, rareCacheBonus: 0.02)

    static let pirateRaid = WorldEvent(
        id: "evt.pirateraid", name: "Pirate Raid", blurb: "Raiders prowl. Tougher foes, richer hauls.",
        symbolName: "shippingbox.and.arrow.backward.fill", colorName: "red",
        scrapMultiplier: 1.75, enemyHPMultiplier: 1.4, rareCacheBonus: 0.01,
        featuredTechIDs: ["tech.plasmacore"])

    static let salvageRush = WorldEvent(
        id: "evt.salvagerush", name: "Salvage Rush", blurb: "A fresh wreck field — caches everywhere!",
        symbolName: "sparkles", colorName: "cyan",
        scrapMultiplier: 1.25, rareCacheBonus: 0.08,
        featuredTechIDs: ["tech.coprocessor", "tech.singularity"])

    static let solarEclipse = WorldEvent(
        id: "evt.eclipse", name: "Solar Eclipse", blurb: "Sensors dimmed; auto-salvage runs hot.",
        symbolName: "circle.lefthalf.filled", colorName: "purple",
        scrapMultiplier: 1.2, rareCacheBonus: 0.0, featuredTechIDs: ["tech.coolantcell"])

    static let meteorShower = WorldEvent(
        id: "evt.meteor", name: "Meteor Shower", blurb: "Debris rains in — caches and scrap aplenty.",
        symbolName: "sparkles.rectangle.stack.fill", colorName: "orange",
        scrapMultiplier: 1.4, rareCacheBonus: 0.05)

    static let derelictBloom = WorldEvent(
        id: "evt.bloom", name: "Derelict Bloom", blurb: "Hull rot spreads — tougher husks, fat payouts.",
        symbolName: "aqi.high", colorName: "green",
        scrapMultiplier: 1.6, enemyHPMultiplier: 1.25, featuredTechIDs: ["tech.coprocessor"])

    /// All scheduled (non-anomaly) events.
    static let all: [WorldEvent] = [
        deadCalm, ionStorm, pirateRaid, salvageRush, solarEclipse, meteorShower, derelictBloom
    ]

    // MARK: Anomalies (rare, dramatic — selected by a clock-seeded chance)

    static let quantumAnomaly = WorldEvent(
        id: "evt.quantum", name: "Quantum Anomaly", blurb: "Reality folds — everything pays triple!",
        symbolName: "atom", colorName: "cyan",
        scrapMultiplier: 3.0, rareCacheBonus: 0.10,
        featuredTechIDs: ["tech.singularity"], isAnomaly: true)

    static let ghostFleet = WorldEvent(
        id: "evt.ghost", name: "Ghost Fleet", blurb: "A lost armada drifts in — dangerous, lucrative.",
        symbolName: "moon.haze.fill", colorName: "purple",
        scrapMultiplier: 2.5, enemyHPMultiplier: 1.5, rareCacheBonus: 0.05, isAnomaly: true)

    static let anomalies: [WorldEvent] = [quantumAnomaly, ghostFleet]
}

// MARK: - Scheduler (deterministic from the clock)

public enum WorldEventScheduler {

    /// The event active at a given date. A rare clock-seeded **anomaly** can
    /// override the schedule for a 4-hour block; otherwise weekends get a
    /// Salvage Rush window and weekdays rotate through events on a fixed rota,
    /// so the schedule stays predictable and learnable.
    public static func event(at date: Date = Date(), calendar: Calendar = .current) -> WorldEvent {
        // 1) Rare anomaly roll (deterministic per 4-hour block, ~1 in 11 blocks).
        if let anomaly = anomaly(at: date, calendar: calendar) {
            return anomaly
        }

        let comps = calendar.dateComponents([.hour, .weekday], from: date)
        let hour = comps.hour ?? 0
        let weekday = comps.weekday ?? 1   // 1 = Sunday, 7 = Saturday

        // 2) Weekend prime hours: Salvage Rush.
        let isWeekend = (weekday == 1 || weekday == 7)
        if isWeekend && (10...22).contains(hour) {
            return .salvageRush
        }

        // 3) Otherwise rotate by a 4-hour block of the day.
        switch hour {
        case 0..<4:   return .solarEclipse   // overnight
        case 4..<8:   return .deadCalm       // early morning
        case 8..<12:  return .ionStorm       // morning
        case 12..<16: return .meteorShower   // midday
        case 16..<20: return .pirateRaid     // evening prime time
        default:      return .derelictBloom  // late evening (20–24)
        }
    }

    /// A deterministic pseudo-random anomaly for the date's 4-hour block, or nil.
    private static func anomaly(at date: Date, calendar: Calendar) -> WorldEvent? {
        let c = calendar.dateComponents([.year, .dayOfYear, .hour], from: date)
        let block = (c.hour ?? 0) / 4
        let seed = (((c.year ?? 0) * 1000) + (c.dayOfYear ?? 0)) * 6 + block
        // Simple LCG hash → stable per block, identical on every device.
        let r = (seed &* 1_103_515_245 &+ 12_345) & 0x7fff_ffff
        guard r % 11 == 0 else { return nil }          // ~9% of blocks
        return WorldEvent.anomalies[r % WorldEvent.anomalies.count]
    }

    /// Seconds until the active event is expected to change (for a countdown).
    public static func secondsUntilNextChange(from date: Date = Date(),
                                              calendar: Calendar = .current) -> TimeInterval {
        let current = event(at: date, calendar: calendar)
        // Probe forward in 5-minute steps up to 24h to find the next switch.
        let step: TimeInterval = 300
        var t: TimeInterval = step
        while t < 24 * 3600 {
            if event(at: date.addingTimeInterval(t), calendar: calendar) != current {
                return t
            }
            t += step
        }
        return t
    }
}

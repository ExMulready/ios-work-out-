//
//  GameEngine.swift
//  RuneClicker — Shared
//
//  The observable game engine that drives the clicker loop. Owns the live
//  GameState, the current Monster, and a 1-second timer that applies idle DPS.
//  Used by the watchOS app directly; the iOS app uses a lighter mirror of the
//  state (it doesn't run the battle loop, it just shops & syncs).
//

import Foundation
import Combine

@MainActor
public final class GameEngine: ObservableObject {

    // MARK: Published state (drives SwiftUI)

    @Published public private(set) var state: GameState
    @Published public private(set) var currentMonster: Monster
    /// Gold earned while away, shown in a "Welcome back" prompt (nil = none).
    @Published public var offlineEarnings: Double?
    /// Seconds remaining on a boss fight; nil when not fighting a boss.
    @Published public private(set) var bossTimeRemaining: Int?
    /// The live, clock-driven World Event (signature mechanic).
    @Published public private(set) var currentEvent: WorldEvent
    /// Newly-unlocked achievements awaiting a toast (FIFO). UI pops these.
    @Published public var recentlyUnlocked: [Achievement] = []

    // MARK: Bio-Boost (HealthKit-driven — set by the Watch's HealthManager)

    /// Today's active energy burned (kcal), fed in from HealthKit.
    @Published public private(set) var bioActiveEnergy: Double = 0
    /// Today's Apple Exercise minutes, fed in from HealthKit.
    @Published public private(set) var bioExerciseMinutes: Double = 0

    /// How much real-world activity boosts in-game power today (×1…×2).
    /// 1000 kcal OR 120 exercise minutes ≈ the +100% cap, blended.
    public var bioBoostMultiplier: Double {
        let energyPart = bioActiveEnergy / 1000.0
        let exercisePart = bioExerciseMinutes / 120.0
        let bonus = min(1.0, energyPart + exercisePart)   // cap at +100%
        return 1.0 + bonus
    }

    public var hasBioBoost: Bool { bioBoostMultiplier > 1.0 }

    /// Called by the Watch HealthManager when fresh HealthKit data arrives.
    public func updateBioMetrics(activeEnergy: Double, exerciseMinutes: Double) {
        bioActiveEnergy = activeEnergy
        bioExerciseMinutes = exerciseMinutes
    }

    // MARK: Static catalogs (could be remote-config'd later)

    public let artifacts = Artifact.catalog
    public let equipment = Equipment.catalog

    private var timer: Timer?
    private var accumulatedFractionalGold: Double = 0
    private let bossTimeLimit = 30   // seconds to beat a Sentinel
    private let baseRareCacheChance = 0.02   // 2% before event bonuses

    // MARK: Init

    public init(state: GameState = GameEngine.load()) {
        self.state = state
        self.currentEvent = WorldEventScheduler.event()
        self.currentMonster = Monster.forLevelChecked(state.currentLevel)
        applyEventHP(to: &currentMonster)
        applyOfflineEarnings()
        if state.isBossLevel { bossTimeRemaining = bossTimeLimit }
    }

    /// Seconds until the active World Event is expected to change.
    public var secondsUntilEventChange: TimeInterval {
        WorldEventScheduler.secondsUntilNextChange()
    }

    // MARK: Derived stats

    public let spells = Spell.catalog

    /// Tap damage including active spell buffs and the HealthKit Bio-Boost.
    public var tapDamage: Double {
        state.tapDamage(artifacts: artifacts, equipment: equipment)
            * state.activeSpellTapMultiplier() * bioBoostMultiplier
    }

    /// DPS including active spell buffs and the HealthKit Bio-Boost.
    public var dps: Double {
        state.dps(artifacts: artifacts, equipment: equipment)
            * state.activeSpellDpsMultiplier() * bioBoostMultiplier
    }

    /// True while any spell buff is currently running (drives the UI banner).
    public var hasActiveSpell: Bool {
        spells.contains { status(of: $0).isActive }
    }

    /// Current status (ready / active / cooldown) of a spell.
    public func status(of spell: Spell) -> SpellStatus {
        spell.status(cast: state.spellCastTimes[spell.id])
    }

    // MARK: Timer lifecycle

    /// Start the 1-second idle loop. Call from `.onAppear` / when foregrounded.
    public func start() {
        stop()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        save()
    }

    // MARK: Core loop

    private func tick() {
        // Refresh the live World Event (publishes only when it actually changes).
        let nowEvent = WorldEventScheduler.event()
        if nowEvent != currentEvent { currentEvent = nowEvent }

        // Apply idle DPS (fractional gold accumulates so low DPS still pays out).
        applyDamage(dps)

        // Boss countdown.
        if state.isBossLevel, var remaining = bossTimeRemaining {
            remaining -= 1
            if remaining <= 0 {
                failBoss()
            } else {
                bossTimeRemaining = remaining
            }
        }
        save()
    }

    // MARK: Player actions

    /// Called when the player taps the attack button on the Watch.
    public func tapAttack() {
        state.lifetimeTaps += 1
        applyDamage(tapDamage)
    }

    /// Apply `amount` of damage to the current monster, handling death/rewards.
    private func applyDamage(_ amount: Double) {
        guard amount > 0 else { return }
        currentMonster.hp -= amount
        if currentMonster.isDead {
            awardKill()
        }
    }

    private func awardKill() {
        // Scrap payout is boosted by the active World Event.
        let scrap = currentMonster.goldReward * currentEvent.scrapMultiplier
        state.gold += scrap
        state.lifetimeGoldEarned += scrap
        state.lifetimeMonstersDefeated += 1

        // A rare cache doesn't count toward level progress — it's a bonus pickup.
        if currentMonster.isRare {
            state.lifetimeCachesCollected += 1
            checkAchievements()
            spawnMonster()
            return
        }

        if currentMonster.isBoss {
            advanceLevel()
        } else {
            state.monstersDefeatedThisLevel += 1
            if state.monstersDefeatedThisLevel >= GameState.killsPerLevel {
                advanceLevel()
            } else {
                spawnMonster()
            }
        }
        checkAchievements()
    }

    private func advanceLevel() {
        state.monstersDefeatedThisLevel = 0
        state.currentLevel += 1

        // Reaching level 100 unlocks Desolation (prestige) — handled by UI prompt.
        spawnMonster()
        bossTimeRemaining = state.isBossLevel ? bossTimeLimit : nil
        save()
    }

    private func spawnMonster() {
        // On non-boss depths, a World Event–boosted chance yields a rare cache.
        let rareChance = baseRareCacheChance + currentEvent.rareCacheBonus
        if !state.isBossLevel && Double.random(in: 0...1) < rareChance {
            currentMonster = Bestiary.rareCache(forLevel: state.currentLevel)
            return   // caches are not affected by enemy-HP modifiers
        }
        var m = Monster.forLevelChecked(state.currentLevel)
        applyEventHP(to: &m)
        currentMonster = m
    }

    /// Scale a hazard's HP by the active event's enemy-HP modifier (not caches).
    private func applyEventHP(to monster: inout Monster) {
        guard !monster.isRare, currentEvent.enemyHPMultiplier != 1 else { return }
        monster.maxHP = (monster.maxHP * currentEvent.enemyHPMultiplier).rounded()
        monster.hp = monster.maxHP
    }

    private func failBoss() {
        // Boss timer expired: monster heals to full, timer resets. (Forgiving.)
        currentMonster.hp = currentMonster.maxHP
        bossTimeRemaining = bossTimeLimit
    }

    // MARK: Rune upgrades (spends gold)

    @discardableResult
    public func upgradeRune(_ runeID: String) -> Bool {
        guard let idx = state.runes.firstIndex(where: { $0.id == runeID }) else { return false }
        let cost = state.runes[idx].nextUpgradeCost
        guard state.gold >= cost else { return false }
        state.gold -= cost
        state.runes[idx].level += 1
        save()
        return true
    }

    // MARK: Spells (timed buffs)

    /// Cast a spell if it's off cooldown and affordable. Returns false otherwise.
    @discardableResult
    public func castSpell(_ spellID: String) -> Bool {
        guard let spell = spells.first(where: { $0.id == spellID }) else { return false }
        guard case .ready = status(of: spell) else { return false }
        guard state.gold >= spell.goldCost else { return false }
        state.gold -= spell.goldCost
        state.spellCastTimes[spell.id] = Date().timeIntervalSince1970
        save()
        return true
    }

    // MARK: Achievements

    public let achievements = Achievement.catalog

    public func isUnlocked(_ achievement: Achievement) -> Bool {
        state.unlockedAchievementIDs.contains(achievement.id)
    }

    /// Unlock any newly-earned achievements, credit their Core rewards, and
    /// queue them for a toast. Cheap enough to call after any state change.
    private func checkAchievements() {
        for ach in achievements where !state.unlockedAchievementIDs.contains(ach.id) {
            if ach.isEarned(state) {
                state.unlockedAchievementIDs.append(ach.id)
                state.crystals += ach.coreReward
                recentlyUnlocked.append(ach)
            }
        }
    }

    /// UI calls this to remove the front toast after showing it.
    public func popRecentlyUnlocked() {
        if !recentlyUnlocked.isEmpty { recentlyUnlocked.removeFirst() }
    }

    // MARK: Daily Salvage Bonus

    /// True if today's bonus hasn't been claimed yet.
    public var isDailyRewardAvailable: Bool {
        let last = Date(timeIntervalSince1970: state.lastDailyClaimTimestamp)
        return !Calendar.current.isDateInToday(last)
    }

    /// Cores the next claim will grant (base 10 + streak, capped at 50).
    public var dailyRewardPreview: Int {
        let last = Date(timeIntervalSince1970: state.lastDailyClaimTimestamp)
        let continuing = Calendar.current.isDateInYesterday(last)
        let streak = continuing ? state.dailyStreak + 1 : 1
        return min(10 + (streak - 1) * 5, 50)
    }

    /// Claim today's Daily Salvage Bonus. Returns the Cores granted (0 if none).
    @discardableResult
    public func claimDailyReward() -> Int {
        guard isDailyRewardAvailable else { return 0 }
        let last = Date(timeIntervalSince1970: state.lastDailyClaimTimestamp)
        if Calendar.current.isDateInYesterday(last) {
            state.dailyStreak += 1
        } else {
            state.dailyStreak = 1   // streak broken (or first ever)
        }
        let reward = min(10 + (state.dailyStreak - 1) * 5, 50)
        state.crystals += reward
        state.lastDailyClaimTimestamp = Date().timeIntervalSince1970
        save()
        return reward
    }

    // MARK: Prestige / Desolation

    public var canPrestige: Bool { state.currentLevel >= 100 }

    /// Begin Desolation: reset progress, keep artifacts & equipment, +10% DPS forever.
    public func prestige() {
        guard canPrestige else { return }
        let kept = (
            crystals: state.crystals,
            artifacts: state.ownedArtifactIDs,
            equipment: state.ownedEquipmentIDs,
            weapon: state.equippedWeaponID,
            armor: state.equippedArmorID,
            prestige: state.prestigeCount + 1
        )
        state = GameState(
            currentLevel: 1,
            gold: 0,
            crystals: kept.crystals,
            prestigeCount: kept.prestige,
            runes: Rune.starterRunes,
            ownedArtifactIDs: kept.artifacts,
            ownedEquipmentIDs: kept.equipment,
            equippedWeaponID: kept.weapon,
            equippedArmorID: kept.armor,
            // Lifetime stats, achievements & daily streak survive a Deep Jump.
            lifetimeGoldEarned: state.lifetimeGoldEarned,
            lifetimeMonstersDefeated: state.lifetimeMonstersDefeated,
            lifetimeTaps: state.lifetimeTaps,
            lifetimeCachesCollected: state.lifetimeCachesCollected,
            unlockedAchievementIDs: state.unlockedAchievementIDs,
            lastDailyClaimTimestamp: state.lastDailyClaimTimestamp,
            dailyStreak: state.dailyStreak
        )
        checkAchievements()   // first/repeat Deep Jump achievements
        spawnMonster()
        save()
    }

    // MARK: Sync from companion (Phone → Watch)

    /// Merge an authoritative update coming from the iOS app (purchases/equips).
    /// We trust the phone for crystals/artifacts/equipment; the watch keeps
    /// gameplay progress (level, gold, runes).
    public func mergeFromCompanion(_ incoming: GameState) {
        state.crystals = incoming.crystals
        state.ownedArtifactIDs = incoming.ownedArtifactIDs
        state.ownedEquipmentIDs = incoming.ownedEquipmentIDs
        state.equippedWeaponID = incoming.equippedWeaponID
        state.equippedArmorID = incoming.equippedArmorID
        save()
    }

    // MARK: Offline / idle earnings

    private func applyOfflineEarnings() {
        let now = Date().timeIntervalSince1970
        let elapsed = now - state.lastSeenTimestamp
        guard elapsed > 5 else { return }   // ignore tiny gaps
        // Cap offline accrual at 8 hours so it stays meaningful but bounded.
        let cappedSeconds = min(elapsed, 8 * 3600)
        let earned = dps * cappedSeconds
        if earned > 0 {
            state.gold += earned
            offlineEarnings = earned
        }
        state.lastSeenTimestamp = now
    }

    // MARK: Persistence (via the App Group–backed SharedStore)

    public func save() {
        state.lastSeenTimestamp = Date().timeIntervalSince1970
        SharedStore.save(state)
    }

    nonisolated public static func load() -> GameState {
        SharedStore.load()
    }

    /// Wipe all progress (used by the Stats screen's reset).
    public func resetAllProgress() {
        state = GameState()
        spawnMonster()
        save()
    }
}

// MARK: - Helpers

private extension Monster {
    /// Wrapper so the engine never crashes on weird level values.
    static func forLevelChecked(_ level: Int) -> Monster {
        Bestiary.monster(forLevel: max(1, level))
    }
}

// MARK: - Number formatting (shared UI helper)

public extension Double {
    /// Compact display for big idle numbers: 1.2K, 3.4M, 5.6B…
    var abbreviated: String {
        let n = self
        switch abs(n) {
        case 1_000_000_000_000...:
            return String(format: "%.1fT", n / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "%.1fB", n / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", n / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", n / 1_000)
        default:
            return String(format: "%.0f", n)
        }
    }
}

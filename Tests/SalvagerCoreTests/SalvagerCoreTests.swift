//
//  SalvagerCoreTests.swift
//  Salvager — core logic tests
//
//  Exercises the platform-agnostic game logic so CI catches regressions in the
//  shared model & rules layer. These run via `swift test` on a macOS runner.
//

import XCTest
@testable import SalvagerCore

final class SalvagerCoreTests: XCTestCase {

    func testNewGameDefaults() {
        let s = GameState()
        XCTAssertEqual(s.currentLevel, 1)
        XCTAssertEqual(s.gold, 0)
        XCTAssertFalse(s.runes.isEmpty, "starter modules should exist")
        XCTAssertTrue(s.unlockedAchievementIDs.isEmpty)
    }

    func testBossEveryFifthDepth() {
        XCTAssertTrue(Bestiary.monster(forLevel: 5).isBoss)
        XCTAssertFalse(Bestiary.monster(forLevel: 4).isBoss)
        XCTAssertTrue(GameState(currentLevel: 10).isBossLevel)
        XCTAssertFalse(GameState(currentLevel: 11).isBossLevel)
    }

    func testHazardHPScalesWithDepth() {
        let early = Bestiary.monster(forLevel: 1).maxHP
        let deep = Bestiary.monster(forLevel: 12).maxHP
        XCTAssertGreaterThan(deep, early, "HP should scale up with depth")
    }

    func testRareCachePaysMoreThanRegularHazard() {
        let cache = Bestiary.rareCache(forLevel: 7)
        let regular = Bestiary.monster(forLevel: 7)   // 7 is not a boss depth
        XCTAssertTrue(cache.isRare)
        XCTAssertGreaterThan(cache.goldReward, regular.goldReward)
    }

    func testWorldEventSchedulerIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = WorldEventScheduler.event(at: date)
        let second = WorldEventScheduler.event(at: date)
        XCTAssertEqual(first, second, "same clock → same event on every device")
    }

    func testPrestigeMultiplierGrows() {
        XCTAssertEqual(GameState(prestigeCount: 0).prestigeMultiplier, 1.0, accuracy: 0.0001)
        XCTAssertEqual(GameState(prestigeCount: 3).prestigeMultiplier, 1.3, accuracy: 0.0001)
    }

    func testAchievementUnlockThreshold() throws {
        let depth5 = try XCTUnwrap(Achievement.byID("ach.depth5"))
        XCTAssertTrue(depth5.isEarned(GameState(currentLevel: 5)))
        XCTAssertFalse(depth5.isEarned(GameState(currentLevel: 4)))
    }

    func testSpellStartsReady() {
        let spell = Spell.catalog[0]
        XCTAssertEqual(spell.status(cast: nil), .ready)
    }

    func testNumberAbbreviation() {
        XCTAssertEqual(1_500.0.abbreviated, "1.5K")
        XCTAssertEqual(2_000_000.0.abbreviated, "2.0M")
    }
}

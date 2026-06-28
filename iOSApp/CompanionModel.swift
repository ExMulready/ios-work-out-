//
//  CompanionModel.swift
//  RuneClicker — iOS Companion
//
//  Holds the phone-side mirror of GameState. The phone owns the wallet &
//  inventory: buying artifacts, equipping gear, and crediting IAP crystals.
//  Gameplay progress (level/gold/runes) arrives from the Watch and is shown
//  read-only here.
//

import Foundation
import Combine

@MainActor
public final class CompanionModel: ObservableObject {
    @Published public var state: GameState

    public let artifacts = Artifact.catalog
    public let equipment = Equipment.catalog

    public init() {
        self.state = SharedStore.load()
    }

    // MARK: Catalog views

    public var ownedArtifacts: [Artifact] {
        artifacts.filter { state.ownedArtifactIDs.contains($0.id) }
    }

    public var ownedEquipment: [Equipment] {
        equipment.filter { state.ownedEquipmentIDs.contains($0.id) }
    }

    public func ownedEquipment(in slot: EquipmentSlot) -> [Equipment] {
        ownedEquipment.filter { $0.slot == slot }
    }

    // MARK: World Event (live, clock-driven)

    /// The currently active World Event (same schedule as the Watch/engine).
    public var currentEvent: WorldEvent { WorldEventScheduler.event() }

    /// Whether a piece of tech is featured (discounted) by the current event.
    public func isFeatured(_ artifact: Artifact) -> Bool {
        currentEvent.featuredTechIDs.contains(artifact.id)
    }

    /// Core cost after any event discount (25% off when featured).
    public func effectiveCost(for artifact: Artifact) -> Int {
        isFeatured(artifact)
            ? Int((Double(artifact.crystalCost) * 0.75).rounded())
            : artifact.crystalCost
    }

    // MARK: Purchases (Cores)

    @discardableResult
    public func buyArtifact(_ artifact: Artifact) -> Bool {
        guard !state.ownedArtifactIDs.contains(artifact.id) else { return false }
        let cost = effectiveCost(for: artifact)
        guard state.crystals >= cost else { return false }
        state.crystals -= cost
        state.ownedArtifactIDs.append(artifact.id)
        persistAndSync()
        return true
    }

    /// Equipment is unlocked with crystals too (tweak pricing as you like).
    public func crystalCost(for equipment: Equipment) -> Int {
        switch equipment.rarity {
        case .common: return 25
        case .rare: return 75
        case .epic: return 200
        case .legendary: return 600
        }
    }

    @discardableResult
    public func buyEquipment(_ item: Equipment) -> Bool {
        guard !state.ownedEquipmentIDs.contains(item.id) else { return false }
        let cost = crystalCost(for: item)
        guard state.crystals >= cost else { return false }
        state.crystals -= cost
        state.ownedEquipmentIDs.append(item.id)
        persistAndSync()
        return true
    }

    // MARK: Equip

    public func equip(_ item: Equipment) {
        switch item.slot {
        case .weapon: state.equippedWeaponID = item.id
        case .armor: state.equippedArmorID = item.id
        }
        persistAndSync()
    }

    public func unequip(slot: EquipmentSlot) {
        switch slot {
        case .weapon: state.equippedWeaponID = nil
        case .armor: state.equippedArmorID = nil
        }
        persistAndSync()
    }

    // MARK: IAP

    /// Credit crystals after a verified StoreKit purchase.
    public func creditCrystals(_ amount: Int) {
        state.crystals += amount
        persistAndSync()
    }

    // MARK: Sync from Watch

    /// Merge gameplay progress coming from the Watch (level/gold/runes).
    public func mergeFromWatch(_ incoming: GameState) {
        state.currentLevel = incoming.currentLevel
        state.monstersDefeatedThisLevel = incoming.monstersDefeatedThisLevel
        state.gold = incoming.gold
        state.prestigeCount = incoming.prestigeCount
        state.runes = incoming.runes
        persist()   // don't echo straight back to the watch
    }

    // MARK: Persistence + sync helpers

    private func persistAndSync() {
        persist()
        WatchConnectivityManager.shared.pushState(state)
    }

    private func persist() {
        state.lastSeenTimestamp = Date().timeIntervalSince1970
        SharedStore.save(state)
    }
}

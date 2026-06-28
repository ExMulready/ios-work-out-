//
//  HealthManager.swift
//  Salvager — watchOS
//
//  Reads the player's real-world activity from HealthKit and feeds it to the
//  GameEngine as a "Bio-Boost" — today's Active Energy and Exercise Minutes
//  multiply your in-game cutter & auto-salvage power. Move in the real world,
//  hit harder in the game. This is the kind of functionality only a Watch app
//  can offer, and a strong differentiator for App Review.
//
//  ⚠️ Xcode setup (see README):
//   • Add the **HealthKit** capability to the Watch target.
//   • Add Info.plist key **NSHealthShareUsageDescription** with a sentence like
//     "Salvager uses your activity to power up your rig."
//   • (No write access is requested — read-only.)
//

import Foundation
import HealthKit

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published private(set) var authorized = false
    @Published private(set) var activeEnergy: Double = 0    // kcal today
    @Published private(set) var exerciseMinutes: Double = 0 // minutes today

    private let store = HKHealthStore()
    private weak var engine: GameEngine?

    private var energyType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    }
    private var exerciseType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
    }

    private init() {}

    func attach(engine: GameEngine) { self.engine = engine }

    /// Request read-only authorization (call once on launch).
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        var read = Set<HKObjectType>()
        if let energyType { read.insert(energyType) }
        if let exerciseType { read.insert(exerciseType) }
        store.requestAuthorization(toShare: [], read: read) { [weak self] ok, _ in
            Task { @MainActor in
                self?.authorized = ok
                self?.refresh()
            }
        }
    }

    /// Re-read today's totals and push them into the engine.
    func refresh() {
        sumToday(energyType, unit: .kilocalorie()) { [weak self] value in
            self?.activeEnergy = value
            self?.pushToEngine()
        }
        sumToday(exerciseType, unit: .minute()) { [weak self] value in
            self?.exerciseMinutes = value
            self?.pushToEngine()
        }
    }

    private func pushToEngine() {
        engine?.updateBioMetrics(activeEnergy: activeEnergy, exerciseMinutes: exerciseMinutes)
    }

    /// Cumulative sum of a quantity type since the start of today.
    private func sumToday(_ type: HKQuantityType?, unit: HKUnit,
                          completion: @escaping (Double) -> Void) {
        guard let type else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(),
                                                    options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
            let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
            Task { @MainActor in completion(value) }
        }
        store.execute(query)
    }
}

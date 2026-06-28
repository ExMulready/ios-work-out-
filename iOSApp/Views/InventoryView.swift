//
//  InventoryView.swift
//  Salvager — iOS Companion
//
//  Read-only cargo manifest of everything the player owns and their current
//  run: owned tech, owned gear, and Watch-synced stats (depth, jumps, scrap).
//

import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var model: CompanionModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WalletHeader()
                List {
                    Section("Run") {
                        statRow("Depth", "\(model.state.currentLevel)", "arrow.down.to.line")
                        statRow("Deep Jumps", "\(model.state.prestigeCount)", "arrow.triangle.2.circlepath")
                        statRow("Scrap", model.state.gold.abbreviated, "cube.fill")
                    }

                    Section("Salvaged Tech (\(model.ownedArtifacts.count))") {
                        if model.ownedArtifacts.isEmpty {
                            Text("None yet — visit the Salvage Exchange.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(model.ownedArtifacts) { a in
                                Label(a.name, systemImage: a.symbolName)
                            }
                        }
                    }

                    Section("Gear (\(model.ownedEquipment.count))") {
                        if model.ownedEquipment.isEmpty {
                            Text("None yet — buy Cutters & Plating in the Rig tab.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(model.ownedEquipment) { e in
                                Label(e.name, systemImage: e.symbolName)
                            }
                        }
                    }

                    Section("Achievements (\(unlockedCount)/\(Achievement.catalog.count))") {
                        ForEach(Achievement.catalog) { ach in
                            achievementRow(ach)
                        }
                    }
                }
            }
            .navigationTitle("Cargo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var unlockedCount: Int {
        Achievement.catalog.filter { model.state.unlockedAchievementIDs.contains($0.id) }.count
    }

    private func achievementRow(_ ach: Achievement) -> some View {
        let unlocked = model.state.unlockedAchievementIDs.contains(ach.id)
        return HStack {
            Image(systemName: unlocked ? ach.symbolName : "lock.fill")
                .foregroundStyle(unlocked ? .yellow : .secondary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(ach.name).font(.body)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(ach.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            } else {
                Label("\(ach.coreReward)", systemImage: "atom")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func statRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(value).bold().foregroundStyle(.secondary)
        }
    }
}

#Preview {
    InventoryView()
        .environmentObject(CompanionModel())
        .environmentObject(WatchConnectivityManager.shared)
}

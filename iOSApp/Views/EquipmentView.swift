//
//  EquipmentView.swift
//  Salvager — iOS Companion
//
//  Rig loadout: Cutter (weapon slot) + Plating (armor slot). Two slots at the
//  top show what's equipped; below, the player buys (with Cores) and equips
//  owned gear. Equipping syncs to the Watch immediately.
//

import SwiftUI

struct EquipmentView: View {
    @EnvironmentObject var model: CompanionModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WalletHeader()
                List {
                    Section("Equipped") {
                        slotRow(.weapon)
                        slotRow(.armor)
                    }
                    Section("Cutters") {
                        ForEach(model.equipment.filter { $0.slot == .weapon }) { item in
                            gearRow(item)
                        }
                    }
                    Section("Plating") {
                        ForEach(model.equipment.filter { $0.slot == .armor }) { item in
                            gearRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Rig")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Equipped slots

    private func slotRow(_ slot: EquipmentSlot) -> some View {
        let equipped: Equipment? = slot == .weapon
            ? model.equipment.first { $0.id == model.state.equippedWeaponID }
            : model.equipment.first { $0.id == model.state.equippedArmorID }
        return HStack {
            Image(systemName: slot == .weapon ? "scope" : "shield.fill")
                .foregroundStyle(.secondary)
            Text(slot == .weapon ? "Cutter" : "Plating").bold()
            Spacer()
            if let e = equipped {
                Text(e.name).foregroundStyle(rarityColor(e.rarity))
                Button(role: .destructive) { model.unequip(slot: slot) } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } else {
                Text("Empty").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Gear rows

    private func gearRow(_ item: Equipment) -> some View {
        let owned = model.state.ownedEquipmentIDs.contains(item.id)
        let isEquipped = item.id == model.state.equippedWeaponID || item.id == model.state.equippedArmorID
        let cost = model.crystalCost(for: item)
        let affordable = model.state.crystals >= cost

        return HStack {
            Image(systemName: item.symbolName)
                .foregroundStyle(rarityColor(item.rarity))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.body)
                Text(statText(item))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isEquipped {
                Label("Equipped", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
            } else if owned {
                Button("Equip") { model.equip(item) }
                    .buttonStyle(.bordered)
            } else {
                Button {
                    model.buyEquipment(item)
                } label: {
                    Label("\(cost)", systemImage: "atom")
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(!affordable)
            }
        }
    }

    private func statText(_ item: Equipment) -> String {
        if item.slot == .weapon { return "\(item.rarity.rawValue.capitalized) · +\(Int(item.tapBonus)) cutter" }
        return "\(item.rarity.rawValue.capitalized) · +\(Int(item.dpsBonus)) auto"
    }

    private func rarityColor(_ r: Rarity) -> Color {
        switch r {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

#Preview {
    EquipmentView()
        .environmentObject(CompanionModel())
        .environmentObject(WatchConnectivityManager.shared)
}

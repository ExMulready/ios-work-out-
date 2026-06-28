//
//  RuneView.swift
//  Salvager — watchOS
//
//  Spend scrap to upgrade rig Modules. Each row shows the module, its current
//  level & bonus, and a buy button with the next upgrade cost (disabled if
//  unaffordable).
//

import SwiftUI
import WatchKit

struct RuneView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        List {
            Section {
                HStack {
                    Label(engine.state.gold.abbreviated, systemImage: "cube.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    Label("\(engine.tapDamage.abbreviated)", systemImage: "scope")
                        .foregroundStyle(.red)
                }
                .font(.caption2.bold())
            }

            Section("Modules") {
                ForEach(engine.state.runes) { rune in
                    runeRow(rune)
                }
            }
        }
        .navigationTitle("Modules")
    }

    private func runeRow(_ rune: Rune) -> some View {
        let affordable = engine.state.gold >= rune.nextUpgradeCost
        return Button {
            FeedbackManager.shared.play(engine.upgradeRune(rune.id) ? .upgrade : .fail)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: rune.symbolName)
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 1) {
                    Text(rune.name).font(.caption2.bold())
                    Text("Lv \(rune.level) · \(bonusText(rune))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(affordable ? .yellow : .gray)
                    Text(rune.nextUpgradeCost.abbreviated)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(affordable ? .primary : .secondary)
                }
            }
        }
        .disabled(!affordable)
    }

    private func bonusText(_ rune: Rune) -> String {
        var parts: [String] = []
        if rune.tapBonusPerLevel > 0 { parts.append("+\(rune.totalTapBonus.abbreviated) cut") }
        if rune.dpsBonusPerLevel > 0 { parts.append("+\(rune.totalDpsBonus.abbreviated) auto") }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
    }
}

#Preview {
    NavigationStack { RuneView() }
        .environmentObject(GameEngine(state: GameState(gold: 5000)))
}

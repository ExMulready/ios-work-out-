//
//  SpellsView.swift
//  Salvager — watchOS
//
//  Trigger timed Overclocks using scrap. Each row shows the overclock, its
//  effect, and a button that reflects live status: Ready (with cost), Active
//  (seconds left), or Cooldown (seconds left). A 1-second ticker keeps the
//  countdowns fresh.
//

import SwiftUI
import WatchKit

struct SpellsView: View {
    @EnvironmentObject var engine: GameEngine
    /// Local ticker so the countdowns update every second while on screen.
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            Section {
                HStack {
                    Label(engine.state.gold.abbreviated, systemImage: "cube.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    if engine.hasActiveSpell {
                        Label("Overclocked", systemImage: "gauge.high")
                            .foregroundStyle(.purple)
                    }
                }
                .font(.caption2.bold())
            }

            Section("Overclocks") {
                ForEach(engine.spells) { spell in
                    spellRow(spell)
                }
            }
        }
        .navigationTitle("Overclocks")
        .onReceive(ticker) { now = $0 }
    }

    @ViewBuilder
    private func spellRow(_ spell: Spell) -> some View {
        let status = spell.status(cast: engine.state.spellCastTimes[spell.id],
                                  now: now.timeIntervalSince1970)
        Button {
            FeedbackManager.shared.play(engine.castSpell(spell.id) ? .upgrade : .fail)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: spell.symbolName)
                    .foregroundStyle(status.isActive ? .purple : .blue)
                    .symbolEffect(.pulse, isActive: status.isActive)
                VStack(alignment: .leading, spacing: 1) {
                    Text(spell.name).font(.caption2.bold())
                    Text(effectText(spell))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusLabel(spell, status)
            }
        }
        .disabled(disabled(for: status, spell: spell))
    }

    @ViewBuilder
    private func statusLabel(_ spell: Spell, _ status: SpellStatus) -> some View {
        switch status {
        case .ready:
            VStack(alignment: .trailing, spacing: 1) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(engine.state.gold >= spell.goldCost ? .yellow : .gray)
                Text(spell.goldCost.abbreviated)
                    .font(.system(size: 10, weight: .bold))
            }
        case .active(let remaining):
            Text("\(Int(remaining.rounded()))s")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.purple)
        case .cooldown(let remaining):
            Label("\(Int(remaining.rounded()))s", systemImage: "hourglass")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private func disabled(for status: SpellStatus, spell: Spell) -> Bool {
        if case .ready = status { return engine.state.gold < spell.goldCost }
        return true   // active or on cooldown
    }

    private func effectText(_ spell: Spell) -> String {
        var parts: [String] = []
        if spell.tapMultiplier > 1 { parts.append("×\(fmt(spell.tapMultiplier)) cut") }
        if spell.dpsMultiplier > 1 { parts.append("×\(fmt(spell.dpsMultiplier)) auto") }
        return parts.joined(separator: ", ") + " · \(Int(spell.duration))s"
    }

    private func fmt(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%.1f", d)
    }
}

#Preview {
    NavigationStack { SpellsView() }
        .environmentObject(GameEngine(state: GameState(gold: 1000)))
}

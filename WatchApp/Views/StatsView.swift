//
//  StatsView.swift
//  Salvager — watchOS
//
//  Lifetime stats, Deep Jump (prestige) info, and danger-zone actions (manual
//  Deep Jump once unlocked, and a full progress reset behind a confirmation).
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var engine: GameEngine
    @EnvironmentObject var feedback: FeedbackManager
    @State private var confirmReset = false
    @State private var confirmPrestige = false

    var body: some View {
        List {
            Section("Rig") {
                statRow("Cutter power", engine.tapDamage.abbreviated, "scope")
                statRow("Auto-salvage", engine.dps.abbreviated, "gearshape.2.fill")
                statRow("Jump bonus",
                        "+\(Int((engine.state.prestigeMultiplier - 1) * 100))%",
                        "arrow.up.forward.circle.fill")
                if engine.hasBioBoost {
                    statRow("Bio-Boost",
                            "+\(Int((engine.bioBoostMultiplier - 1) * 100))%",
                            "heart.fill")
                }
            }

            Section {
                NavigationLink {
                    BioBoostView()
                } label: {
                    Label("Bio-Boost (Health)", systemImage: "heart.fill")
                }
            }

            Section("Live Sector") {
                statRow(engine.currentEvent.name,
                        "×\(String(format: "%.2g", engine.currentEvent.scrapMultiplier)) scrap",
                        engine.currentEvent.symbolName)
                statRow("Changes in", engine.secondsUntilEventChange.shortDuration, "clock.fill")
            }

            Section("Lifetime") {
                statRow("Scrap salvaged", engine.state.lifetimeGoldEarned.abbreviated, "cube.fill")
                statRow("Hazards cleared", "\(engine.state.lifetimeMonstersDefeated)", "bolt.shield.fill")
                statRow("Caches cracked", "\(engine.state.lifetimeCachesCollected)", "shippingbox.fill")
                statRow("Cutter strikes", "\(engine.state.lifetimeTaps)", "hand.point.up.left.fill")
                statRow("Deep Jumps", "\(engine.state.prestigeCount)", "arrow.triangle.2.circlepath")
            }

            Section {
                NavigationLink {
                    AchievementsView()
                } label: {
                    Label("Achievements", systemImage: "trophy.fill")
                }
            }

            Section("Settings") {
                Toggle(isOn: $feedback.hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap.fill")
                }
                Toggle(isOn: $feedback.soundEnabled) {
                    Label("Sound", systemImage: "speaker.wave.2.fill")
                }
            }

            Section("Deep Jump") {
                if engine.canPrestige {
                    Button {
                        confirmPrestige = true
                    } label: {
                        Label("Initiate Deep Jump", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .tint(.purple)
                } else {
                    Label("Unlocks at Depth 100", systemImage: "lock.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset all progress", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Stats")
        .alert("Initiate Deep Jump?", isPresented: $confirmPrestige) {
            Button("Jump", role: .destructive) { engine.prestige() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Drift to a fresh derelict at Depth 1, keep tech & gear, gain +10% permanent power.")
        }
        .alert("Reset everything?", isPresented: $confirmReset) {
            Button("Erase", role: .destructive) { engine.resetAllProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This wipes ALL progress, including artifacts. This cannot be undone.")
        }
    }

    private func statRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(.caption2)
            Spacer()
            Text(value).font(.caption2.bold()).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack { StatsView() }
        .environmentObject(GameEngine(state: GameState(currentLevel: 100, gold: 5000,
                                                       lifetimeGoldEarned: 123456,
                                                       lifetimeMonstersDefeated: 980,
                                                       lifetimeTaps: 4200)))
        .environmentObject(FeedbackManager.shared)
        .environmentObject(HealthManager.shared)
}

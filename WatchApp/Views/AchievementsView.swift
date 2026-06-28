//
//  AchievementsView.swift
//  Salvager — watchOS
//
//  Lists every achievement with its unlock state and Core reward. Unlocked
//  ones are highlighted; locked ones show the requirement.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var engine: GameEngine

    private var unlockedCount: Int {
        engine.achievements.filter { engine.isUnlocked($0) }.count
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("\(unlockedCount)/\(engine.achievements.count)", systemImage: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                }
                .font(.caption2.bold())
            }

            ForEach(engine.achievements) { ach in
                row(ach)
            }
        }
        .navigationTitle("Achievements")
    }

    private func row(_ ach: Achievement) -> some View {
        let unlocked = engine.isUnlocked(ach)
        return HStack(spacing: 8) {
            Image(systemName: unlocked ? ach.symbolName : "lock.fill")
                .foregroundStyle(unlocked ? .yellow : .secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(ach.name)
                    .font(.caption2.bold())
                    .foregroundStyle(unlocked ? .primary : .secondary)
                Text(ach.detail)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 2) {
                Text("+\(ach.coreReward)")
                Image(systemName: "atom")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(unlocked ? .green : .secondary.opacity(0.6))
        }
        .opacity(unlocked ? 1 : 0.7)
    }
}

#Preview {
    NavigationStack { AchievementsView() }
        .environmentObject(GameEngine(state: GameState(currentLevel: 30, prestigeCount: 1,
                                                       lifetimeGoldEarned: 1_200_000,
                                                       lifetimeMonstersDefeated: 240,
                                                       unlockedAchievementIDs: ["ach.depth5", "ach.depth25", "ach.jump1"])))
}

//
//  BattleView.swift
//  Salvager — watchOS
//
//  The main salvage screen: hazard + HP bar, big CUTTER button, scrap/auto
//  readout, depth indicator, the live World Event banner, and navigation to
//  Modules / Overclocks / Stats.
//

import SwiftUI
import WatchKit

struct BattleView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var showPrestigePrompt = false
    @State private var showBossIntro = false
    @State private var showDailyReward = false
    @State private var dailyRewardAmount = 0
    /// Depth the Sentinel intro was last shown for, so it only appears once per
    /// encounter (not every time we navigate back to this screen).
    @State private var bossIntroShownForLevel = 0
    @State private var tapScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 5) {
            header
            eventBanner

            Spacer(minLength: 2)

            monster

            Spacer(minLength: 2)

            attackButton

            stats
        }
        .padding(.horizontal, 4)
        .overlay(alignment: .top) { achievementToast }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink {
                    SpellsView()
                } label: {
                    Image(systemName: "gauge.high")     // Overclocks
                }
                NavigationLink {
                    RuneView()
                } label: {
                    Image(systemName: "cpu")            // Modules
                }
                NavigationLink {
                    StatsView()
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
        // Sentinel intro when a boss depth begins.
        .fullScreenCover(isPresented: $showBossIntro) {
            BossView(monster: engine.currentMonster,
                     level: engine.state.currentLevel) {
                showBossIntro = false
            }
        }
        // "Welcome back" offline scrap.
        .alert("Welcome back!", isPresented: offlineBinding) {
            Button("Collect") { engine.offlineEarnings = nil }
        } message: {
            if let g = engine.offlineEarnings {
                Text("Your drones salvaged \(g.abbreviated) scrap while you were away.")
            }
        }
        // Daily Salvage Bonus (first launch each day).
        .alert("Daily Salvage Bonus", isPresented: $showDailyReward) {
            Button("Collect \(dailyRewardAmount) Cores") {}
        } message: {
            Text("Day \(engine.state.dailyStreak) streak! Come back tomorrow to keep it going.")
        }
        // Deep Jump (prestige) prompt once deep enough.
        .alert("Initiate Deep Jump?", isPresented: $showPrestigePrompt) {
            Button("Jump", role: .destructive) { engine.prestige() }
            Button("Not yet", role: .cancel) {}
        } message: {
            Text("Drift to a fresh derelict at Depth 1, keep your tech, and gain +10% permanent power.")
        }
        .onChange(of: engine.canPrestige) { _, can in
            if can { showPrestigePrompt = true }
        }
        .onChange(of: engine.state.currentLevel) { _, level in
            FeedbackManager.shared.play(level % 5 == 0 ? .boss : .levelUp)
            presentBossIntroIfNeeded(level: level)
        }
        .onAppear {
            presentBossIntroIfNeeded(level: engine.state.currentLevel)
            claimDailyRewardIfAvailable()
        }
    }

    /// Grant the once-per-day bonus and show a prompt (skips while onboarding).
    private func claimDailyRewardIfAvailable() {
        guard engine.isDailyRewardAvailable else { return }
        let amount = engine.claimDailyReward()
        guard amount > 0 else { return }
        dailyRewardAmount = amount
        showDailyReward = true
        FeedbackManager.shared.play(.achievement)
    }

    // MARK: Subviews

    private var header: some View {
        HStack {
            Label("Depth \(engine.state.currentLevel)", systemImage: "arrow.down.to.line")
                .font(.caption2.bold())
            if engine.hasActiveSpell {
                Image(systemName: "gauge.high")
                    .font(.caption2)
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse)
            }
            if engine.hasBioBoost {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
            }
            Spacer()
            if engine.state.isBossLevel, let t = engine.bossTimeRemaining {
                Label("\(t)s", systemImage: "timer")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }
        }
        .foregroundStyle(.secondary)
    }

    /// Transient banner shown when an achievement unlocks. Auto-dismisses and
    /// then shows the next queued one, if any.
    @ViewBuilder
    private var achievementToast: some View {
        if let ach = engine.recentlyUnlocked.first {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 0) {
                    Text(ach.name).font(.system(size: 11, weight: .bold))
                    Text("+\(ach.coreReward) Cores").font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.yellow.opacity(0.6), lineWidth: 1))
            .transition(.move(edge: .top).combined(with: .opacity))
            .id(ach.id)
            .task(id: ach.id) {
                FeedbackManager.shared.play(.achievement)
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation { engine.popRecentlyUnlocked() }
            }
        }
    }

    /// Live World Event chip — the signature, clock-driven mechanic.
    /// Anomalies get a louder, pulsing treatment.
    private var eventBanner: some View {
        let e = engine.currentEvent
        return HStack(spacing: 4) {
            Image(systemName: e.symbolName)
                .symbolEffect(.pulse, isActive: e.isAnomaly)
            Text(e.isAnomaly ? e.name.uppercased() : e.name)
                .lineLimit(1)
            if e.scrapMultiplier > 1 {
                Text("×\(fmt(e.scrapMultiplier))")
                    .fontWeight(.heavy)
            }
        }
        .font(.system(size: 10, weight: e.isAnomaly ? .heavy : .semibold))
        .foregroundStyle(e.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(e.color.opacity(e.isAnomaly ? 0.28 : 0.15), in: Capsule())
        .overlay(
            Capsule().stroke(e.color, lineWidth: e.isAnomaly ? 1 : 0)
        )
    }

    private var monster: some View {
        VStack(spacing: 4) {
            Image(systemName: engine.currentMonster.symbolName)
                .resizable()
                .scaledToFit()
                .frame(height: engine.currentMonster.isBoss ? 46 : 38)
                .foregroundStyle(monsterColor)
                .symbolEffect(.bounce, value: engine.currentMonster.hp)

            Text(engine.currentMonster.name)
                .font(.caption2)
                .foregroundStyle(engine.currentMonster.isRare ? .cyan : .primary)
                .lineLimit(1)

            // HP bar
            ProgressView(value: engine.currentMonster.healthFraction)
                .tint(.red)
                .frame(height: 4)
        }
    }

    private var monsterColor: Color {
        if engine.currentMonster.isRare { return .cyan }
        return engine.currentMonster.isBoss ? .orange : .green
    }

    private var attackButton: some View {
        Button {
            engine.tapAttack()
            FeedbackManager.shared.play(.tap)
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { tapScale = 0.9 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { tapScale = 1.0 }
            }
        } label: {
            Image(systemName: "scope")
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .scaleEffect(tapScale)
    }

    private var stats: some View {
        HStack {
            Label(engine.state.gold.abbreviated, systemImage: "cube.fill")
                .foregroundStyle(.yellow)
            Spacer()
            Label("\(engine.dps.abbreviated)/s", systemImage: "gearshape.2.fill")
                .foregroundStyle(.blue)
        }
        .font(.caption2.bold())
    }

    /// Show the Sentinel intro once per boss depth (skip the prestige overlap).
    private func presentBossIntroIfNeeded(level: Int) {
        guard level % 5 == 0, level != bossIntroShownForLevel else { return }
        bossIntroShownForLevel = level
        showBossIntro = true
    }

    private func fmt(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%.2g", d)
    }

    private var offlineBinding: Binding<Bool> {
        Binding(
            get: { engine.offlineEarnings != nil },
            set: { if !$0 { engine.offlineEarnings = nil } }
        )
    }
}

#Preview {
    NavigationStack { BattleView() }
        .environmentObject(GameEngine(state: GameState(currentLevel: 5, gold: 1234)))
}

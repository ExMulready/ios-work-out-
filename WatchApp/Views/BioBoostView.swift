//
//  BioBoostView.swift
//  Salvager — watchOS
//
//  Explains the HealthKit Bio-Boost: how today's real-world activity is
//  powering the rig, and how to push it higher. Reads live values from the
//  HealthManager and the resulting multiplier from the engine.
//

import SwiftUI

struct BioBoostView: View {
    @EnvironmentObject var engine: GameEngine
    @EnvironmentObject var health: HealthManager

    private var bonusPercent: Int {
        Int(((engine.bioBoostMultiplier - 1) * 100).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.pink)
                    .symbolEffect(.pulse, isActive: engine.hasBioBoost)

                Text("+\(bonusPercent)% Power")
                    .font(.title3.bold())
                    .foregroundStyle(engine.hasBioBoost ? .pink : .secondary)
                Text("Bio-Boost")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !health.authorized {
                    Text("Allow Health access so your workouts can power your rig.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Enable Health") { health.requestAuthorization() }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                } else {
                    metric("Active energy", "\(Int(health.activeEnergy)) kcal", "flame.fill", .orange)
                    metric("Exercise", "\(Int(health.exerciseMinutes)) min", "figure.run", .green)

                    Text("Resets daily. 1000 kcal or 120 exercise min reaches the +100% cap.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)

                    Button {
                        health.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Bio-Boost")
        .onAppear { health.refresh() }
    }

    private func metric(_ title: String, _ value: String, _ symbol: String, _ color: Color) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .foregroundStyle(color)
            Spacer()
            Text(value).bold()
        }
        .font(.caption2)
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack { BioBoostView() }
        .environmentObject(GameEngine())
        .environmentObject(HealthManager.shared)
}

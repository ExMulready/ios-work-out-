//
//  BossView.swift
//  Salvager — watchOS
//
//  Dramatic full-screen intro shown when the player reaches a Sentinel (boss)
//  depth. Presented as a fullScreenCover from BattleView; tapping "Engage"
//  dismisses it and the normal fight begins with the Sentinel timer running.
//

import SwiftUI

struct BossView: View {
    let monster: Monster
    let level: Int
    let onBegin: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 10) {
            Text("SENTINEL")
                .font(.caption.bold())
                .tracking(3)
                .foregroundStyle(.orange)

            Image(systemName: monster.symbolName)
                .resizable()
                .scaledToFit()
                .frame(height: 56)
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.8), radius: pulse ? 12 : 4)
                .scaleEffect(pulse ? 1.08 : 0.96)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

            Text(monster.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Depth \(level) · Beat the timer!")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button {
                onBegin()
            } label: {
                Label("Engage", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(
            RadialGradient(colors: [.orange.opacity(0.25), .black],
                           center: .center, startRadius: 10, endRadius: 120)
            .ignoresSafeArea()
        )
        .onAppear { pulse = true }
    }
}

#Preview {
    BossView(monster: Bestiary.monster(forLevel: 5), level: 5, onBegin: {})
}

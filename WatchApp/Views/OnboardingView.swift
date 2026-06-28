//
//  OnboardingView.swift
//  Salvager — watchOS
//
//  First-launch, swipeable intro that teaches the core loop and — crucially —
//  the World Events rhythm (the reason to keep coming back). Presented as a
//  fullScreenCover from ContentView until the player taps "Start Salvaging".
//

import SwiftUI

struct OnboardingView: View {
    /// Called when the player finishes onboarding.
    let onFinish: () -> Void

    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let color: Color
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "scope", color: .red,
             title: "Strip the Derelict",
             body: "Tap the CUTTER to crack hazards and bank scrap."),
        Page(symbol: "gearshape.2.fill", color: .blue,
             title: "Drones Never Sleep",
             body: "Your rig keeps auto-salvaging while you're away. Collect on return."),
        Page(symbol: "bolt.fill", color: .yellow,
             title: "The Sector Is Alive",
             body: "Live events change by the hour — Ion Storms, Pirate Raids, rare Anomalies. Come back when payouts spike!"),
        Page(symbol: "shield.lefthalf.filled", color: .orange,
             title: "Go Deep",
             body: "A Sentinel guards every 5th depth. At Depth 100, Deep Jump to grow permanently stronger.")
    ]

    var body: some View {
        TabView(selection: $page) {
            ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                pageView(p, isLast: idx == pages.count - 1)
                    .tag(idx)
            }
        }
        .tabViewStyle(.verticalPage)
    }

    private func pageView(_ p: Page, isLast: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: p.symbol)
                .font(.system(size: 34))
                .foregroundStyle(p.color)
            Text(p.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if isLast {
                Button {
                    onFinish()
                } label: {
                    Label("Start Salvaging", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 4)
            } else {
                Image(systemName: "chevron.compact.down")
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 6)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}

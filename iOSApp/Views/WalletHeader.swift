//
//  WalletHeader.swift
//  Salvager — iOS Companion
//
//  Reusable header showing the player's wallet (Cores + Scrap), the live World
//  Event, and the Watch-link status. Reused across the Exchange/Rig/Store
//  screens. A ticker keeps the event fresh while the phone app is open.
//

import SwiftUI

struct WalletHeader: View {
    @EnvironmentObject var model: CompanionModel
    @EnvironmentObject var connectivity: WatchConnectivityManager

    @State private var event = WorldEventScheduler.event()
    @State private var changesIn = WorldEventScheduler.secondsUntilNextChange()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Label("\(model.state.crystals)", systemImage: "atom")
                    .foregroundStyle(.cyan)
                Label(model.state.gold.abbreviated, systemImage: "cube.fill")
                    .foregroundStyle(.yellow)
                Spacer()
                Image(systemName: connectivity.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                    .foregroundStyle(connectivity.isReachable ? .green : .secondary)
            }
            .font(.subheadline.bold())
            .padding(.horizontal)
            .padding(.vertical, 8)

            eventStrip
        }
        .background(.ultraThinMaterial)
        .onReceive(ticker) { _ in
            event = WorldEventScheduler.event()
            changesIn = WorldEventScheduler.secondsUntilNextChange()
        }
    }

    /// Live World Event strip — drives the "come back at the right time" loop.
    /// Anomalies get a bold badge + tinted background.
    private var eventStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: event.symbolName)
                .symbolEffect(.pulse, isActive: event.isAnomaly)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(event.name).font(.caption.bold())
                    if event.isAnomaly {
                        Text("ANOMALY")
                            .font(.system(size: 8, weight: .heavy))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(event.color, in: Capsule())
                            .foregroundStyle(.black)
                    }
                }
                Text(event.blurb).font(.caption2).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                if event.scrapMultiplier > 1 {
                    Text("×\(String(format: "%.2g", event.scrapMultiplier)) scrap")
                        .font(.caption2.bold())
                }
                Text("ends in \(changesIn.shortDuration)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(event.color)
        .padding(.horizontal)
        .padding(.vertical, event.isAnomaly ? 6 : 0)
        .padding(.bottom, 8)
        .background(event.isAnomaly ? event.color.opacity(0.12) : .clear)
    }
}

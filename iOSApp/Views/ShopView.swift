//
//  ShopView.swift
//  Salvager — iOS Companion
//
//  The Salvage Exchange: spend Cores on permanent Salvaged Tech that multiplies
//  cutter (tap) and auto-salvage (DPS) power. Tech featured by the live World
//  Event is discounted 25% — a reason to check back as events rotate.
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject var model: CompanionModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WalletHeader()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(model.artifacts) { artifact in
                            ArtifactCard(artifact: artifact)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Salvage Exchange")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ArtifactCard: View {
    @EnvironmentObject var model: CompanionModel
    let artifact: Artifact

    private var owned: Bool { model.state.ownedArtifactIDs.contains(artifact.id) }
    private var featured: Bool { model.isFeatured(artifact) }
    private var cost: Int { model.effectiveCost(for: artifact) }
    private var affordable: Bool { model.state.crystals >= cost }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: artifact.symbolName)
                .font(.system(size: 36))
                .foregroundStyle(.purple)
                .frame(height: 44)

            Text(artifact.name).font(.headline)
            Text(artifact.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if featured && !owned {
                Text("EVENT DEAL · 25% OFF")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.cyan)
            }

            if owned {
                Label("Owned", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            } else {
                Button {
                    model.buyArtifact(artifact)
                } label: {
                    Label("\(cost)", systemImage: "atom")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(!affordable)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.cyan, lineWidth: featured && !owned ? 1.5 : 0)
        )
    }
}

#Preview {
    ShopView()
        .environmentObject(CompanionModel())
        .environmentObject(WatchConnectivityManager.shared)
}

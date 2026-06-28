//
//  StoreView.swift
//  Salvager — iOS Companion
//
//  Real-money In-App Purchases (StoreKit 2). Buy Core packs that credit the
//  in-game Core wallet spent in the Salvage Exchange.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var model: CompanionModel
    @EnvironmentObject var store: StoreKitManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WalletHeader()
                List {
                    Section {
                        if store.products.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Loading store…").foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(store.products, id: \.id) { product in
                                productRow(product)
                            }
                        }
                    } header: {
                        Text("Core Packs")
                    } footer: {
                        Text("Cores are spent in the Salvage Exchange on tech and gear.")
                    }

                    Section {
                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                    }
                }
            }
            .navigationTitle("Get Cores")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Store", isPresented: errorBinding) {
                Button("OK") { store.lastError = nil }
            } message: {
                Text(store.lastError ?? "")
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let cores = CrystalPack.crystals(forProductID: product.id)
        let busy = store.purchaseInProgress == product.id
        return HStack {
            Image(systemName: "atom").foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline)
                Text("\(cores) cores").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await store.purchase(product) }
            } label: {
                if busy { ProgressView() } else { Text(product.displayPrice).bold() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(busy)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } })
    }
}

#Preview {
    StoreView()
        .environmentObject(CompanionModel())
        .environmentObject(StoreKitManager())
        .environmentObject(WatchConnectivityManager.shared)
}

//
//  RuneClickerCompanionApp.swift  (Salvager — iOS companion app entry)
//
//  NOTE: file/struct names keep the "RuneClicker" prefix for internal
//  stability; the shipping product is "Salvager" (set via CFBundleDisplayName).
//  Wires up the shared model, WatchConnectivity, and StoreKit, then presents
//  the tabbed companion UI (Exchange / Rig / Cargo / Cores).
//

import SwiftUI

@main
struct RuneClicker_Companion_App: App {
    @StateObject private var model = CompanionModel()
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @StateObject private var store = StoreKitManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(model)
                .environmentObject(connectivity)
                .environmentObject(store)
                .onAppear {
                    connectivity.attach(model: model)
                    store.attach(model: model)
                    store.start()
                }
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject var model: CompanionModel

    var body: some View {
        TabView {
            ShopView()
                .tabItem { Label("Exchange", systemImage: "bag.fill") }
            EquipmentView()
                .tabItem { Label("Rig", systemImage: "shield.lefthalf.filled") }
            InventoryView()
                .tabItem { Label("Cargo", systemImage: "square.grid.2x2.fill") }
            StoreView()
                .tabItem { Label("Cores", systemImage: "atom") }
        }
    }
}

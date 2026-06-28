//
//  RuneClickerApp.swift  (Salvager — watchOS app entry)
//
//  NOTE: file/struct names keep the "RuneClicker" prefix for internal
//  stability; the shipping product is "Salvager" (set via CFBundleDisplayName).
//  Owns the single GameEngine instance and wires up scene-phase handling for
//  the idle loop, extended runtime sessions, and idle reminders.
//

import SwiftUI

@main
struct RuneClicker_Watch_App: App {
    @StateObject private var engine = GameEngine()
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @StateObject private var health = HealthManager.shared
    @StateObject private var feedback = FeedbackManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(connectivity)
                .environmentObject(health)
                .environmentObject(feedback)
                .onAppear {
                    connectivity.attach(engine: engine)
                    health.attach(engine: engine)
                    NotificationManager.shared.requestAuthorization()
                    health.requestAuthorization()
                    engine.start()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                engine.start()
                health.refresh()           // re-read today's activity
                NotificationManager.shared.cancelIdleReminder()
            case .background, .inactive:
                engine.stop()              // persists state
                connectivity.pushState(engine.state)
                NotificationManager.shared.scheduleIdleReminder()
            @unknown default:
                break
            }
        }
    }
}

/// Top-level tab/navigation container for the Watch.
struct ContentView: View {
    @EnvironmentObject var engine: GameEngine
    @AppStorage("salvager.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        NavigationStack {
            BattleView()
        }
        .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
            OnboardingView { hasOnboarded = true }
        }
    }
}

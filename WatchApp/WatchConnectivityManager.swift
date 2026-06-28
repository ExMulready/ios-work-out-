//
//  WatchConnectivityManager.swift
//  RuneClicker — watchOS
//
//  Bridges the Watch game and the iPhone companion app. The Watch is the
//  authority on gameplay progress (level/gold/runes); the Phone is the
//  authority on the wallet & inventory (crystals/artifacts/equipment).
//  We exchange the full GameState and let GameEngine.mergeFromCompanion()
//  pick the right fields from each side.
//

import Foundation
import WatchConnectivity

@MainActor
public final class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()

    @Published public private(set) var isReachable = false

    private weak var engine: GameEngine?
    private let session: WCSession = .default

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    /// Connect the live engine so incoming phone updates can be merged.
    public func attach(engine: GameEngine) {
        self.engine = engine
    }

    /// Push the latest state to the phone (best-effort).
    public func pushState(_ state: GameState) {
        guard session.activationState == .activated else { return }
        guard let dict = state.asDictionary else { return }
        // applicationContext = latest-wins, survives app-not-running.
        try? session.updateApplicationContext(dict)
        // If reachable, also send live so the phone UI updates instantly.
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil, errorHandler: nil)
        }
    }

    private func handleIncoming(_ dict: [String: Any]) {
        guard let incoming = GameState(dictionary: dict) else { return }
        engine?.mergeFromCompanion(incoming)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    public nonisolated func session(_ session: WCSession,
                                    activationDidCompleteWith activationState: WCSessionActivationState,
                                    error: Error?) {
        Task { @MainActor in self.isReachable = session.isReachable }
    }

    public nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.isReachable = session.isReachable }
    }

    public nonisolated func session(_ session: WCSession,
                                    didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.handleIncoming(message) }
    }

    public nonisolated func session(_ session: WCSession,
                                    didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.handleIncoming(applicationContext) }
    }
}

// GameState <-> dictionary transport helpers now live in Shared
// (GameState+Transport.swift) so both the Watch and iPhone use the same code.

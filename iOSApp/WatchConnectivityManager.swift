//
//  WatchConnectivityManager.swift
//  RuneClicker — iOS Companion
//
//  Phone side of the WatchConnectivity link. Mirrors the Watch manager:
//  receives gameplay progress from the Watch and pushes wallet/inventory
//  changes back.
//

import Foundation
import WatchConnectivity

@MainActor
public final class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()

    @Published public private(set) var isReachable = false

    private weak var model: CompanionModel?
    private let session: WCSession = .default

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    public func attach(model: CompanionModel) {
        self.model = model
    }

    public func pushState(_ state: GameState) {
        guard session.activationState == .activated else { return }
        guard let dict = state.asDictionary else { return }
        try? session.updateApplicationContext(dict)
        if session.isReachable {
            session.sendMessage(dict, replyHandler: nil, errorHandler: nil)
        }
    }

    private func handleIncoming(_ dict: [String: Any]) {
        guard let incoming = GameState(dictionary: dict) else { return }
        model?.mergeFromWatch(incoming)
    }
}

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

    // Required no-op stubs on iOS.
    public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    public nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for the new Watch if the user switches devices.
        WCSession.default.activate()
    }
}

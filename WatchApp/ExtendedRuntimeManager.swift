//
//  ExtendedRuntimeManager.swift
//  RuneClicker — watchOS
//
//  Keeps the idle loop alive for a short while after the wrist lowers using a
//  WKExtendedRuntimeSession. watchOS does NOT allow indefinite background
//  execution — sessions are time-limited — so the real "while you were away"
//  gold is reconciled by GameEngine.applyOfflineEarnings() on next launch.
//  This session just smooths the transition and lets a boss timer finish.
//

import Foundation
import WatchKit

@MainActor
final class ExtendedRuntimeManager: NSObject, ObservableObject {
    private var session: WKExtendedRuntimeSession?

    func begin() {
        guard session?.state != .running else { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        session = s
    }

    func end() {
        session?.invalidate()
        session = nil
    }
}

extension ExtendedRuntimeManager: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        // The system is about to reclaim time — persistence already happened on
        // each tick, so there's nothing extra to flush here.
    }

    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        self.session = nil
    }
}

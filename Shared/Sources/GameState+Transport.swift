//
//  GameState+Transport.swift
//  Salvager — Shared
//
//  Encodes/decodes GameState as a plain [String: Any] dictionary for sending
//  across the WatchConnectivity link. Lives in Shared so BOTH the Watch and the
//  iPhone connectivity managers can use it.
//

import Foundation

public extension GameState {
    /// JSON-dictionary representation suitable for WCSession transport.
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return obj
    }

    /// Rebuild a GameState from a WCSession-delivered dictionary.
    init?(dictionary: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let decoded = try? JSONDecoder().decode(GameState.self, from: data)
        else { return nil }
        self = decoded
    }
}

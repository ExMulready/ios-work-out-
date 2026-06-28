//
//  SharedStore.swift
//  Salvager — Shared
//
//  Single persistence gateway used by the Watch app, the iPhone app, AND the
//  watch-face complication. Backed by an **App Group** container so all three
//  read/write the same save file. Also mirrors to iCloud KV store for
//  cross-device continuity and reloads any widget timelines after a save.
//
//  ⚠️ Xcode setup: add the App Group capability `group.com.salvager.shared`
//  to every target (iOS app, Watch app, Widget extension). See README.
//

import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

public enum SharedStore {

    /// Must match the App Group ID configured in every target's entitlements.
    public static let appGroupID = "group.com.salvager.shared"

    private static let saveKey = "Salvager.GameState"

    /// Shared defaults if the App Group is configured, else falls back to
    /// standard defaults (so the code still runs before you set up the group).
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: Save / Load

    public static func save(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: saveKey)
        NSUbiquitousKeyValueStore.default.set(data, forKey: saveKey)
        reloadWidgets()
    }

    public static func load() -> GameState {
        if let data = defaults.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            return decoded
        }
        // One-time migration from pre-App-Group standard defaults.
        if let legacy = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: legacy) {
            save(decoded)
            return decoded
        }
        return GameState()
    }

    // MARK: Widgets

    public static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

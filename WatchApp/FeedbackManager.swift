//
//  FeedbackManager.swift
//  Salvager — watchOS
//
//  Centralizes all game feedback: WatchKit **haptics** (always available) plus
//  optional **sound effects** played from bundled audio files. Both are
//  user-toggleable in Settings (persisted in UserDefaults). Call
//  `FeedbackManager.shared.play(.kill)` etc. instead of poking WKInterfaceDevice
//  directly, so the toggles are respected everywhere.
//
//  Sound assets are optional: drop short .wav files named to match `soundFile`
//  below into the Watch target's bundle (tap.wav, kill.wav, levelup.wav,
//  upgrade.wav, achievement.wav, boss.wav, fail.wav). If a file is missing the
//  sound simply no-ops and the haptic still fires.
//

import Foundation
import WatchKit
import AVFoundation

@MainActor
final class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()

    enum Event {
        case tap, kill, levelUp, upgrade, fail, achievement, boss
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.sound)
            if soundEnabled { activateAudioSession() }
        }
    }

    private let defaults = UserDefaults.standard
    private enum Keys { static let haptics = "salvager.haptics"; static let sound = "salvager.sound" }

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // Default haptics ON, sound OFF (sound is opt-in and needs assets).
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? false
    }

    // MARK: Public

    func play(_ event: Event) {
        if hapticsEnabled { WKInterfaceDevice.current().play(haptic(for: event)) }
        if soundEnabled { playSound(named: soundFile(for: event)) }
    }

    // MARK: Mapping

    private func haptic(for event: Event) -> WKHapticType {
        switch event {
        case .tap:         return .click
        case .kill:        return .directionUp
        case .levelUp:     return .notification
        case .upgrade:     return .success
        case .fail:        return .failure
        case .achievement: return .success
        case .boss:        return .start
        }
    }

    private func soundFile(for event: Event) -> String {
        switch event {
        case .tap:         return "tap"
        case .kill:        return "kill"
        case .levelUp:     return "levelup"
        case .upgrade:     return "upgrade"
        case .fail:        return "fail"
        case .achievement: return "achievement"
        case .boss:        return "boss"
        }
    }

    // MARK: Sound playback

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func playSound(named name: String) {
        if let player = players[name] {
            player.currentTime = 0
            player.play()
            return
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return   // asset not bundled — silently skip
        }
        player.prepareToPlay()
        players[name] = player
        player.play()
    }
}

//
//  WorldEvent+UI.swift
//  Salvager — Shared
//
//  Tiny SwiftUI bridge so both the Watch and Phone can render a WorldEvent's
//  accent color and a short "time remaining" string consistently.
//

import SwiftUI

public extension WorldEvent {
    /// Accent color resolved from `colorName`.
    var color: Color {
        switch colorName {
        case "yellow": return .yellow
        case "red":    return .red
        case "cyan":   return .cyan
        case "purple": return .purple
        case "blue":   return .blue
        case "orange": return .orange
        case "green":  return .green
        default:       return .gray
        }
    }
}

public extension TimeInterval {
    /// Compact "2h 5m" / "12m" / "45s" formatting for countdowns.
    var shortDuration: String {
        let total = Int(self)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
    }
}

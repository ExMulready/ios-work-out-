//
//  RuneClickerWidget.swift
//  Salvager — Watch Complication / Widget
//
//  A WidgetKit complication for the watch face. Reads the shared GameState
//  (via SharedStore's App Group) and shows the player's depth, scrap, and the
//  live World Event at a glance — reinforcing the "check back when the event
//  changes" loop that defines the game.
//
//  Supported families: accessoryCircular, accessoryInline, accessoryRectangular,
//  accessoryCorner. Add `Shared/Sources/*.swift` to this target so SharedStore,
//  the models, and WorldEvents are available here too.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct RuneEntry: TimelineEntry {
    let date: Date
    let level: Int
    let gold: Double
    let isBoss: Bool
    let eventName: String
    let eventSymbol: String

    static let placeholder = RuneEntry(date: .now, level: 12, gold: 48_200, isBoss: false,
                                       eventName: "Ion Storm", eventSymbol: "bolt.fill")
}

// MARK: - Provider

struct RuneProvider: TimelineProvider {
    func placeholder(in context: Context) -> RuneEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (RuneEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RuneEntry>) -> Void) {
        // Refresh when the World Event next changes (or 15 min, whichever first).
        let entry = currentEntry()
        let eventChange = Date().addingTimeInterval(WorldEventScheduler.secondsUntilNextChange())
        let fallback = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(min(eventChange, fallback))))
    }

    private func currentEntry() -> RuneEntry {
        let s = SharedStore.load()
        let e = WorldEventScheduler.event()
        return RuneEntry(date: .now, level: s.currentLevel, gold: s.gold,
                         isBoss: s.isBossLevel, eventName: e.name, eventSymbol: e.symbolName)
    }
}

// MARK: - Views per family

struct RuneClickerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RuneEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("D\(entry.level) · \(entry.gold.abbreviated) scrap", systemImage: entry.eventSymbol)

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: entry.isBoss ? "shield.lefthalf.filled" : entry.eventSymbol)
                        .font(.caption)
                    Text("\(entry.level)").font(.headline.bold())
                }
            }

        case .accessoryCorner:
            Image(systemName: entry.eventSymbol)
                .font(.title2)
                .widgetLabel("D\(entry.level) · \(entry.gold.abbreviated) scrap")

        case .accessoryRectangular:
            HStack {
                Image(systemName: entry.isBoss ? "shield.lefthalf.filled" : entry.eventSymbol)
                    .font(.title2)
                    .foregroundStyle(entry.isBoss ? .orange : .cyan)
                VStack(alignment: .leading) {
                    Text("Salvager").font(.headline)
                    Text("Depth \(entry.level)\(entry.isBoss ? " · Sentinel!" : "")")
                        .font(.caption)
                    Text("\(entry.eventName) · \(entry.gold.abbreviated) scrap")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }

        default:
            Text("Depth \(entry.level)")
        }
    }
}

// MARK: - Widget

@main
struct RuneClickerWidget: Widget {
    let kind = "SalvagerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RuneProvider()) { entry in
            RuneClickerWidgetView(entry: entry)
        }
        .configurationDisplayName("Salvager")
        .description("Your depth, scrap, and the live sector event at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    RuneClickerWidget()
} timeline: {
    RuneEntry.placeholder
    RuneEntry(date: .now, level: 25, gold: 1_250_000, isBoss: true,
              eventName: "Pirate Raid", eventSymbol: "shippingbox.and.arrow.backward.fill")
}

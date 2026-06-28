//
//  NotificationManager.swift
//  RuneClicker — watchOS
//
//  Schedules a gentle "come back" local notification so idle gold doesn't sit
//  uncollected forever. We schedule one when the app backgrounds and cancel it
//  when the app returns to the foreground. No server, no remote push.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let reminderID = "RuneClicker.idleReminder"
    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Ask once for permission (call on first launch).
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Schedule a reminder a few hours out (called when the app backgrounds).
    func scheduleIdleReminder(afterHours hours: Double = 4) {
        cancelIdleReminder()

        let content = UNMutableNotificationContent()
        content.title = "Your drones are salvaging"
        content.body = "Scrap is piling up — return to collect and upgrade your rig!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, hours * 3600), repeats: false
        )
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// Cancel the pending reminder (called when the app foregrounds).
    func cancelIdleReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}

//
//  LocalNotificationManager.swift
//  iTrainer
//
//  Created by Codex on 07.07.2026.
//

import Foundation
import UserNotifications

enum LocalNotificationPermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied
}

final class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()
    
    private enum NotificationID {
        static let restFinished = "rest-timer-finished"
        static let activeWorkoutReminder = "active-workout-reminder"
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let activeWorkoutReminderDelay: TimeInterval = 30 * 60
    private var hasRequestedAuthorization = false
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorizationIfNeeded() {
        guard AppSettings.shared.notificationsEnabled else { return }
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self?.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                if let error {
                    print("Local notification authorization error: \(error)")
                }
            }
        }
    }
    
    func permissionStatus() async -> LocalNotificationPermissionStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: Self.permissionStatus(for: settings.authorizationStatus))
            }
        }
    }
    
    func requestAuthorization() async -> LocalNotificationPermissionStatus {
        hasRequestedAuthorization = true
        let currentStatus = await permissionStatus()
        guard currentStatus == .notDetermined else {
            return currentStatus
        }
        
        return await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                if let error {
                    print("Local notification authorization error: \(error)")
                }
                
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    continuation.resume(returning: Self.permissionStatus(for: settings.authorizationStatus))
                }
            }
        }
    }
    
    func scheduleRestFinishedNotification(after interval: TimeInterval) {
        guard AppSettings.shared.notificationsEnabled else { return }
        
        let interval = max(interval, 1)
        requestAuthorizationIfNeeded()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.restFinished])
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notifications.rest_finished.title")
        content.body = String(localized: "notifications.rest_finished.body")
        content.sound = .default
        content.categoryIdentifier = "workout"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: NotificationID.restFinished,
                                            content: content,
                                            trigger: trigger)
        notificationCenter.add(request) { error in
            if let error {
                print("Failed to schedule rest notification: \(error)")
            }
        }
    }
    
    func cancelRestFinishedNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.restFinished])
    }
    
    func scheduleActiveWorkoutReminder(workoutTitle: String?) {
        guard AppSettings.shared.notificationsEnabled else { return }
        
        requestAuthorizationIfNeeded()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.activeWorkoutReminder])
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notifications.active_workout.title")
        if let workoutTitle, !workoutTitle.isEmpty {
            content.body = String.localizedStringWithFormat(
                String(localized: "notifications.active_workout.body_with_title"),
                workoutTitle
            )
        } else {
            content.body = String(localized: "notifications.active_workout.body")
        }
        content.sound = .default
        content.categoryIdentifier = "workout"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: activeWorkoutReminderDelay, repeats: false)
        let request = UNNotificationRequest(identifier: NotificationID.activeWorkoutReminder,
                                            content: content,
                                            trigger: trigger)
        notificationCenter.add(request) { error in
            if let error {
                print("Failed to schedule active workout reminder: \(error)")
            }
        }
    }
    
    func cancelActiveWorkoutReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.activeWorkoutReminder])
    }
    
    func cancelAllWorkoutNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            NotificationID.restFinished,
            NotificationID.activeWorkoutReminder
        ])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
    
    private static func permissionStatus(for authorizationStatus: UNAuthorizationStatus) -> LocalNotificationPermissionStatus {
        switch authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .authorized, .provisional, .ephemeral:
            .authorized
        case .denied:
            .denied
        @unknown default:
            .denied
        }
    }
}

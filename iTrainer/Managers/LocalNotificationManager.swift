//
//  LocalNotificationManager.swift
//  iTrainer
//
//  Created by Codex on 07.07.2026.
//

import Foundation
import UserNotifications

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
    
    func scheduleRestFinishedNotification(after interval: TimeInterval) {
        let interval = max(interval, 1)
        requestAuthorizationIfNeeded()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.restFinished])
        
        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Time for your next set."
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
        requestAuthorizationIfNeeded()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [NotificationID.activeWorkoutReminder])
        
        let content = UNMutableNotificationContent()
        content.title = "Workout still active"
        if let workoutTitle, !workoutTitle.isEmpty {
            content.body = "\(workoutTitle) is still running."
        } else {
            content.body = "Your workout is still running."
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
}

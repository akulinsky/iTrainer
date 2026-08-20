//
//  SettingsViewModel.swift
//  iTrainer
//
//  Created by Codex on 22.07.2026.
//

import Foundation
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationPermissionStatus: LocalNotificationPermissionStatus = .notDetermined
    
    let supportEmail = "support@liftova.app"
    let appStoreURL = URL(string: "https://liftova.app")!
    let privacyPolicyURL: URL? = URL(string: "https://liftova.app/privacy")
    
    var feedbackMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "settings.support.feedback.subject")),
            URLQueryItem(name: "body", value: feedbackBody)
        ]
        return components.url
    }
    
    var feedbackBody: String {
        "\n\n---\n\(String(localized: "settings.support.feedback.app_info"))\n\(appVersionText)\niOS \(UIDevice.current.systemVersion)"
    }
    
    var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
#if DEBUG
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
#else
        return version
#endif
    }
    
    func refreshNotificationPermissionStatus() async {
        notificationPermissionStatus = await LocalNotificationManager.shared.permissionStatus()
    }
    
    func updateNotificationsEnabled(_ isEnabled: Bool, settings: AppSettings) {
        if !isEnabled {
            settings.notificationsEnabled = false
            LocalNotificationManager.shared.cancelAllWorkoutNotifications()
            return
        }
        
        Task {
            let status = await LocalNotificationManager.shared.requestAuthorization()
            await MainActor.run {
                self.notificationPermissionStatus = status
                settings.notificationsEnabled = status == .authorized
            }
        }
    }
}

//
//  SettingsView.swift
//  iTrainer
//
//  Created by Codex on 16.07.2026.
//

import MessageUI
import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var isMailPresented = false
    @State private var isMailUnavailableAlertPresented = false
    @State private var notificationPermissionStatus: LocalNotificationPermissionStatus = .notDetermined
    
    private let supportEmail = "support@itrainer.app"
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")!
    private let privacyPolicyURL: URL? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                unitsSection
                notificationsSection
                languageSection
                supportSection
                privacySection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isMailPresented) {
            MailView(result: $mailResult,
                     recipients: [supportEmail],
                     subject: String(localized: "settings.support.feedback.subject"),
                     body: feedbackBody)
        }
        .alert(Text("settings.support.mail_unavailable.title"), isPresented: $isMailUnavailableAlertPresented) {
            Button("settings.common.ok", role: .cancel) {}
        } message: {
            Text("settings.support.mail_unavailable.message")
        }
        .task {
            await refreshNotificationPermissionStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await refreshNotificationPermissionStatus()
            }
        }
    }
    
    private var unitsSection: some View {
        settingsCard(title: "settings.units.title") {
            VStack(alignment: .leading, spacing: 18) {
                pickerRow(title: "settings.units.weight",
                          selection: $settings.weightUnitPreference,
                          options: WeightUnitPreference.allCases)
                Divider()
                    .overlay(AppColor.separatorSoft)
                pickerRow(title: "settings.units.distance",
                          selection: $settings.distanceUnitPreference,
                          options: DistanceUnitPreference.allCases)
            }
        }
    }
    
    private var languageSection: some View {
        settingsCard(title: "settings.language.title") {
            settingsActionRow(title: "settings.language.system.title",
                              subtitle: "settings.language.system.subtitle",
                              systemImage: "globe",
                              trailingSystemImage: "arrow.up.forward.app") {
                openAppSettings()
            }
        }
    }
    
    private var notificationsSection: some View {
        settingsCard(title: "settings.notifications.title") {
            VStack(alignment: .leading, spacing: 14) {
                switch notificationPermissionStatus {
                case .authorized:
                    notificationToggleRow(title: "settings.notifications.enabled.title",
                                          subtitle: settings.notificationsEnabled ? "settings.notifications.enabled.subtitle" : "settings.notifications.paused.subtitle",
                                          isEnabled: true)
                case .notDetermined:
                    notificationToggleRow(title: "settings.notifications.enable.title",
                                          subtitle: "settings.notifications.enable.subtitle",
                                          isEnabled: true)
                case .denied:
                    notificationPermissionBlockedRow
                }
            }
        }
    }
    
    private var supportSection: some View {
        settingsCard(title: "settings.support.title") {
            VStack(alignment: .leading, spacing: 14) {
                ShareLink(item: appStoreURL) {
                    settingsRowLabel(title: "settings.share_app.title",
                                     systemImage: "square.and.arrow.up",
                                     trailingSystemImage: "chevron.right")
                }
                .buttonStyle(.plain)
                
                Divider()
                    .overlay(AppColor.separatorSoft)
                
                settingsActionRow(title: "settings.rate_app.title",
                                  systemImage: "star",
                                  trailingSystemImage: "chevron.right") {
                    requestReview()
                }
                
                Divider()
                    .overlay(AppColor.separatorSoft)
                
                settingsActionRow(title: "settings.support.feedback.title",
                                  subtitle: "settings.support.feedback.subtitle",
                                  systemImage: "envelope",
                                  trailingSystemImage: "chevron.right") {
                    sendFeedback()
                }
            }
        }
    }
    
    private var privacySection: some View {
        settingsCard(title: "settings.privacy.title") {
            VStack(alignment: .leading, spacing: 14) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.privacy.local_data.title")
                            .font(AppFont.rowTitle)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("settings.privacy.local_data.subtitle")
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.brandPrimary)
                        .frame(width: 28)
                }
                
                Divider()
                    .overlay(AppColor.separatorSoft)
                
                settingsActionRow(title: "settings.privacy.policy.title",
                                  subtitle: privacyPolicyURL == nil ? "settings.privacy.policy.pending" : nil,
                                  systemImage: "doc.text",
                                  trailingSystemImage: privacyPolicyURL == nil ? nil : "chevron.right") {
                    openPrivacyPolicy()
                }
                .disabled(privacyPolicyURL == nil)
                .opacity(privacyPolicyURL == nil ? 0.55 : 1)
            }
        }
    }
    
    private var aboutSection: some View {
        settingsCard(title: "settings.about.title") {
            settingsInfoRow(title: "settings.about.version", value: appVersionText)
        }
    }
    
    private func settingsCard<Content: View>(title: LocalizedStringKey,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
            
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private func pickerRow<Option: Identifiable & Hashable>(title: LocalizedStringKey,
                                                            selection: Binding<Option>,
                                                            options: [Option]) -> some View where Option: UnitPreferenceTitleProviding {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(LocalizedStringKey(option.titleKey))
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private func settingsActionRow(title: LocalizedStringKey,
                                   subtitle: LocalizedStringKey? = nil,
                                   systemImage: String,
                                   trailingSystemImage: String?,
                                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowLabel(title: title,
                             subtitle: subtitle,
                             systemImage: systemImage,
                             trailingSystemImage: trailingSystemImage)
        }
        .buttonStyle(.plain)
    }
    
    private func settingsRowLabel(title: LocalizedStringKey,
                                  subtitle: LocalizedStringKey? = nil,
                                  systemImage: String,
                                  trailingSystemImage: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.brandPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            
            Spacer(minLength: 12)
            
            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func settingsInfoRow(title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Spacer(minLength: 12)
            Text(value)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
    
    private func notificationToggleRow(title: LocalizedStringKey,
                                       subtitle: LocalizedStringKey,
                                       isEnabled: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.brandPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            Spacer(minLength: 12)
            
            Toggle("", isOn: notificationsToggleBinding)
                .labelsHidden()
                .disabled(!isEnabled)
                .tint(AppColor.brandPrimary)
        }
    }
    
    private var notificationPermissionBlockedRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.notifications.blocked.title")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("settings.notifications.blocked.subtitle")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
            } icon: {
                Image(systemName: "bell.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.progressAmber)
                    .frame(width: 28)
            }
            
            Button {
                openAppSettings()
            } label: {
                Label("settings.notifications.open_settings", systemImage: "arrow.up.forward.app")
                    .font(AppFont.rowTitle)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.brandPrimary)
        }
    }
    
    private var notificationsToggleBinding: Binding<Bool> {
        Binding {
            notificationPermissionStatus == .authorized && settings.notificationsEnabled
        } set: { isEnabled in
            updateNotificationsEnabled(isEnabled)
        }
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(url)
    }
    
    @MainActor
    private func refreshNotificationPermissionStatus() async {
        notificationPermissionStatus = await LocalNotificationManager.shared.permissionStatus()
    }
    
    private func updateNotificationsEnabled(_ isEnabled: Bool) {
        if !isEnabled {
            settings.notificationsEnabled = false
            LocalNotificationManager.shared.cancelAllWorkoutNotifications()
            return
        }
        
        Task {
            let status = await LocalNotificationManager.shared.requestAuthorization()
            await MainActor.run {
                notificationPermissionStatus = status
                settings.notificationsEnabled = status == .authorized
            }
        }
    }
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            isMailPresented = true
            return
        }
        
        guard let url = feedbackMailURL else {
            isMailUnavailableAlertPresented = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                isMailUnavailableAlertPresented = true
            }
        }
    }
    
    private func openPrivacyPolicy() {
        guard let privacyPolicyURL else {
            return
        }
        openURL(privacyPolicyURL)
    }
    
    private var feedbackMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: String(localized: "settings.support.feedback.subject")),
            URLQueryItem(name: "body", value: feedbackBody)
        ]
        return components.url
    }
    
    private var feedbackBody: String {
        "\n\n---\n\(String(localized: "settings.support.feedback.app_info"))\n\(appVersionText)\niOS \(UIDevice.current.systemVersion)"
    }
    
    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
#if DEBUG
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
#else
        return version
#endif
    }
}

private protocol UnitPreferenceTitleProviding {
    var titleKey: String { get }
}

extension WeightUnitPreference: UnitPreferenceTitleProviding {}
extension DistanceUnitPreference: UnitPreferenceTitleProviding {}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
    }
}

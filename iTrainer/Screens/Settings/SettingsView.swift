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
    
    @StateObject private var viewModel = SettingsViewModel()
    
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var isMailPresented = false
    @State private var isMailUnavailableAlertPresented = false
    
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
                     recipients: [viewModel.supportEmail],
                     subject: String(localized: "settings.support.feedback.subject"),
                     body: viewModel.feedbackBody)
        }
        .alert(Text("settings.support.mail_unavailable.title"), isPresented: $isMailUnavailableAlertPresented) {
            Button("settings.common.ok", role: .cancel) {}
        } message: {
            Text("settings.support.mail_unavailable.message")
        }
        .task {
            await viewModel.refreshNotificationPermissionStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await viewModel.refreshNotificationPermissionStatus()
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
                switch viewModel.notificationPermissionStatus {
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
                ShareLink(item: viewModel.appStoreURL) {
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
                                  subtitle: viewModel.privacyPolicyURL == nil ? "settings.privacy.policy.pending" : nil,
                                  systemImage: "doc.text",
                                  trailingSystemImage: viewModel.privacyPolicyURL == nil ? nil : "chevron.right") {
                    openPrivacyPolicy()
                }
                .disabled(viewModel.privacyPolicyURL == nil)
                .opacity(viewModel.privacyPolicyURL == nil ? 0.55 : 1)
            }
        }
    }
    
    private var aboutSection: some View {
        settingsCard(title: "settings.about.title") {
            settingsInfoRow(title: "settings.about.version", value: viewModel.appVersionText)
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
            viewModel.notificationPermissionStatus == .authorized && settings.notificationsEnabled
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
    
    private func updateNotificationsEnabled(_ isEnabled: Bool) {
        viewModel.updateNotificationsEnabled(isEnabled, settings: settings)
    }
    
    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            isMailPresented = true
            return
        }
        
        guard let url = viewModel.feedbackMailURL else {
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
        guard let privacyPolicyURL = viewModel.privacyPolicyURL else {
            return
        }
        openURL(privacyPolicyURL)
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

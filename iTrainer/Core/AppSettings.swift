//
//  AppSettings.swift
//  iTrainer
//
//  Created by Codex on 16.07.2026.
//

import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var weightUnitPreference: WeightUnitPreference {
        didSet {
            defaults.set(weightUnitPreference.rawValue, forKey: Self.weightUnitPreferenceKey)
        }
    }
    
    @Published var distanceUnitPreference: DistanceUnitPreference {
        didSet {
            defaults.set(distanceUnitPreference.rawValue, forKey: Self.distanceUnitPreferenceKey)
        }
    }
    
    private static let weightUnitPreferenceKey = "settings.weightUnitPreference"
    private static let distanceUnitPreferenceKey = "settings.distanceUnitPreference"
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.weightUnitPreference = WeightUnitPreference(rawValue: defaults.string(forKey: Self.weightUnitPreferenceKey) ?? "") ?? .system
        self.distanceUnitPreference = DistanceUnitPreference(rawValue: defaults.string(forKey: Self.distanceUnitPreferenceKey) ?? "") ?? .system
    }
}

enum WeightUnitPreference: String, CaseIterable, Identifiable {
    case system
    case kilograms
    case pounds
    
    var id: String { rawValue }
    
    var titleKey: String {
        switch self {
        case .system:
            "settings.units.system"
        case .kilograms:
            "settings.units.weight.kilograms"
        case .pounds:
            "settings.units.weight.pounds"
        }
    }
}

enum DistanceUnitPreference: String, CaseIterable, Identifiable {
    case system
    case metric
    case imperial
    
    var id: String { rawValue }
    
    var titleKey: String {
        switch self {
        case .system:
            "settings.units.system"
        case .metric:
            "settings.units.distance.metric"
        case .imperial:
            "settings.units.distance.imperial"
        }
    }
}

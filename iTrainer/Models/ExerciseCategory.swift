//
//  ExerciseCategory.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 06.08.2024.
//

import Foundation
import SwiftUI
import UIKit

enum ImageAssetName {
    static let missing = "icMissingImage"
    
    static func resolved(_ iconName: String?) -> String {
        let iconName = iconName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        guard !iconName.isEmpty else {
            return missing
        }
        
        guard iconName == missing || UIImage(named: iconName) != nil else {
            return missing
        }
        
        return iconName
    }
}

enum ExerciseCatalogLocalization {
    static func title(for key: String, fallback: String) -> String {
        Bundle.main.localizedString(forKey: key, value: fallback, table: "ExerciseCatalog")
    }
}

struct ExerciseCategory: Decodable, Identifiable, Equatable {
    let id: String
    let titleKey: String
    let defaultTitle: String
    let kind: String
    let iconName: String
    let sortOrder: Int
    
    var title: String {
        displayName
    }
    
    var displayName: String {
        ExerciseCatalogLocalization.title(for: titleKey, fallback: defaultTitle)
    }
    
    var icon: Image {
        Image(iconName)
    }
    
    init(id: String,
         titleKey: String,
         defaultTitle: String,
         kind: String,
         iconName: String = ImageAssetName.missing,
         sortOrder: Int) {
        self.id = id
        self.titleKey = titleKey
        self.defaultTitle = defaultTitle
        self.kind = kind
        self.iconName = ImageAssetName.resolved(iconName)
        self.sortOrder = sortOrder
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case titleKey
        case defaultTitle
        case kind
        case iconName
        case sortOrder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        titleKey = try container.decode(String.self, forKey: .titleKey)
        defaultTitle = try container.decode(String.self, forKey: .defaultTitle)
        kind = try container.decode(String.self, forKey: .kind)
        iconName = ImageAssetName.resolved(try container.decodeIfPresent(String.self, forKey: .iconName))
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
    }
}

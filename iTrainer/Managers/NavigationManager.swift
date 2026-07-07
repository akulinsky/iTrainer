//
//  NavigationManager.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.06.2026.
//

import SwiftUI

final class NavigationManager: ObservableObject {
    
    @Published var path = NavigationPath()
    
    static func readSerializedData() -> Data? {
        // Read data representing the path from app's persistent storage.
        nil
    }
    
    static func writeSerializedData(_ data: Data) {
        // Write data representing the path to app's persistent storage.
    }
    
    init() {
        if let data = Self.readSerializedData() {
            do {
                let representation = try JSONDecoder().decode(
                    NavigationPath.CodableRepresentation.self,
                    from: data)
                self.path = NavigationPath(representation)
            } catch {
                self.path = NavigationPath()
            }
        } else {
            self.path = NavigationPath()
        }
    }
    
    func save() {
        guard let representation = path.codable else { return }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(representation)
            Self.writeSerializedData(data)
        } catch {
            // Handle error.
        }
    }
    
    func replaceLast<Value: Hashable>(with value: Value) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(value)
    }
}

extension EnvironmentValues {
    private struct NavigationKey: EnvironmentKey {
        static let defaultValue = NavigationManager()
    }

    var navigation: NavigationManager {
        get { self[NavigationKey.self] }
        set { self[NavigationKey.self] = newValue }
    }
}

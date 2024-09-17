//
//  LifecycleLogger.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 15.09.2024.
//

import Foundation

class LifecycleLogger {
    let name: String
    
    static var items = [String : Int]()
    
    init(name: String) {
        self.name = name
        var count = LifecycleLogger.items[name] ?? 0
        count += 1
        LifecycleLogger.items[name] = count
        print("dbg_ \(name).init count: \(count)")
    }
    
    deinit {
        var count = LifecycleLogger.items[name] ?? 0
        count -= 1
        LifecycleLogger.items[name] = count
        print("dbg_ \(name).deinit count: \(count)")
    }
}

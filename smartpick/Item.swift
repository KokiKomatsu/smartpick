//
//  Item.swift
//  smartpick
//
//  Created by Koki Komatsu on 2025/03/03.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

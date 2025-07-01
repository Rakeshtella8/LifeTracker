//
//  Item.swift
//  LifeTrack
//
//  Created by rakesh tella on 01/07/25.
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

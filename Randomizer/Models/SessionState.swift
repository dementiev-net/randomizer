//
//  SessionState.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

struct SessionState {
    var currentNumber: Int = 0
    var currentRating: Int = 0
    var sessionDuration: TimeInterval = 0
    var allTimeDuration: TimeInterval = 0
    
    var isOverLimit: Bool {
        return allTimeDuration > 3600 // 1 час
    }
}

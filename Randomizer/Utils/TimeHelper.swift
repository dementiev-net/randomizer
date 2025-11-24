//
//  TimeHelper.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

struct TimeHelper {
    private static let formatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
    
    static func format(seconds: TimeInterval) -> String {
        return formatter.string(from: seconds) ?? "00:00:00"
    }
}

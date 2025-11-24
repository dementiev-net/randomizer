//
//  RandomizerService.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

// Протокол оставляем, это хорошая привычка для архитектуры
protocol RandomizerServiceProtocol {
    func generateNumber() -> Int
    func calculateRating(for number: Int) -> Int
}

class RandomizerService: RandomizerServiceProtocol {
    func generateNumber() -> Int {
        return Int.random(in: 1..<100)
    }
    
    func calculateRating(for number: Int) -> Int {
        switch number {
        case 75...: return 5
        case 66...: return 4
        case 50...: return 3
        case 33...: return 2
        case 25...: return 1
        default:    return 0
        }
    }
}

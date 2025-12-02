//
//  SessionState.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

// MARK: - Session State

/// Состояние текущей сессии работы с приложением
///
/// Хранит информацию о текущем номере, рейтинге и продолжительности
/// использования приложения в рамках текущей и всех сессий.
struct SessionStateModel {
    
    /// Текущий активный номер
    var currentNumber: Int = 0
    
    /// Текущий рейтинг пользователя
    var currentRating: Int = 0
    
    /// Длительность текущей сессии в секундах
    var sessionDuration: TimeInterval = 0
    
    /// Общая длительность использования приложения (все сессии) в секундах
    var allTimeDuration: TimeInterval = 0
    
    /// Флаг превышения лимита использования
    ///
    /// - Returns: `true`, если общее время использования превысило 1 час (3600 секунд)
    ///
    /// - Note: Используется для отслеживания лимитов и потенциальных ограничений
    var isOverLimit: Bool {
        return allTimeDuration > 3600 // 1 час
    }
}

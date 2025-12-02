//
//  TimeHelper.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

// MARK: - Time Helper

/// Вспомогательная структура для форматирования временных интервалов
///
/// Предоставляет единый форматтер для преобразования секунд в
/// читаемый формат времени "HH:MM:SS".
///
/// Пример использования:
/// ```swift
/// let formatted = TimeHelper.format(seconds: 3661)
/// // Результат: "01:01:01"
/// ```
struct TimeHelper {
    
    /// Статический форматтер для преобразования временных интервалов
    ///
    /// Настроен на отображение часов, минут и секунд с ведущими нулями.
    /// Создаётся один раз при первом обращении для оптимизации производительности.
    private static let formatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
    
    /// Форматирует временной интервал в строку формата "HH:MM:SS"
    ///
    /// - Parameter seconds: Количество секунд для форматирования
    /// - Returns: Отформатированная строка времени (например, "01:23:45")
    ///
    /// - Note: При ошибке форматирования возвращает "00:00:00"
    ///
    /// Примеры:
    /// - `format(seconds: 0)` → "00:00:00"
    /// - `format(seconds: 61)` → "00:01:01"
    /// - `format(seconds: 3661)` → "01:01:01"
    static func format(seconds: TimeInterval) -> String {
        return formatter.string(from: seconds) ?? "00:00:00"
    }
}

//
//  RatingView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

// MARK: - Rating View

/// Визуальное представление рейтинга в виде горизонтальных полосок
///
/// Отображает уровень от 0 до 5 в виде цветных прямоугольников.
/// Активные полоски заполнены градиентом указанного цвета,
/// неактивные - полупрозрачным серым.
///
/// Пример использования:
/// ```swift
/// RatingView(level: 3, activeColor: .yellow)
/// RatingView(level: 5, activeColor: .green)
/// ```
struct RatingView: View {
    
    /// Текущий уровень рейтинга (0-5)
    let level: Int
    
    /// Цвет активных полосок
    ///
    /// Обычно зависит от уровня:
    /// - Красный: низкий рейтинг (0-2)
    /// - Жёлтый: средний рейтинг (3-4)
    /// - Зелёный: высокий рейтинг (5)
    let activeColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                // Градиент для активных ячеек
                let gradient = LinearGradient(
                    colors: [activeColor, activeColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Заливка для неактивных ячеек
                let inactiveFill = Color.white.opacity(0.15)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(index <= level ? AnyShapeStyle(gradient) : AnyShapeStyle(inactiveFill))
                    .frame(height: 12)
            }
        }
    }
}

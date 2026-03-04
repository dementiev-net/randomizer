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
/// Отображает число 0-99 в виде 3 дискретных плашек по ~33%.
/// Активна только одна плашка текущего диапазона (низ/середина/верх),
/// неактивные - полупрозрачным серым.
///
/// Пример использования:
/// ```swift
/// RatingView(number: 22, activeColor: Color(red: 0.45, green: 0.48, blue: 0.53))
/// RatingView(number: 88, activeColor: Color(red: 0.95, green: 0.97, blue: 0.99))
/// ```
struct RatingView: View {

    /// Текущее число рандомайзера (0-99)
    let number: Int

    /// Цвет активных полосок
    ///
    /// Подбирается по диапазонам:
    /// - 0-33: сероватый
    /// - 34-66: светло-серо-голубой
    /// - 67-99: почти белый
    let activeColor: Color

    private var activeSegment: Int {
        switch number {
        case ...33:
            return 1
        case 34...66:
            return 2
        default:
            return 3
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { index in
                // Градиент для активных ячеек
                let gradient = LinearGradient(
                    colors: [activeColor.opacity(0.95), activeColor.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Заливка для неактивных ячеек
                let inactiveFill = Color.white.opacity(0.15)

                RoundedRectangle(cornerRadius: 3)
                    .fill(index == activeSegment ? AnyShapeStyle(gradient) : AnyShapeStyle(inactiveFill))
                    .frame(height: 12)
            }
        }
    }
}

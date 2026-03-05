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
/// Отображает 3 дискретные плашки нижнего индикатора.
/// Активна только одна плашка текущего диапазона (низ/середина/верх),
/// неактивные - полупрозрачным серым.
///
/// Пример использования:
/// ```swift
/// RatingView(activeSegment: 1, activeColor: Color(red: 0.45, green: 0.48, blue: 0.53))
/// RatingView(activeSegment: 3, activeColor: Color(red: 0.95, green: 0.97, blue: 0.99))
/// ```
struct RatingView: View {

    /// Текущий активный сегмент (1...3)
    let activeSegment: Int

    /// Цвет активных полосок
    ///
    /// Подбирается по текущему диапазону во ViewModel.
    let activeColor: Color

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

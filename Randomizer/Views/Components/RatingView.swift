//
//  RatingView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

struct RatingView: View {
    let level: Int
    let activeColor: Color // Цвет передаем извне (красный/желтый/зеленый)
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                // Градиент для активных ячеек
                let gradient = LinearGradient(
                    colors: [activeColor, activeColor.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Для неактивных - просто прозрачный серый
                let inactiveFill = Color.white.opacity(0.15)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(index <= level ? AnyShapeStyle(gradient) : AnyShapeStyle(inactiveFill))
                    .frame(height: 12) // Высота полоски
            }
        }
    }
}

//
//  ContentView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

// MARK: - Content View

/// Главное представление приложения Randomizer
///
/// Отображает:
/// - Крупное случайное число (000-099)
/// - Визуальный рейтинг в виде цветных полосок
/// - Таймеры текущей сессии и общего времени использования
/// - Индикаторы усталости при длительном использовании
///
/// ## Взаимодействие:
/// - Тап по экрану генерирует новое случайное число
/// - Кнопка сброса обнуляет таймер сессии
/// - Тактильная обратная связь при генерации
///
/// ## Состояния усталости:
/// - **Normal**: стандартное отображение
/// - **Warning**: жёлтый цвет таймера + иконка предупреждения
/// - **Critical**: красный пульсирующий таймер
struct ContentView: View {
    
    // MARK: - State Properties
    
    /// ViewModel с бизнес-логикой и состоянием
    @StateObject private var viewModel = RandomizerView()
    
    /// Флаг для анимации пульсации в критическом состоянии
    @State private var isPulsing = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            
            // 1. Основное число (крупный шрифт с ведущими нулями)
            Text(String(format: "%03d", viewModel.state.currentNumber))
                .font(.custom("HelveticaNeue-Bold", size: 150))
                .lineLimit(1)
                .minimumScaleFactor(0.5) // Адаптивное уменьшение при нехватке места
                .foregroundColor(.white)
                .contentShape(Rectangle()) // Расширяет область тапа
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            // 2. Визуальный рейтинг (цветные полоски)
            RatingView(level: viewModel.state.currentRating, activeColor: viewModel.barColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 5)
            
            // 3. Секция таймеров
            VStack(spacing: 4) {
                
                // Строка таймера текущей сессии
                HStack {
                    Text("Сессия")
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Время сессии + кнопка сброса
                    HStack(spacing: 6) {
                        Text(TimeHelper.format(seconds: viewModel.state.sessionDuration))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        // Кнопка сброса таймера сессии
                        Button(action: viewModel.resetAllTime) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: 16, height: 14)
                        }
                        .buttonStyle(.plain)
                        .help("Reset Session")
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Строка общего времени использования
                HStack {
                    HStack(spacing: 4) {
                        Text("Все время")
                        
                        // Иконка предупреждения при усталости
                        if viewModel.fatigueState != .normal {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                        }
                    }
                    .foregroundColor(viewModel.timerColor)
                    
                    Spacer()
                    
                    // Время + невидимая заглушка для выравнивания
                    HStack(spacing: 6) {
                        Text(TimeHelper.format(seconds: viewModel.state.allTimeDuration))
                            .foregroundColor(viewModel.timerColor)
                            .monospacedDigit()
                            .fontWeight(viewModel.fatigueState == .normal ? .regular : .bold)
                            .opacity(viewModel.fatigueState == .critical && isPulsing ? 0.5 : 1.0)
                            .animation(
                                viewModel.fatigueState == .critical ?
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                                value: isPulsing
                            )
                            .onAppear { isPulsing = true }
                        
                        // Невидимая заглушка для выравнивания со строкой выше
                        // (компенсирует ширину кнопки сброса)
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 16, height: 14)
                            .opacity(0)
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .default))
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .background(Color.black.opacity(0.01)) // Делает весь фон кликабельным
        .onTapGesture {
            // Тактильная обратная связь
            let generator = NSHapticFeedbackManager.defaultPerformer
            generator.perform(.alignment, performanceTime: .now)
            
            // Генерация нового числа
            viewModel.generateNewData()
        }
    }
}

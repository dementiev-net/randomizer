//
//  ContentView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RandomizerView()
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 8) { // Чуть меньше отступ между блоками
            
            // 1. ОГРОМНОЕ ЧИСЛО
            Text(String(format: "%03d", viewModel.state.currentNumber))
                .font(.custom("HelveticaNeue-Bold", size: 150)) // Чуть больше шрифт
                .lineLimit(1)
                .minimumScaleFactor(0.5) // Если вдруг окно сожмут, цифры уменьшатся, а не обрежутся
            //.padding(.top, 5)
                .foregroundColor(.white)
                .contentShape(Rectangle()) // Чтобы кликалось
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1) // Легкая тень для объема
            
            // 2. РЕЙТИНГ (Полоска)
            RatingView(level: viewModel.state.currentRating, activeColor: viewModel.barColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 5)
            
            // 3. ТАЙМЕРЫ (Аккуратные строки)
            VStack(spacing: 4) {
                
                // --- Строка Session ---
                HStack {
                    Text("Сессия")
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Группируем Время + Кнопку
                    HStack(spacing: 6) {
                        Text(TimeHelper.format(seconds: viewModel.state.sessionDuration))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        // Кнопка сброса (ВИДИМАЯ)
                        Button(action: viewModel.resetAllTime) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: 16, height: 14) // Фиксируем размер
                        }
                        .buttonStyle(.plain)
                        .help("Reset Session")
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // --- Строка Alltime ---
                HStack {
                    HStack(spacing: 4) {
                        Text("Все время")
                        if viewModel.fatigueState != .normal {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                        }
                    }
                    .foregroundColor(viewModel.timerColor)
                    
                    Spacer()
                    
                    // Группируем Время + Невидимую кнопку
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
                        
                        // --- ЗАГЛУШКА (Секрет выравнивания) ---
                        // Это точно такая же иконка, как сверху, но полностью прозрачная
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 16, height: 14) // Тот же размер
                            .opacity(0) // Невидимая!
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .default))
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .background(Color.black.opacity(0.01)) // Для кликабельности фона
        .onTapGesture {
            let generator = NSHapticFeedbackManager.defaultPerformer
            generator.perform(.alignment, performanceTime: .now)
            viewModel.generateNewData()
        }
    }
}

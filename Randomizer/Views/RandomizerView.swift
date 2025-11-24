//
//  RandomizerViewModel.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI
import Combine

// Состояния усталости
enum SessionFatigueState {
    case normal     // Всё ок
    case warning    // Пора закругляться (55+ мин)
    case critical   // Переработка (60+ мин)
}

class RandomizerView: ObservableObject {
    @Published var state = SessionState()
    
    // Цвета и состояния
    @Published var barColor: Color = .blue
    @Published var fatigueState: SessionFatigueState = .normal // Текущее состояние усталости
    
    // Настройки таймера (в секундах)
    //private let warningThreshold: TimeInterval = 10 // Предупреждение через 10 сек
    //private let criticalThreshold: TimeInterval = 20 // Тревога через 20 сек
    private let warningThreshold: TimeInterval = 55 * 60 // 55 минут
    private let criticalThreshold: TimeInterval = 60 * 60 // 60 минут
    
    private let service: RandomizerServiceProtocol
    private var timer: AnyCancellable?
    private let randomInterval: TimeInterval = 10.0
    
    init(service: RandomizerServiceProtocol = RandomizerService()) {
        self.service = service
        startTimer()
        generateNewData()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        state.sessionDuration += 1
        state.allTimeDuration += 1
        
        // Проверяем усталость каждую секунду
        checkFatigue()
        
        if Int(state.sessionDuration) % Int(randomInterval) == 0 {
            generateNewData()
        }
    }
    
    // --- Логика Умного Таймера ---
    private func checkFatigue() {
        if state.allTimeDuration >= criticalThreshold {
            if fatigueState != .critical { fatigueState = .critical }
        } else if state.allTimeDuration >= warningThreshold {
            if fatigueState != .warning { fatigueState = .warning }
        } else {
            if fatigueState != .normal { fatigueState = .normal }
        }
    }
    
    // Получить цвет для таймера в зависимости от состояния
    var timerColor: Color {
        switch fatigueState {
        case .normal: return .gray
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    // --- Остальная логика ---
    func generateNewData() {
        let newNumber = service.generateNumber()
        state.currentNumber = newNumber
        state.currentRating = service.calculateRating(for: newNumber)
        updateBarColor(for: newNumber)
    }
    
    private func updateBarColor(for number: Int) {
        switch number {
        case 67...100: barColor = .green
        case 34...66:  barColor = .yellow
        default:       barColor = .red
        }
    }
    
    func resetAllTime() {
        state.allTimeDuration = 0
        checkFatigue() // Сразу сбрасываем цвет
    }
}

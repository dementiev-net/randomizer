//
//  RandomizerViewModel.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI
import Combine

// MARK: - Session Fatigue State

/// Состояния усталости пользователя на основе времени использования
///
/// Используется для визуальной индикации длительности работы с приложением:
/// - **normal**: стандартное состояние (серый цвет)
/// - **warning**: предупреждение о длительной работе (оранжевый цвет, 55+ минут)
/// - **critical**: критическая усталость (красный пульсирующий, 60+ минут)
enum SessionFatigueState {
    /// Нормальное состояние (менее 55 минут)
    case normal
    
    /// Предупреждение о приближении к лимиту (55-59 минут)
    case warning
    
    /// Критическое состояние, рекомендуется перерыв (60+ минут)
    case critical
}

// MARK: - Randomizer View Model

/// ViewModel для управления состоянием генератора случайных чисел
///
/// Отвечает за:
/// - Генерацию случайных чисел и расчёт рейтинга
/// - Отслеживание времени текущей сессии и общего времени
/// - Автоматическую генерацию новых чисел каждые 10 секунд
/// - Мониторинг состояния усталости с визуальной индикацией
/// - Управление цветами UI в зависимости от рейтинга и усталости
///
/// ## Пороги усталости:
/// - **55 минут**: переход в состояние warning (оранжевый)
/// - **60 минут**: переход в состояние critical (красный, пульсация)
class RandomizerView: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Текущее состояние сессии (числа, рейтинг, таймеры)
    @Published var state = SessionStateModel()
    
    /// Цвет полосок рейтинга (зависит от сгенерированного числа)
    ///
    /// - Зелёный: 67-100 (высокий рейтинг)
    /// - Жёлтый: 34-66 (средний рейтинг)
    /// - Красный: 1-33 (низкий рейтинг)
    @Published var barColor: Color = .blue
    
    /// Текущее состояние усталости пользователя
    @Published var fatigueState: SessionFatigueState = .normal
    
    // MARK: - Private Properties
    
    /// Порог предупреждения о длительной работе (55 минут)
    private let warningThreshold: TimeInterval = 55 * 60
    
    /// Порог критической усталости (60 минут)
    private let criticalThreshold: TimeInterval = 60 * 60
    
    /// Сервис генерации случайных чисел и расчёта рейтинга
    private let service: RandomizerServiceProtocol
    
    /// Таймер для отслеживания времени и автогенерации
    private var timer: AnyCancellable?
    
    /// Интервал автоматической генерации нового числа (секунды)
    private let randomInterval: TimeInterval = 10.0
    
    // MARK: - Initialization
    
    /// Инициализирует ViewModel с опциональным сервисом
    ///
    /// - Parameter service: Сервис генерации чисел (по умолчанию `RandomizerService`)
    ///
    /// Автоматически запускает таймер и генерирует первое число.
    init(service: RandomizerServiceProtocol = RandomizerService()) {
        self.service = service
        startTimer()
        generateNewData()
    }
    
    // MARK: - Timer Management
    
    /// Запускает таймер обновления состояния (срабатывает каждую секунду)
    ///
    /// Таймер обновляет:
    /// - Длительность текущей сессии
    /// - Общее время использования
    /// - Состояние усталости
    /// - Автоматически генерирует новое число каждые 10 секунд
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    /// Обработчик тика таймера (вызывается каждую секунду)
    ///
    /// Увеличивает счётчики времени, проверяет усталость и
    /// генерирует новое число при достижении интервала автогенерации.
    private func tick() {
        state.sessionDuration += 1
        state.allTimeDuration += 1
        
        // Проверяем усталость каждую секунду
        checkFatigue()
        
        // Автогенерация каждые 10 секунд
        if Int(state.sessionDuration) % Int(randomInterval) == 0 {
            generateNewData()
        }
    }
    
    // MARK: - Fatigue Monitoring
    
    /// Проверяет уровень усталости на основе общего времени использования
    ///
    /// Обновляет `fatigueState` в зависимости от пройденного времени:
    /// - < 55 минут: normal
    /// - 55-59 минут: warning
    /// - ≥ 60 минут: critical
    private func checkFatigue() {
        if state.allTimeDuration >= criticalThreshold {
            if fatigueState != .critical { fatigueState = .critical }
        } else if state.allTimeDuration >= warningThreshold {
            if fatigueState != .warning { fatigueState = .warning }
        } else {
            if fatigueState != .normal { fatigueState = .normal }
        }
    }
    
    /// Возвращает цвет таймера в зависимости от состояния усталости
    ///
    /// - Returns: Цвет для отображения таймера общего времени
    ///
    /// Цветовая схема:
    /// - **normal**: серый
    /// - **warning**: оранжевый
    /// - **critical**: красный
    var timerColor: Color {
        switch fatigueState {
        case .normal: return .gray
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    // MARK: - Public Methods
    
    /// Генерирует новое случайное число и обновляет состояние
    ///
    /// Создаёт новое число через сервис, рассчитывает рейтинг
    /// и обновляет цвет полосок рейтинга.
    ///
    /// Вызывается:
    /// - При инициализации
    /// - Каждые 10 секунд автоматически
    /// - При тапе пользователя по экрану
    func generateNewData() {
        let newNumber = service.generateNumber()
        state.currentNumber = newNumber
        state.currentRating = service.calculateRating(for: newNumber)
        updateBarColor(for: newNumber)
    }
    
    /// Сбрасывает счётчик общего времени использования
    ///
    /// Обнуляет `allTimeDuration` и пересчитывает состояние усталости,
    /// возвращая UI в нормальное состояние.
    ///
    /// - Note: Счётчик текущей сессии не сбрасывается
    func resetAllTime() {
        state.allTimeDuration = 0
        checkFatigue() // Сразу обновляем визуальное состояние
    }
    
    // MARK: - Private Methods
    
    /// Обновляет цвет полосок рейтинга в зависимости от числа
    ///
    /// - Parameter number: Сгенерированное число (1-99)
    ///
    /// Логика окрашивания:
    /// - **67-100**: зелёный (высокий)
    /// - **34-66**: жёлтый (средний)
    /// - **1-33**: красный (низкий)
    private func updateBarColor(for number: Int) {
        switch number {
        case 67...100: barColor = .green
        case 34...66:  barColor = .yellow
        default:       barColor = .red
        }
    }
}

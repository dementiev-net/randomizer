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
    /// - Зелёный: 67-99 (высокий рейтинг)
    /// - Жёлтый: 34-66 (средний рейтинг)
    /// - Красный: 1-33 (низкий рейтинг)
    @Published var barColor: Color = .blue

    /// Текущее состояние усталости пользователя
    @Published var fatigueState: SessionFatigueState = .normal

    /// Текущий банкролл в долларах
    @Published private(set) var currentBankrollUSD: Double = 0

    /// Лимит для шота (например, 25 для NL25)
    @Published private(set) var shotLimitNL: Int = 25

    /// Количество попыток шота верхнего лимита
    @Published private(set) var shotAttempts: Int = 0

    // MARK: - Private Properties

    /// Порог предупреждения о длительной работе (55 минут)
    private let warningThreshold: TimeInterval = 55 * 60

    /// Порог критической усталости (60 минут)
    private let criticalThreshold: TimeInterval = 60 * 60

    /// Сервис генерации случайных чисел и расчёта рейтинга
    private let service: RandomizerServiceProtocol

    /// Персистентное хранилище общего времени
    private let defaults: UserDefaults

    /// Ключ сохранения общего времени использования
    private let allTimeDurationKey = "allTimeDuration"

    /// Ключ сохранения текущего банкролла
    private let currentBankrollUSDKey = "currentBankrollUSD"

    /// Ключ сохранения лимита для шота
    private let shotLimitNLKey = "shotLimitNL"

    /// Ключ сохранения количества попыток шота
    private let shotAttemptsKey = "shotAttempts"

    /// Таймер для отслеживания времени и автогенерации
    private var timer: AnyCancellable?

    /// Интервал автоматической генерации нового числа (секунды)
    private let randomInterval: TimeInterval = 10.0

    // MARK: - Initialization

    /// Инициализирует ViewModel с опциональным сервисом
    ///
    /// - Parameters:
    ///   - service: Сервис генерации чисел (по умолчанию `RandomizerService`)
    ///   - autoStartTimer: Запускать ли внутренний таймер сразу после инициализации
    ///   - defaults: Хранилище для персистентного общего времени
    ///
    /// Автоматически восстанавливает общее время и генерирует первое число.
    init(
        service: RandomizerServiceProtocol = RandomizerService(),
        autoStartTimer: Bool = true,
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.defaults = defaults

        state.allTimeDuration = defaults.double(forKey: allTimeDurationKey)
        loadBankrollSettings()
        checkFatigue()

        if autoStartTimer {
            startTimer()
        }

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
    func tick() {
        state.sessionDuration += 1
        state.allTimeDuration += 1
        persistAllTimeDuration()

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

    /// Требуемый банкролл для шота (25 BI верхнего лимита)
    var requiredBankrollForShot: Double {
        Double(shotLimitNL) * 25
    }

    /// Бюджет шота (2 BI верхнего лимита)
    var shotBudget: Double {
        Double(shotLimitNL) * 2
    }

    /// Сколько не хватает до минимального банкролла для шота
    var missingBankrollForShot: Double {
        max(0, requiredBankrollForShot - currentBankrollUSD)
    }

    /// Можно ли делать шот верхнего лимита
    var canTakeShot: Bool {
        currentBankrollUSD >= requiredBankrollForShot
    }

    /// Запас банкролла сверх минимального порога для шота
    var bankrollReserveForShot: Double {
        max(0, currentBankrollUSD - requiredBankrollForShot)
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

    /// Сбрасывает длительность текущей сессии
    ///
    /// Обнуляет `sessionDuration` без изменения общего времени.
    func resetSession() {
        state.sessionDuration = 0
    }

    /// Сбрасывает общее время использования
    ///
    /// Обнуляет `allTimeDuration`, сохраняет состояние и пересчитывает усталость.
    func resetAllTime() {
        state.allTimeDuration = 0
        persistAllTimeDuration()
        checkFatigue()
    }

    /// Обновляет текущий банкролл
    ///
    /// - Parameter value: Значение в долларах
    func setCurrentBankrollUSD(_ value: Double) {
        currentBankrollUSD = max(0, value)
        persistBankrollSettings()
    }

    /// Обновляет верхний лимит для шота
    ///
    /// - Parameter value: Лимит NL (например, 25 для NL25)
    func setShotLimitNL(_ value: Int) {
        shotLimitNL = max(1, value)
        persistBankrollSettings()
    }

    /// Обновляет количество попыток шота
    ///
    /// - Parameter value: Количество попыток (не меньше 0)
    func setShotAttempts(_ value: Int) {
        shotAttempts = max(0, value)
        persistBankrollSettings()
    }

    /// Увеличивает счётчик попыток шота на 1
    func incrementShotAttempts() {
        setShotAttempts(shotAttempts + 1)
    }

    /// Уменьшает счётчик попыток шота на 1 (не ниже 0)
    func decrementShotAttempts() {
        setShotAttempts(max(0, shotAttempts - 1))
    }

    // MARK: - Private Methods

    /// Обновляет цвет полосок рейтинга в зависимости от числа
    ///
    /// - Parameter number: Сгенерированное число (1-99)
    ///
    /// Логика окрашивания:
    /// - **67-99**: зелёный (высокий)
    /// - **34-66**: жёлтый (средний)
    /// - **1-33**: красный (низкий)
    private func updateBarColor(for number: Int) {
        switch number {
        case 67...99: barColor = .green
        case 34...66: barColor = .yellow
        default:      barColor = .red
        }
    }

    /// Сохраняет общее время использования в `UserDefaults`
    private func persistAllTimeDuration() {
        defaults.set(state.allTimeDuration, forKey: allTimeDurationKey)
    }

    /// Загружает параметры банкролла и шота из `UserDefaults`
    private func loadBankrollSettings() {
        if defaults.object(forKey: currentBankrollUSDKey) != nil {
            currentBankrollUSD = max(0, defaults.double(forKey: currentBankrollUSDKey))
        } else {
            currentBankrollUSD = 0
        }

        if defaults.object(forKey: shotLimitNLKey) != nil {
            shotLimitNL = max(1, defaults.integer(forKey: shotLimitNLKey))
        } else {
            shotLimitNL = 25
        }

        if defaults.object(forKey: shotAttemptsKey) != nil {
            shotAttempts = max(0, defaults.integer(forKey: shotAttemptsKey))
        } else {
            shotAttempts = 0
        }
    }

    /// Сохраняет параметры банкролла и шота в `UserDefaults`
    private func persistBankrollSettings() {
        defaults.set(currentBankrollUSD, forKey: currentBankrollUSDKey)
        defaults.set(shotLimitNL, forKey: shotLimitNLKey)
        defaults.set(shotAttempts, forKey: shotAttemptsKey)
    }
}

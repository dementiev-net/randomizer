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
/// - **warning**: предупреждение о длительной работе (оранжевый цвет)
/// - **critical**: критическая усталость (красный пульсирующий)
enum SessionFatigueState: Equatable {
    /// Нормальное состояние (менее порога warning)
    case normal

    /// Предупреждение о приближении к лимиту (между warning и critical)
    case warning

    /// Критическое состояние, рекомендуется перерыв (выше порога critical)
    case critical
}

/// Причина блокировки текущей сессии по лимитам
enum SessionLimitReason: String, Equatable {
    /// Достигнут лимит потерь
    case stopLoss

    /// Достигнут лимит прибыли
    case stopWin
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
/// - Значения настраиваются пользователем в окне настроек.
class RandomizerView: ObservableObject {

    // MARK: - Published Properties

    /// Текущее состояние сессии (числа, рейтинг, таймеры)
    @Published var state = SessionStateModel()

    /// Цвет полосок рейтинга (зависит от сгенерированного числа)
    ///
    /// Цвет зависит от текущего сегмента индикатора
    /// (границы сегментов настраиваются пользователем).
    @Published var barColor: Color = Color(red: 0.45, green: 0.48, blue: 0.53)

    /// Верхняя граница нижнего диапазона индикатора (0...N)
    @Published private(set) var randomizerLowUpperBound: Int = 33

    /// Верхняя граница среднего диапазона индикатора (N+1...M)
    @Published private(set) var randomizerMidUpperBound: Int = 66

    /// Текущее состояние усталости пользователя
    @Published var fatigueState: SessionFatigueState = .normal

    /// Порог warning для усталости в минутах
    @Published private(set) var fatigueWarningMinutes: Int = 55

    /// Порог critical для усталости в минутах
    @Published private(set) var fatigueCriticalMinutes: Int = 60

    /// Текущий банкролл в долларах
    @Published private(set) var currentBankrollUSD: Double = 0

    /// Лимит для шота (например, 25 для NL25)
    @Published private(set) var shotLimitNL: Int = 25

    /// Порог банкролла для шота в бай-инах (например, 25 BI)
    @Published private(set) var shotBankrollThresholdBuyIns: Int = 25

    /// Количество попыток шота в BI (стоп-лосс = -N BI)
    @Published private(set) var shotAttempts: Int = 2

    /// Накопленный результат текущего шота в долларах
    @Published private(set) var currentShotResultUSD: Double = 0

    /// Флаг блокировки шота после достижения стоп-лосса
    @Published private(set) var isShotLocked: Bool = false

    /// Лимит убытка текущей сессии в долларах (0 = выключен)
    @Published private(set) var sessionStopLossUSD: Double = 0

    /// Включён ли жёсткий режим stop-loss (автоблокировка на перерыв)
    @Published private(set) var hardStopLossEnabled: Bool = false

    /// Длительность перерыва после stop-loss (в минутах)
    @Published private(set) var hardStopLossBreakMinutes: Int = 15

    /// Время окончания перерыва после stop-loss (если активен)
    @Published private(set) var stopLossBlockUntil: Date?

    /// Лимит прибыли текущей сессии в долларах (0 = выключен)
    @Published private(set) var sessionStopWinUSD: Double = 0

    /// Результат текущей сессии в долларах
    @Published private(set) var sessionResultUSD: Double = 0

    /// Причина блокировки текущей сессии по лимитам
    @Published private(set) var sessionLimitReason: SessionLimitReason?

    /// Журнал шотов (новые записи в начале списка)
    @Published private(set) var shotJournalEntries: [ShotJournalEntry] = []

    // MARK: - Private Properties

    /// Минимально допустимый порог warning (в минутах)
    private let minFatigueWarningMinutes = 1

    /// Максимально допустимый порог warning (в минутах)
    private let maxFatigueWarningMinutes = 1439

    /// Минимально допустимый порог critical (в минутах)
    private let minFatigueCriticalMinutes = 2

    /// Максимально допустимый порог critical (в минутах)
    private let maxFatigueCriticalMinutes = 1440

    /// Сервис генерации случайных чисел и расчёта рейтинга
    private let service: RandomizerServiceProtocol

    /// Сервис локальных уведомлений macOS
    private let notificationService: NotificationServiceProtocol

    /// Провайдер текущего времени (для таймеров и тестируемости)
    private let currentDateProvider: () -> Date

    /// Полный путь к JSON-файлу с настройками банкролла
    private let bankrollSettingsFileURL: URL

    /// Полный путь к JSON-файлу с журналом шотов
    private let shotJournalFileURL: URL

    /// Таймер для отслеживания времени и автогенерации
    private var timer: AnyCancellable?

    /// Интервал автоматической генерации нового числа (секунды)
    private let randomInterval: TimeInterval = 10.0

    // MARK: - Initialization

    /// Инициализирует ViewModel с опциональным сервисом
    ///
    /// - Parameters:
    ///   - service: Сервис генерации чисел (по умолчанию `RandomizerService`)
    ///   - notificationService: Сервис локальных уведомлений
    ///   - autoStartTimer: Запускать ли внутренний таймер сразу после инициализации
    ///   - defaults: Не используется (оставлен для обратной совместимости инициализации)
    ///   - bankrollSettingsFileURL: URL JSON-файла настроек банкролла
    ///   - shotJournalFileURL: URL JSON-файла журнала шотов
    ///
    /// Автоматически восстанавливает общее время и генерирует первое число.
    init(
        service: RandomizerServiceProtocol = RandomizerService(),
        notificationService: NotificationServiceProtocol = NoopNotificationService(),
        autoStartTimer: Bool = true,
        defaults _: UserDefaults = .standard,
        bankrollSettingsFileURL: URL? = nil,
        shotJournalFileURL: URL? = nil,
        currentDateProvider: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.notificationService = notificationService
        self.currentDateProvider = currentDateProvider
        self.bankrollSettingsFileURL = bankrollSettingsFileURL ?? Self.defaultBankrollSettingsFileURL()
        self.shotJournalFileURL = shotJournalFileURL ?? Self.defaultShotJournalFileURL()

        state.allTimeDuration = 0
        loadBankrollSettings()
        loadShotJournal()
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

        // Проверяем усталость каждую секунду
        checkFatigue()
        handleHardStopLossBreakIfNeeded()

        // Автогенерация каждые 10 секунд
        if Int(state.sessionDuration) % Int(randomInterval) == 0 {
            generateNewData()
        }
    }

    /// Порог warning в секундах
    private var warningThreshold: TimeInterval {
        TimeInterval(fatigueWarningMinutes * 60)
    }

    /// Порог critical в секундах
    private var criticalThreshold: TimeInterval {
        TimeInterval(fatigueCriticalMinutes * 60)
    }

    // MARK: - Fatigue Monitoring

    /// Проверяет уровень усталости на основе общего времени использования
    ///
    /// Обновляет `fatigueState` в зависимости от пройденного времени:
    /// - < warning: normal
    /// - warning..<(critical): warning
    /// - >= critical: critical
    private func checkFatigue() {
        let previousState = fatigueState
        let nextState: SessionFatigueState

        if state.allTimeDuration >= criticalThreshold {
            nextState = .critical
        } else if state.allTimeDuration >= warningThreshold {
            nextState = .warning
        } else {
            nextState = .normal
        }

        guard nextState != previousState else { return }
        fatigueState = nextState
        notifyFatigueTransition(from: previousState, to: nextState)
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

    /// Требуемый банкролл для шота (N BI верхнего лимита из настроек)
    var requiredBankrollForShot: Double {
        Double(shotLimitNL) * Double(shotBankrollThresholdBuyIns)
    }

    /// Бюджет шота (N BI верхнего лимита, где N = попытки шота)
    var shotBudget: Double {
        Double(shotLimitNL) * Double(shotAttempts)
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

    /// Запас банкролла сверх порога в бай-инах верхнего лимита
    var bankrollReserveForShotInBuyIns: Double {
        guard shotLimitNL > 0 else { return 0 }
        return bankrollReserveForShot / Double(shotLimitNL)
    }

    /// Накопленный результат текущего шота в бай-инах
    var currentShotResultBuyIns: Double {
        guard shotLimitNL > 0 else { return 0 }
        return currentShotResultUSD / Double(shotLimitNL)
    }

    /// Можно ли прямо сейчас играть шот (достаточный банкролл и нет блокировки)
    var isShotAvailable: Bool {
        canTakeShot && !isShotLocked
    }

    /// Заблокирована ли текущая сессия по stop-loss / stop-win
    var isSessionPlayBlocked: Bool {
        sessionLimitReason != nil
    }

    /// Активен ли перерыв по жёсткому stop-loss
    var isHardStopLossBreakActive: Bool {
        guard hardStopLossEnabled, let stopLossBlockUntil else { return false }
        return currentDateProvider() < stopLossBlockUntil
    }

    /// Оставшееся время перерыва в секундах
    var hardStopLossBreakRemainingSeconds: Int {
        guard let stopLossBlockUntil else { return 0 }
        return max(0, Int(ceil(stopLossBlockUntil.timeIntervalSince(currentDateProvider()))))
    }

    /// Оставшееся время перерыва в формате HH:MM:SS
    var hardStopLossBreakRemainingText: String {
        TimeHelper.format(seconds: TimeInterval(hardStopLossBreakRemainingSeconds))
    }

    /// Текущий активный сегмент нижнего индикатора (1...3)
    var currentRandomizerSegment: Int {
        randomizerSegment(for: state.currentNumber)
    }

    /// Цвет крупного числа на главном экране с учетом лимитов и усталости
    var randomizerNumberColor: Color {
        switch sessionLimitReason {
        case .stopLoss:
            return .red
        case .stopWin:
            return .green
        case nil:
            return fatigueState == .normal ? .white : .yellow
        }
    }

    /// Текст статуса текущей сессии для главного экрана
    var sessionStatusText: String? {
        switch sessionLimitReason {
        case .stopLoss:
            if isHardStopLossBreakActive {
                return "перерыв \(hardStopLossBreakRemainingText)"
            }
            return "игра запрещена по stop-loss"
        case .stopWin:
            return "stop-win достигнут"
        case nil:
            return fatigueState == .normal ? nil : "отдохни"
        }
    }

    /// Цвет текста статуса текущей сессии
    var sessionStatusColor: Color {
        switch sessionLimitReason {
        case .stopLoss:
            return .red
        case .stopWin:
            return .green
        case nil:
            return fatigueState == .normal ? .gray : .yellow
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
        guard !isSessionPlayBlocked else { return }

        let newNumber = service.generateNumber()
        state.currentNumber = newNumber
        state.currentRating = service.calculateRating(for: newNumber)
        updateBarColor(for: newNumber)
    }

    /// Сбрасывает длительность текущей сессии
    ///
    /// Обнуляет текущую сессию:
    /// - таймер сессии
    /// - результат сессии
    /// - блокировку по stop-loss / stop-win
    func resetSession() {
        state.sessionDuration = 0
        sessionResultUSD = 0
        sessionLimitReason = nil
        stopLossBlockUntil = nil
        persistBankrollSettings()
    }

    /// Сбрасывает общее время использования
    ///
    /// Обнуляет `allTimeDuration` и пересчитывает усталость.
    func resetAllTime() {
        state.allTimeDuration = 0
        checkFatigue()
    }

    /// Обновляет текущий банкролл
    ///
    /// - Parameter value: Значение в долларах
    func setCurrentBankrollUSD(_ value: Double) {
        currentBankrollUSD = max(0, value)
        evaluateAutoUnlockIfNeeded()
        persistBankrollSettings()
    }

    /// Обновляет верхний лимит для шота
    ///
    /// - Parameter value: Лимит NL (например, 25 для NL25)
    func setShotLimitNL(_ value: Int) {
        shotLimitNL = max(1, value)
        evaluateAutoUnlockIfNeeded()
        evaluateShotStopLossIfNeeded()
        persistBankrollSettings()
    }

    /// Обновляет порог банкролла для шота в BI
    ///
    /// - Parameter value: Порог в BI (не меньше 1)
    func setShotBankrollThresholdBuyIns(_ value: Int) {
        shotBankrollThresholdBuyIns = max(1, value)
        evaluateAutoUnlockIfNeeded()
        persistBankrollSettings()
    }

    /// Обновляет количество попыток шота (стоп-лосс в BI)
    ///
    /// - Parameter value: Количество BI (не меньше 1)
    func setShotAttempts(_ value: Int) {
        shotAttempts = max(1, value)
        evaluateShotStopLossIfNeeded()
        persistBankrollSettings()
    }

    /// Обновляет порог warning для усталости в минутах
    ///
    /// - Parameter value: Новый порог warning
    func setFatigueWarningMinutes(_ value: Int) {
        let warning = min(max(minFatigueWarningMinutes, value), maxFatigueWarningMinutes)
        fatigueWarningMinutes = warning

        if fatigueCriticalMinutes <= warning {
            fatigueCriticalMinutes = min(maxFatigueCriticalMinutes, warning + 1)
        }

        checkFatigue()
        persistBankrollSettings()
    }

    /// Обновляет порог critical для усталости в минутах
    ///
    /// - Parameter value: Новый порог critical
    func setFatigueCriticalMinutes(_ value: Int) {
        let critical = min(
            max(fatigueWarningMinutes + 1, value),
            maxFatigueCriticalMinutes
        )
        fatigueCriticalMinutes = max(minFatigueCriticalMinutes, critical)
        checkFatigue()
        persistBankrollSettings()
    }

    /// Обновляет границы диапазонов нижнего индикатора
    ///
    /// - Parameters:
    ///   - lowUpperBound: Верхняя граница нижнего диапазона (минимум 1)
    ///   - midUpperBound: Верхняя граница среднего диапазона (должна быть больше lowUpperBound)
    func setRandomizerRangeBoundaries(lowUpperBound: Int, midUpperBound: Int) {
        let low = min(max(1, lowUpperBound), 97)
        let mid = min(max(low + 1, midUpperBound), 98)

        randomizerLowUpperBound = low
        randomizerMidUpperBound = mid
        updateBarColor(for: state.currentNumber)
        persistBankrollSettings()
    }

    /// Обновляет stop-loss текущей сессии в долларах
    ///
    /// - Parameter value: Лимит убытка (0 = выключен)
    func setSessionStopLossUSD(_ value: Double) {
        sessionStopLossUSD = max(0, value)
        evaluateSessionLimitsIfNeeded()
        persistBankrollSettings()
    }

    /// Включает/выключает жёсткий режим stop-loss с перерывом
    ///
    /// - Parameter value: `true`, если режим должен быть включён
    func setHardStopLossEnabled(_ value: Bool) {
        hardStopLossEnabled = value

        if !value {
            stopLossBlockUntil = nil
        }

        persistBankrollSettings()
    }

    /// Обновляет длительность перерыва по жёсткому stop-loss
    ///
    /// - Parameter value: Перерыв в минутах (минимум 1)
    func setHardStopLossBreakMinutes(_ value: Int) {
        hardStopLossBreakMinutes = max(1, value)
        persistBankrollSettings()
    }

    /// Обновляет stop-win текущей сессии в долларах
    ///
    /// - Parameter value: Лимит прибыли (0 = выключен)
    func setSessionStopWinUSD(_ value: Double) {
        sessionStopWinUSD = max(0, value)
        evaluateSessionLimitsIfNeeded()
        persistBankrollSettings()
    }

    /// Увеличивает количество попыток шота (BI) на 1
    func incrementShotAttempts() {
        setShotAttempts(shotAttempts + 1)
    }

    /// Уменьшает количество попыток шота (BI) на 1 (не ниже 1)
    func decrementShotAttempts() {
        setShotAttempts(max(1, shotAttempts - 1))
    }

    /// Инициирует запрос разрешения на локальные уведомления
    ///
    /// Вызывается из UI после появления окна, чтобы системный prompt
    /// показывался в корректном контексте активного приложения.
    func requestNotificationAuthorization() {
        requestNotificationAuthorizationIfNeeded()
    }

    /// Добавляет новую запись в журнал шотов
    ///
    /// - Parameters:
    ///   - resultUSD: Результат сессии шота в долларах (может быть отрицательным)
    ///   - comment: Комментарий к записи
    ///   - applyToBankroll: Применять ли результат к текущему банкроллу
    func addShotJournalEntry(resultUSD: Double, comment: String, applyToBankroll: Bool) {
        guard resultUSD.isFinite else { return }

        let limit = max(1, shotLimitNL)
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        if applyToBankroll {
            setCurrentBankrollUSD(currentBankrollUSD + resultUSD)
        }

        if !isShotLocked {
            currentShotResultUSD += resultUSD
            evaluateShotStopLossIfNeeded()
        }

        sessionResultUSD += resultUSD
        evaluateSessionLimitsIfNeeded()
        persistBankrollSettings()

        let entry = ShotJournalEntry(
            id: UUID(),
            date: Date(),
            limitNL: limit,
            sessionDurationSeconds: Int(state.sessionDuration),
            resultUSD: resultUSD,
            resultBuyIns: resultUSD / Double(limit),
            applyToBankroll: applyToBankroll,
            bankrollAfterUSD: currentBankrollUSD,
            comment: trimmedComment
        )

        shotJournalEntries.insert(entry, at: 0)
        persistShotJournal()
    }

    // MARK: - Private Methods

    /// Обновляет цвет полосок рейтинга в зависимости от числа
    ///
    /// - Parameter number: Сгенерированное число (1-99)
    ///
    /// Логика окрашивания:
    /// - **0-lowUpperBound**: сероватый
    /// - **lowUpperBound+1-midUpperBound**: светло-серо-голубой
    /// - **midUpperBound+1-99**: почти белый
    private func updateBarColor(for number: Int) {
        switch randomizerSegment(for: number) {
        case 1:
            barColor = Color(red: 0.45, green: 0.48, blue: 0.53) // ~#737A87
        case 2:
            barColor = Color(red: 0.72, green: 0.78, blue: 0.86) // ~#B8C7DB
        default:
            barColor = Color(red: 0.95, green: 0.97, blue: 0.99) // ~#F2F7FC
        }
    }

    /// Возвращает сегмент нижнего индикатора для заданного числа (1...3)
    private func randomizerSegment(for number: Int) -> Int {
        if number <= randomizerLowUpperBound {
            return 1
        }

        if number <= randomizerMidUpperBound {
            return 2
        }

        return 3
    }

    /// Загружает параметры банкролла и шота из JSON-файла в Documents
    private func loadBankrollSettings() {
        do {
            let settings: BankrollSettingsFileModel
            let decoder = Self.makeJSONDecoder()

            if FileManager.default.fileExists(atPath: bankrollSettingsFileURL.path) {
                let data = try Data(contentsOf: bankrollSettingsFileURL)
                settings = try decoder.decode(BankrollSettingsFileModel.self, from: data)
            } else {
                settings = .defaults
            }

            applyBankrollSettings(settings)
            normalizeSessionLimitsAfterLoad()
            evaluateAutoUnlockIfNeeded()
            evaluateSessionLimitsIfNeeded()
            updateBarColor(for: state.currentNumber)
            persistBankrollSettings()
        } catch {
            applyBankrollSettings(.defaults)
            normalizeSessionLimitsAfterLoad()
            evaluateAutoUnlockIfNeeded()
            evaluateSessionLimitsIfNeeded()
            updateBarColor(for: state.currentNumber)
            persistBankrollSettings()
        }
    }

    /// Сохраняет параметры банкролла и шота в JSON-файл в Documents
    private func persistBankrollSettings() {
        do {
            try ensureBankrollStorageDirectoryExists()
            let data = try Self.makeJSONEncoder().encode(currentBankrollSettings())
            try data.write(to: bankrollSettingsFileURL, options: .atomic)
        } catch {
            // Если запись не удалась, оставляем текущее состояние в памяти
        }
    }

    /// Загружает журнал шотов из JSON-файла в Documents
    private func loadShotJournal() {
        do {
            let decoder = Self.makeJSONDecoder()

            if FileManager.default.fileExists(atPath: shotJournalFileURL.path) {
                let data = try Data(contentsOf: shotJournalFileURL)
                shotJournalEntries = try decoder.decode([ShotJournalEntry].self, from: data)
            } else {
                shotJournalEntries = []
            }

            persistShotJournal()
        } catch {
            shotJournalEntries = []
            persistShotJournal()
        }
    }

    /// Сохраняет журнал шотов в JSON-файл в Documents
    private func persistShotJournal() {
        do {
            try ensureBankrollStorageDirectoryExists()
            let data = try Self.makeJSONEncoder().encode(shotJournalEntries)
            try data.write(to: shotJournalFileURL, options: .atomic)
        } catch {
            // Если запись не удалась, оставляем текущее состояние в памяти
        }
    }

    /// Проверяет достижение стоп-лосса шота (-N BI) и блокирует шот при необходимости
    private func evaluateShotStopLossIfNeeded() {
        guard !isShotLocked else { return }
        guard shotBudget > 0 else { return }

        if currentShotResultUSD <= -shotBudget {
            isShotLocked = true
            notificationService.postNotification(
                id: "shot-stoploss-\(UUID().uuidString)",
                title: "Игра запрещена по stop-loss",
                body: "Шот NL\(shotLimitNL) закрыт после -\(shotAttempts) BI."
            )
        }
    }

    /// Проверяет stop-loss / stop-win текущей сессии и при необходимости блокирует игру
    private func evaluateSessionLimitsIfNeeded() {
        guard sessionLimitReason == nil else { return }

        if sessionStopLossUSD > 0, sessionResultUSD <= -sessionStopLossUSD {
            sessionLimitReason = .stopLoss
            if hardStopLossEnabled {
                let breakSeconds = TimeInterval(hardStopLossBreakMinutes * 60)
                stopLossBlockUntil = currentDateProvider().addingTimeInterval(breakSeconds)
                notificationService.postNotification(
                    id: "session-stoploss-\(UUID().uuidString)",
                    title: "Игра запрещена по stop-loss",
                    body: "Лимит сессии достигнут: \(formatSignedAmount(sessionResultUSD))$. Перерыв \(hardStopLossBreakMinutes) мин."
                )
            } else {
                notificationService.postNotification(
                    id: "session-stoploss-\(UUID().uuidString)",
                    title: "Игра запрещена по stop-loss",
                    body: "Лимит сессии достигнут: \(formatSignedAmount(sessionResultUSD))$."
                )
            }
            return
        }

        if sessionStopWinUSD > 0, sessionResultUSD >= sessionStopWinUSD {
            sessionLimitReason = .stopWin
            notificationService.postNotification(
                id: "session-stopwin-\(UUID().uuidString)",
                title: "Stop-win достигнут",
                body: "Зафиксирован результат сессии: \(formatSignedAmount(sessionResultUSD))$."
            )
        }
    }

    /// Проверяет окончание перерыва по жёсткому stop-loss и разблокирует сессию
    private func handleHardStopLossBreakIfNeeded() {
        guard let stopLossBlockUntil else { return }
        guard currentDateProvider() >= stopLossBlockUntil else { return }

        self.stopLossBlockUntil = nil

        guard sessionLimitReason == .stopLoss else {
            persistBankrollSettings()
            return
        }

        sessionLimitReason = nil
        sessionResultUSD = 0
        notificationService.postNotification(
            id: "session-stoploss-break-end-\(UUID().uuidString)",
            title: "Перерыв завершён",
            body: "Можно продолжать игру."
        )
        persistBankrollSettings()
    }

    /// Запрашивает разрешение на локальные уведомления macOS
    private func requestNotificationAuthorizationIfNeeded() {
        notificationService.requestAuthorizationIfNeeded { _ in
            // Результат не блокирует работу приложения.
        }
    }

    /// Отправляет уведомление при переходе в состояние усталости
    private func notifyFatigueTransition(from oldState: SessionFatigueState, to newState: SessionFatigueState) {
        guard oldState != newState else { return }

        switch newState {
        case .normal:
            break
        case .warning:
            notificationService.postNotification(
                id: "fatigue-warning-\(UUID().uuidString)",
                title: "Пора отдохнуть",
                body: "Сессия длится долго. Сделайте короткий перерыв."
            )
        case .critical:
            notificationService.postNotification(
                id: "fatigue-critical-\(UUID().uuidString)",
                title: "Нужен перерыв",
                body: "Достигнут критический порог времени сессии."
            )
        }
    }

    private func formatSignedAmount(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        let sign = rounded >= 0 ? "+" : ""

        if rounded == rounded.rounded() {
            return "\(sign)\(Int(rounded))"
        }

        if (rounded * 10).rounded() == rounded * 10 {
            return "\(sign)\(String(format: "%.1f", rounded))"
        }

        return "\(sign)\(String(format: "%.2f", rounded))"
    }

    /// Нормализует состояние лимитов сессии после загрузки из JSON
    private func normalizeSessionLimitsAfterLoad() {
        guard hardStopLossEnabled else {
            stopLossBlockUntil = nil
            return
        }

        guard sessionLimitReason == .stopLoss else {
            stopLossBlockUntil = nil
            return
        }

        guard let stopLossBlockUntil else { return }

        if currentDateProvider() >= stopLossBlockUntil {
            self.stopLossBlockUntil = nil
            sessionLimitReason = nil
            sessionResultUSD = 0
        }
    }

    /// Автоматически снимает блокировку шота после восстановления до порога в BI
    private func evaluateAutoUnlockIfNeeded() {
        guard isShotLocked else { return }

        if currentBankrollUSD >= requiredBankrollForShot {
            isShotLocked = false
            currentShotResultUSD = 0
        }
    }

    /// Применяет значения настроек с валидацией границ
    private func applyBankrollSettings(_ settings: BankrollSettingsFileModel) {
        currentBankrollUSD = max(0, settings.currentBankrollUSD)
        shotLimitNL = max(1, settings.shotLimitNL)
        shotBankrollThresholdBuyIns = max(1, settings.shotBankrollThresholdBuyIns)
        shotAttempts = max(1, settings.shotAttempts)
        let warning = min(max(minFatigueWarningMinutes, settings.fatigueWarningMinutes), maxFatigueWarningMinutes)
        let critical = min(
            max(warning + 1, settings.fatigueCriticalMinutes),
            maxFatigueCriticalMinutes
        )
        fatigueWarningMinutes = warning
        fatigueCriticalMinutes = max(minFatigueCriticalMinutes, critical)
        let low = min(max(1, settings.randomizerLowUpperBound), 97)
        let mid = min(max(low + 1, settings.randomizerMidUpperBound), 98)
        randomizerLowUpperBound = low
        randomizerMidUpperBound = mid
        currentShotResultUSD = settings.currentShotResultUSD
        isShotLocked = settings.isShotLocked
        sessionStopLossUSD = max(0, settings.sessionStopLossUSD)
        hardStopLossEnabled = settings.hardStopLossEnabled
        hardStopLossBreakMinutes = max(1, settings.hardStopLossBreakMinutes)
        stopLossBlockUntil = settings.stopLossBlockUntil
        sessionStopWinUSD = max(0, settings.sessionStopWinUSD)
        sessionResultUSD = settings.sessionResultUSD
        sessionLimitReason = settings.sessionLimitReason.flatMap { SessionLimitReason(rawValue: $0) }
    }

    /// Формирует текущую модель для сохранения в JSON
    private func currentBankrollSettings() -> BankrollSettingsFileModel {
        BankrollSettingsFileModel(
            currentBankrollUSD: currentBankrollUSD,
            shotLimitNL: shotLimitNL,
            shotBankrollThresholdBuyIns: shotBankrollThresholdBuyIns,
            shotAttempts: shotAttempts,
            fatigueWarningMinutes: fatigueWarningMinutes,
            fatigueCriticalMinutes: fatigueCriticalMinutes,
            randomizerLowUpperBound: randomizerLowUpperBound,
            randomizerMidUpperBound: randomizerMidUpperBound,
            currentShotResultUSD: currentShotResultUSD,
            isShotLocked: isShotLocked,
            sessionStopLossUSD: sessionStopLossUSD,
            hardStopLossEnabled: hardStopLossEnabled,
            hardStopLossBreakMinutes: hardStopLossBreakMinutes,
            stopLossBlockUntil: stopLossBlockUntil,
            sessionStopWinUSD: sessionStopWinUSD,
            sessionResultUSD: sessionResultUSD,
            sessionLimitReason: sessionLimitReason?.rawValue
        )
    }

    /// Создаёт каталог Documents/Randomizer при необходимости
    private func ensureBankrollStorageDirectoryExists() throws {
        let directory = Self.defaultStorageDirectoryURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// URL файла настроек по умолчанию: ~/Documents/Randomizer/settings.json
    private static func defaultBankrollSettingsFileURL() -> URL {
        defaultStorageDirectoryURL()
            .appendingPathComponent("settings.json", isDirectory: false)
    }

    /// URL файла журнала шотов по умолчанию: ~/Documents/Randomizer/shot_journal.json
    private static func defaultShotJournalFileURL() -> URL {
        defaultStorageDirectoryURL()
            .appendingPathComponent("shot_journal.json", isDirectory: false)
    }

    /// Каталог хранения JSON-файлов: ~/Documents/Randomizer
    private static func defaultStorageDirectoryURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Randomizer", isDirectory: true)
    }

    /// Настроенный JSONEncoder (читаемый JSON + ISO8601 даты)
    private static func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    /// Настроенный JSONDecoder (ISO8601 даты)
    private static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

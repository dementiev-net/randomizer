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
enum SessionFatigueState: Equatable {
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

    /// Порог банкролла для шота в бай-инах (например, 25 BI)
    @Published private(set) var shotBankrollThresholdBuyIns: Int = 25

    /// Количество попыток шота в BI (стоп-лосс = -N BI)
    @Published private(set) var shotAttempts: Int = 2

    /// Накопленный результат текущего шота в долларах
    @Published private(set) var currentShotResultUSD: Double = 0

    /// Флаг блокировки шота после достижения стоп-лосса
    @Published private(set) var isShotLocked: Bool = false

    /// Журнал шотов (новые записи в начале списка)
    @Published private(set) var shotJournalEntries: [ShotJournalEntry] = []

    // MARK: - Private Properties

    /// Порог предупреждения о длительной работе (55 минут)
    private let warningThreshold: TimeInterval = 55 * 60

    /// Порог критической усталости (60 минут)
    private let criticalThreshold: TimeInterval = 60 * 60

    /// Сервис генерации случайных чисел и расчёта рейтинга
    private let service: RandomizerServiceProtocol

    /// Персистентное хранилище общего времени
    private let defaults: UserDefaults

    /// Сервис локальных уведомлений macOS
    private let notificationService: NotificationServiceProtocol

    /// Ключ сохранения общего времени использования
    private let allTimeDurationKey = "allTimeDuration"

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
    ///   - defaults: Хранилище для персистентного общего времени
    ///   - bankrollSettingsFileURL: URL JSON-файла настроек банкролла
    ///   - shotJournalFileURL: URL JSON-файла журнала шотов
    ///
    /// Автоматически восстанавливает общее время и генерирует первое число.
    init(
        service: RandomizerServiceProtocol = RandomizerService(),
        notificationService: NotificationServiceProtocol = NoopNotificationService(),
        autoStartTimer: Bool = true,
        defaults: UserDefaults = .standard,
        bankrollSettingsFileURL: URL? = nil,
        shotJournalFileURL: URL? = nil
    ) {
        self.service = service
        self.notificationService = notificationService
        self.defaults = defaults
        self.bankrollSettingsFileURL = bankrollSettingsFileURL ?? Self.defaultBankrollSettingsFileURL()
        self.shotJournalFileURL = shotJournalFileURL ?? Self.defaultShotJournalFileURL()

        requestNotificationAuthorizationIfNeeded()
        state.allTimeDuration = defaults.double(forKey: allTimeDurationKey)
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

    /// Увеличивает количество попыток шота (BI) на 1
    func incrementShotAttempts() {
        setShotAttempts(shotAttempts + 1)
    }

    /// Уменьшает количество попыток шота (BI) на 1 (не ниже 1)
    func decrementShotAttempts() {
        setShotAttempts(max(1, shotAttempts - 1))
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
            persistBankrollSettings()
        }

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
            evaluateAutoUnlockIfNeeded()
            persistBankrollSettings()
        } catch {
            applyBankrollSettings(.defaults)
            evaluateAutoUnlockIfNeeded()
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
        currentShotResultUSD = settings.currentShotResultUSD
        isShotLocked = settings.isShotLocked
    }

    /// Формирует текущую модель для сохранения в JSON
    private func currentBankrollSettings() -> BankrollSettingsFileModel {
        BankrollSettingsFileModel(
            currentBankrollUSD: currentBankrollUSD,
            shotLimitNL: shotLimitNL,
            shotBankrollThresholdBuyIns: shotBankrollThresholdBuyIns,
            shotAttempts: shotAttempts,
            currentShotResultUSD: currentShotResultUSD,
            isShotLocked: isShotLocked
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

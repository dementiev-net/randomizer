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

    /// Флаг отображения настроек банкролла
    @State private var isBankrollSettingsPresented = false

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
                        Button(action: viewModel.resetSession) {
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

                Divider().background(Color.white.opacity(0.1))

                // Строка статуса шота верхнего лимита
                HStack {
                    Text("Шот NL\(viewModel.shotLimitNL)")
                        .foregroundColor(.gray)

                    Spacer()

                    HStack(spacing: 6) {
                        Text(
                            viewModel.isShotLocked ?
                            "ШОТ ЗАКРЫТ" :
                            viewModel.isShotAvailable ?
                            "ГОТОВ (\(formatBuyIns(viewModel.bankrollReserveForShotInBuyIns)) BI)" :
                            "нужно $\(formatAmount(viewModel.missingBankrollForShot))"
                        )
                            .foregroundColor(
                                viewModel.isShotLocked ?
                                .red :
                                (viewModel.isShotAvailable ? .green : .orange)
                            )
                            .lineLimit(1)

                        Button {
                            isBankrollSettingsPresented = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: 16, height: 14)
                        }
                        .buttonStyle(.plain)
                        .help("Настройки банкролла")
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .default))
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .background(Color.black.opacity(0.01)) // Делает весь фон кликабельным
        .sheet(isPresented: $isBankrollSettingsPresented) {
            BankrollSettingsSheet(viewModel: viewModel)
        }
        .onTapGesture {
            // Тактильная обратная связь
            let generator = NSHapticFeedbackManager.defaultPerformer
            generator.perform(.alignment, performanceTime: .now)

            // Генерация нового числа
            viewModel.generateNewData()
        }
    }

    /// Форматирует денежное значение до целого без дробной части
    private func formatAmount(_ value: Double) -> String {
        String(Int(value.rounded(.up)))
    }

    /// Форматирует количество бай-инов (до 2 знаков после запятой)
    private func formatBuyIns(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100

        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }

        if (rounded * 10).rounded() == rounded * 10 {
            return String(format: "%.1f", rounded)
        }

        return String(format: "%.2f", rounded)
    }
}

// MARK: - Bankroll Settings Sheet

private struct BankrollSettingsSheet: View {

    /// Общая ViewModel приложения
    @ObservedObject var viewModel: RandomizerView

    /// Закрытие sheet окна
    @Environment(\.dismiss) private var dismiss

    /// Текстовое значение банкролла для свободного редактирования
    @State private var bankrollText = ""

    /// Текстовое значение лимита шота для свободного редактирования
    @State private var shotLimitText = ""

    /// Текстовое значение результата записи журнала в долларах
    @State private var shotResultText = ""

    /// Текст комментария для записи журнала
    @State private var shotCommentText = ""

    /// Признак применения результата записи к текущему банкроллу
    @State private var applyShotResultToBankroll = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Настройки банкролла")
                    .font(.system(size: 16, weight: .semibold))

                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Банкролл, $")
                            .foregroundColor(.gray)

                        TextField(
                            "0",
                            text: $bankrollText
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .onChange(of: bankrollText) { _, newValue in
                            handleBankrollInputChange(newValue)
                        }
                        .onSubmit {
                            commitBankrollInput()
                        }
                    }

                    GridRow {
                        Text("Лимит шота")
                            .foregroundColor(.gray)

                        HStack(spacing: 4) {
                            Text("NL")
                            TextField(
                                "25",
                                text: $shotLimitText
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .onChange(of: shotLimitText) { _, newValue in
                                handleShotLimitInputChange(newValue)
                            }
                            .onSubmit {
                                commitShotLimitInput()
                            }
                        }
                    }

                    GridRow {
                        Text("Попытки шота, BI")
                            .foregroundColor(.gray)

                        Stepper(
                            value: Binding(
                                get: { viewModel.shotAttempts },
                                set: { viewModel.setShotAttempts($0) }
                            ),
                            in: 1...999
                        ) {
                            Text("\(viewModel.shotAttempts)")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .leading)
                        }
                        .frame(width: 140, alignment: .leading)
                    }

                    GridRow {
                        Text("Порог шота, BI")
                            .foregroundColor(.gray)

                        Stepper(
                            value: Binding(
                                get: { viewModel.shotBankrollThresholdBuyIns },
                                set: { viewModel.setShotBankrollThresholdBuyIns($0) }
                            ),
                            in: 1...999
                        ) {
                            Text("\(viewModel.shotBankrollThresholdBuyIns)")
                                .monospacedDigit()
                                .frame(minWidth: 40, alignment: .leading)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 5) {
                    Text("Порог шота (\(viewModel.shotBankrollThresholdBuyIns) BI): $\(formatAmount(viewModel.requiredBankrollForShot))")
                    Text("Бюджет шота (\(viewModel.shotAttempts) BI): $\(formatAmount(viewModel.shotBudget))")
                    Text(
                        "Текущий шот: \(formatSignedAmount(viewModel.currentShotResultUSD))$ " +
                        "(\(formatSignedBuyIns(viewModel.currentShotResultBuyIns)) BI)"
                    )
                    Text(
                        viewModel.isShotLocked ?
                        "Шот закрыт после -\(viewModel.shotAttempts) BI. Восстановите банкролл до $\(formatAmount(viewModel.requiredBankrollForShot))." :
                        viewModel.isShotAvailable ?
                        "Банкролл позволяет делать шот NL\(viewModel.shotLimitNL)." :
                        "До шота NL\(viewModel.shotLimitNL) не хватает $\(formatAmount(viewModel.missingBankrollForShot))."
                    )
                    .foregroundColor(
                        viewModel.isShotLocked ?
                        .red :
                        (viewModel.isShotAvailable ? .green : .orange)
                    )
                    .fontWeight(.semibold)
                }
                .font(.system(size: 12))

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Журнал шотов")
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 8) {
                        Button("-1 BI") { setShotResultFromBuyIns(-1) }
                        Button("-0.5 BI") { setShotResultFromBuyIns(-0.5) }
                        Button("+1 BI") { setShotResultFromBuyIns(1) }
                    }
                    .buttonStyle(.bordered)

                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 8) {
                        GridRow {
                            Text("Результат, $")
                                .foregroundColor(.gray)

                            TextField(
                                "0",
                                text: $shotResultText
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                            .onChange(of: shotResultText) { _, newValue in
                                handleShotResultInputChange(newValue)
                            }
                        }

                        GridRow {
                            Text("Комментарий")
                                .foregroundColor(.gray)

                            TextField("опционально", text: $shotCommentText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 220)
                        }
                    }

                    Toggle("Применить к банкроллу", isOn: $applyShotResultToBankroll)
                        .toggleStyle(.checkbox)

                    HStack {
                        Spacer()
                        Button("Записать") {
                            commitShotJournalEntry()
                        }
                        .disabled(!canCommitShotJournalEntry)
                    }

                    if viewModel.shotJournalEntries.isEmpty {
                        Text("Записей пока нет")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(viewModel.shotJournalEntries.prefix(5))) { entry in
                                ShotJournalEntryRow(entry: entry)
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Готово") {
                        commitBankrollInput()
                        commitShotLimitInput()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
        }
        .frame(width: 380, height: 560)
        .onAppear {
            bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
            shotLimitText = String(viewModel.shotLimitNL)
            shotResultText = ""
            shotCommentText = ""
            applyShotResultToBankroll = true
        }
    }

    /// Форматирует денежное значение до целого без дробной части
    private func formatAmount(_ value: Double) -> String {
        String(Int(value.rounded(.up)))
    }

    /// Форматирует число со знаком и без лишних нулей
    private func formatSignedAmount(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        let rounded = (value * 100).rounded() / 100

        if rounded == rounded.rounded() {
            return "\(sign)\(Int(rounded))"
        }

        if (rounded * 10).rounded() == rounded * 10 {
            return "\(sign)\(String(format: "%.1f", rounded))"
        }

        return "\(sign)\(String(format: "%.2f", rounded))"
    }

    /// Форматирует количество бай-инов со знаком и без лишних нулей
    private func formatSignedBuyIns(_ value: Double) -> String {
        formatSignedAmount(value)
    }

    /// Форматирует число для редактируемого текстового поля
    private func formatEditableAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }

        return String(value)
    }

    /// Обрабатывает ручной ввод банкролла без принудительного восстановления старого числа
    private func handleBankrollInputChange(_ newValue: String) {
        let sanitized = sanitizeDecimalInput(newValue)
        guard sanitized == newValue else {
            bankrollText = sanitized
            return
        }

        guard !sanitized.isEmpty, let value = Double(sanitized) else {
            return
        }

        viewModel.setCurrentBankrollUSD(value)
    }

    /// Обрабатывает ручной ввод лимита шота без блокировки пустого значения
    private func handleShotLimitInputChange(_ newValue: String) {
        let sanitized = sanitizeIntegerInput(newValue)
        guard sanitized == newValue else {
            shotLimitText = sanitized
            return
        }

        guard !sanitized.isEmpty, let value = Int(sanitized) else {
            return
        }

        viewModel.setShotLimitNL(value)
    }

    /// Финализирует ввод банкролла при завершении редактирования
    private func commitBankrollInput() {
        let text = sanitizeDecimalInput(bankrollText)
        if text.isEmpty {
            viewModel.setCurrentBankrollUSD(0)
            bankrollText = "0"
            return
        }

        guard let value = Double(text) else {
            bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
            return
        }

        viewModel.setCurrentBankrollUSD(value)
        bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
    }

    /// Финализирует ввод лимита шота при завершении редактирования
    private func commitShotLimitInput() {
        let text = sanitizeIntegerInput(shotLimitText)
        if text.isEmpty {
            shotLimitText = String(viewModel.shotLimitNL)
            return
        }

        guard let value = Int(text) else {
            shotLimitText = String(viewModel.shotLimitNL)
            return
        }

        viewModel.setShotLimitNL(value)
        shotLimitText = String(viewModel.shotLimitNL)
    }

    /// Можно ли сохранить запись журнала с текущим вводом
    private var canCommitShotJournalEntry: Bool {
        guard let value = parseSignedAmount(shotResultText) else { return false }
        return value != 0
    }

    /// Обрабатывает ручной ввод результата шота с поддержкой знака
    private func handleShotResultInputChange(_ newValue: String) {
        let sanitized = sanitizeSignedDecimalInput(newValue)
        guard sanitized == newValue else {
            shotResultText = sanitized
            return
        }
    }

    /// Устанавливает результат шота через количество бай-инов
    private func setShotResultFromBuyIns(_ buyIns: Double) {
        let value = buyIns * Double(viewModel.shotLimitNL)
        shotResultText = formatEditableAmount(value)
    }

    /// Сохраняет запись в журнал шотов
    private func commitShotJournalEntry() {
        guard let amount = parseSignedAmount(shotResultText), amount != 0 else { return }

        viewModel.addShotJournalEntry(
            resultUSD: amount,
            comment: shotCommentText,
            applyToBankroll: applyShotResultToBankroll
        )

        // После применения результата к банкроллу синхронизируем отображаемое поле.
        bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
        shotResultText = ""
        shotCommentText = ""
    }

    /// Разбирает текстовое значение суммы с поддержкой знака
    private func parseSignedAmount(_ input: String) -> Double? {
        let text = sanitizeSignedDecimalInput(input)
        guard !text.isEmpty, text != "-", text != "+", text != ".", text != "-.", text != "+." else {
            return nil
        }
        return Double(text)
    }

    /// Оставляет только цифры и один десятичный разделитель
    private func sanitizeDecimalInput(_ input: String) -> String {
        var result = ""
        var hasSeparator = false

        for character in input {
            if character.isNumber {
                result.append(character)
                continue
            }

            if (character == "." || character == ",") && !hasSeparator {
                result.append(".")
                hasSeparator = true
            }
        }

        return result
    }

    /// Оставляет знак, цифры и один десятичный разделитель
    private func sanitizeSignedDecimalInput(_ input: String) -> String {
        var result = ""
        var hasSeparator = false

        for character in input {
            if character == "-" || character == "+" {
                if result.isEmpty {
                    result.append(character)
                }
                continue
            }

            if character.isNumber {
                result.append(character)
                continue
            }

            if (character == "." || character == ",") && !hasSeparator {
                result.append(".")
                hasSeparator = true
            }
        }

        return result
    }

    /// Оставляет только цифры для целочисленного поля
    private func sanitizeIntegerInput(_ input: String) -> String {
        input.filter(\.isNumber)
    }
}

private struct ShotJournalEntryRow: View {

    /// Запись журнала для отображения
    let entry: ShotJournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(Self.dateFormatter.string(from: entry.date))
                    .foregroundColor(.gray)

                Text("NL\(entry.limitNL)")
                    .foregroundColor(.gray)

                Text(formattedResultUSD(entry.resultUSD))
                    .foregroundColor(entry.resultUSD >= 0 ? .green : .orange)
                    .fontWeight(.semibold)

                Text("(\(formattedBuyIns(entry.resultBuyIns)) BI)")
                    .foregroundColor(.gray)
            }
            .font(.system(size: 11))

            if !entry.comment.isEmpty {
                Text(entry.comment)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    /// Форматирует результат в долларах с знаком
    private func formattedResultUSD(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        let rounded = (value * 100).rounded() / 100

        if rounded == rounded.rounded() {
            return "\(sign)\(Int(rounded))$"
        }

        if (rounded * 10).rounded() == rounded * 10 {
            return "\(sign)\(String(format: "%.1f", rounded))$"
        }

        return "\(sign)\(String(format: "%.2f", rounded))$"
    }

    /// Форматирует количество бай-инов до 2 знаков
    private func formattedBuyIns(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100

        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }

        if (rounded * 10).rounded() == rounded * 10 {
            return String(format: "%.1f", rounded)
        }

        return String(format: "%.2f", rounded)
    }

    /// Форматтер даты/времени для строки журнала
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        return formatter
    }()
}

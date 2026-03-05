//
//  BankrollSettingsSheet.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

struct BankrollSettingsSheet: View {
    private let sheetWidth: CGFloat = 380
    private let sheetHeight: CGFloat = 520

    /// Общая ViewModel приложения
    @ObservedObject var viewModel: RandomizerView

    /// Закрытие sheet окна
    @Environment(\.dismiss) private var dismiss

    /// Открытие дополнительного окна приложения
    @Environment(\.openWindow) private var openWindow

    /// Текстовое значение банкролла для свободного редактирования
    @State private var bankrollText = ""

    /// Текстовое значение лимита шота для свободного редактирования
    @State private var shotLimitText = ""

    /// Текстовое значение stop-loss текущей сессии в долларах
    @State private var sessionStopLossText = ""

    /// Текстовое значение stop-win текущей сессии в долларах
    @State private var sessionStopWinText = ""

    /// Текстовое значение результата записи журнала в долларах
    @State private var shotResultText = ""

    /// Текст комментария для записи журнала
    @State private var shotCommentText = ""

    /// Признак применения результата записи к текущему банкроллу
    @State private var applyShotResultToBankroll = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Настройки банкролла")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button {
                    closeSheet()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Закрыть")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            Text("Банкролл, $")
                                .foregroundColor(.gray)

                            TextField("0", text: $bankrollText)
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
                                TextField("25", text: $shotLimitText)
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
                            Text("Шот, BI")
                                .foregroundColor(.gray)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Попытки")
                                        .font(.system(size: 11))
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
                                    .frame(width: 110, alignment: .leading)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Порог")
                                        .font(.system(size: 11))
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
                                    .frame(width: 110, alignment: .leading)
                                }
                            }
                        }

                        GridRow {
                            Text("Лимиты, $")
                                .foregroundColor(.gray)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stop-loss")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)

                                    TextField("0", text: $sessionStopLossText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 110)
                                        .onChange(of: sessionStopLossText) { _, newValue in
                                            handleSessionStopLossInputChange(newValue)
                                        }
                                        .onSubmit {
                                            commitSessionStopLossInput()
                                        }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stop-win")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)

                                    TextField("0", text: $sessionStopWinText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 110)
                                        .onChange(of: sessionStopWinText) { _, newValue in
                                            handleSessionStopWinInputChange(newValue)
                                        }
                                        .onSubmit {
                                            commitSessionStopWinInput()
                                        }
                                }
                            }
                        }

                        GridRow {
                            Text("Усталость, мин")
                                .foregroundColor(.gray)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Warning")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)

                                    Stepper(
                                        value: Binding(
                                            get: { viewModel.fatigueWarningMinutes },
                                            set: { viewModel.setFatigueWarningMinutes($0) }
                                        ),
                                        in: 1...1439
                                    ) {
                                        Text("\(viewModel.fatigueWarningMinutes)")
                                            .monospacedDigit()
                                            .frame(minWidth: 40, alignment: .leading)
                                    }
                                    .frame(width: 110, alignment: .leading)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Critical")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)

                                    Stepper(
                                        value: Binding(
                                            get: { viewModel.fatigueCriticalMinutes },
                                            set: { viewModel.setFatigueCriticalMinutes($0) }
                                        ),
                                        in: 2...1440
                                    ) {
                                        Text("\(viewModel.fatigueCriticalMinutes)")
                                            .monospacedDigit()
                                            .frame(minWidth: 40, alignment: .leading)
                                    }
                                    .frame(width: 110, alignment: .leading)
                                }
                            }
                        }

                        GridRow {
                            Text("Индикатор, %")
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Button("33/66") {
                                        viewModel.setRandomizerRangeBoundaries(lowUpperBound: 33, midUpperBound: 66)
                                    }
                                    Button("25/75") {
                                        viewModel.setRandomizerRangeBoundaries(lowUpperBound: 25, midUpperBound: 75)
                                    }
                                    Button("20/80") {
                                        viewModel.setRandomizerRangeBoundaries(lowUpperBound: 20, midUpperBound: 80)
                                    }
                                }
                                .buttonStyle(.bordered)

                                RangeBoundsSlider(
                                    minimumValue: 1,
                                    maximumValue: 98,
                                    lowerValue: viewModel.randomizerLowUpperBound,
                                    upperValue: viewModel.randomizerMidUpperBound
                                ) { lower, upper in
                                    viewModel.setRandomizerRangeBoundaries(
                                        lowUpperBound: lower,
                                        midUpperBound: upper
                                    )
                                }
                                .frame(width: 220)
                            }
                        }

                        GridRow {
                            Text("Жесткий stop-loss")
                                .foregroundColor(.gray)

                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(
                                    "Включен",
                                    isOn: Binding(
                                        get: { viewModel.hardStopLossEnabled },
                                        set: { viewModel.setHardStopLossEnabled($0) }
                                    )
                                )
                                .toggleStyle(.switch)

                                if viewModel.hardStopLossEnabled {
                                    Stepper(
                                        value: Binding(
                                            get: { viewModel.hardStopLossBreakMinutes },
                                            set: { viewModel.setHardStopLossBreakMinutes($0) }
                                        ),
                                        in: 1...180
                                    ) {
                                        Text("Перерыв: \(viewModel.hardStopLossBreakMinutes) мин")
                                            .monospacedDigit()
                                    }
                                    .frame(width: 220, alignment: .leading)
                                }

                                if viewModel.isHardStopLossBreakActive {
                                    Text("Осталось: \(viewModel.hardStopLossBreakRemainingText)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
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
                            "Результат сессии: \(formatSignedAmount(viewModel.sessionResultUSD))$"
                        )
                        Text(
                            "Лимиты сессии: stop-loss \(formatAmount(viewModel.sessionStopLossUSD))$ / " +
                            "stop-win \(formatAmount(viewModel.sessionStopWinUSD))$"
                        )
                        Text(
                            "Усталость: warning \(viewModel.fatigueWarningMinutes) мин / " +
                            "critical \(viewModel.fatigueCriticalMinutes) мин"
                        )
                        Text(
                            "Индикатор: 0-\(viewModel.randomizerLowUpperBound) / " +
                            "\(viewModel.randomizerLowUpperBound + 1)-\(viewModel.randomizerMidUpperBound) / " +
                            "\(viewModel.randomizerMidUpperBound + 1)-99"
                        )
                        if viewModel.hardStopLossEnabled {
                            Text("Жесткий stop-loss: \(viewModel.hardStopLossBreakMinutes) мин")
                        }
                        if viewModel.isHardStopLossBreakActive {
                            Text("Перерыв по stop-loss: \(viewModel.hardStopLossBreakRemainingText)")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                        Text(
                            viewModel.isShotLocked
                            ? "Шот закрыт после -\(viewModel.shotAttempts) BI. Восстановите банкролл до $\(formatAmount(viewModel.requiredBankrollForShot))."
                            : viewModel.isShotAvailable
                            ? "Банкролл позволяет делать шот NL\(viewModel.shotLimitNL)."
                            : "До шота NL\(viewModel.shotLimitNL) не хватает $\(formatAmount(viewModel.missingBankrollForShot))."
                        )
                        .foregroundColor(
                            viewModel.isShotLocked
                            ? .red
                            : (viewModel.isShotAvailable ? .green : .orange)
                        )
                        .fontWeight(.semibold)
                        Text(sessionLimitStatusText)
                            .foregroundColor(sessionLimitStatusColor)
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

                                TextField("0", text: $shotResultText)
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
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }

            Divider()

            HStack(spacing: 8) {
                Spacer()
                Button {
                    closeSheet(openJournal: true)
                } label: {
                    Label("Журнал", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.bordered)
                .help("Показать журнал")
                Button("Записать") {
                    commitShotJournalEntry()
                }
                .disabled(!canCommitShotJournalEntry)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: sheetWidth, height: sheetHeight)
        .background(
            FixedSheetWindowConfigurator(
                width: sheetWidth,
                height: sheetHeight
            )
        )
        .onAppear {
            bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
            shotLimitText = String(viewModel.shotLimitNL)
            sessionStopLossText = formatEditableAmount(viewModel.sessionStopLossUSD)
            sessionStopWinText = formatEditableAmount(viewModel.sessionStopWinUSD)
            shotResultText = ""
            shotCommentText = ""
            applyShotResultToBankroll = true
        }
    }

    private func formatAmount(_ value: Double) -> String {
        String(Int(value.rounded(.up)))
    }

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

    private func formatSignedBuyIns(_ value: Double) -> String {
        formatSignedAmount(value)
    }

    private func formatEditableAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }

        return String(value)
    }

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

    private func handleSessionStopLossInputChange(_ newValue: String) {
        let sanitized = sanitizeDecimalInput(newValue)
        guard sanitized == newValue else {
            sessionStopLossText = sanitized
            return
        }

        guard !sanitized.isEmpty else {
            viewModel.setSessionStopLossUSD(0)
            return
        }

        guard let value = Double(sanitized) else { return }
        viewModel.setSessionStopLossUSD(value)
    }

    private func handleSessionStopWinInputChange(_ newValue: String) {
        let sanitized = sanitizeDecimalInput(newValue)
        guard sanitized == newValue else {
            sessionStopWinText = sanitized
            return
        }

        guard !sanitized.isEmpty else {
            viewModel.setSessionStopWinUSD(0)
            return
        }

        guard let value = Double(sanitized) else { return }
        viewModel.setSessionStopWinUSD(value)
    }

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

    private func commitSessionStopLossInput() {
        let text = sanitizeDecimalInput(sessionStopLossText)
        guard !text.isEmpty else {
            viewModel.setSessionStopLossUSD(0)
            sessionStopLossText = "0"
            return
        }

        guard let value = Double(text) else {
            sessionStopLossText = formatEditableAmount(viewModel.sessionStopLossUSD)
            return
        }

        viewModel.setSessionStopLossUSD(value)
        sessionStopLossText = formatEditableAmount(viewModel.sessionStopLossUSD)
    }

    private func commitSessionStopWinInput() {
        let text = sanitizeDecimalInput(sessionStopWinText)
        guard !text.isEmpty else {
            viewModel.setSessionStopWinUSD(0)
            sessionStopWinText = "0"
            return
        }

        guard let value = Double(text) else {
            sessionStopWinText = formatEditableAmount(viewModel.sessionStopWinUSD)
            return
        }

        viewModel.setSessionStopWinUSD(value)
        sessionStopWinText = formatEditableAmount(viewModel.sessionStopWinUSD)
    }

    private var canCommitShotJournalEntry: Bool {
        guard let value = parseSignedAmount(shotResultText) else { return false }
        return value != 0
    }

    private func handleShotResultInputChange(_ newValue: String) {
        let sanitized = sanitizeSignedDecimalInput(newValue)
        guard sanitized == newValue else {
            shotResultText = sanitized
            return
        }
    }

    private func setShotResultFromBuyIns(_ buyIns: Double) {
        let value = buyIns * Double(viewModel.shotLimitNL)
        shotResultText = formatEditableAmount(value)
    }

    private func commitShotJournalEntry() {
        // Гарантируем, что лимиты применены даже если поле еще в фокусе.
        commitSessionStopLossInput()
        commitSessionStopWinInput()

        guard let amount = parseSignedAmount(shotResultText), amount != 0 else { return }

        viewModel.addShotJournalEntry(
            resultUSD: amount,
            comment: shotCommentText,
            applyToBankroll: applyShotResultToBankroll
        )

        bankrollText = formatEditableAmount(viewModel.currentBankrollUSD)
        shotResultText = ""
        shotCommentText = ""
    }

    private func parseSignedAmount(_ input: String) -> Double? {
        let text = sanitizeSignedDecimalInput(input)
        guard !text.isEmpty, text != "-", text != "+", text != ".", text != "-.", text != "+." else {
            return nil
        }
        return Double(text)
    }

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

    private func sanitizeIntegerInput(_ input: String) -> String {
        input.filter(\.isNumber)
    }

    private func closeSheet(openJournal: Bool = false) {
        commitBankrollInput()
        commitShotLimitInput()
        commitSessionStopLossInput()
        commitSessionStopWinInput()
        dismiss()

        guard openJournal else { return }
        DispatchQueue.main.async {
            openWindow(id: AppWindowID.shotJournal)
        }
    }

    private var sessionLimitStatusText: String {
        switch viewModel.sessionLimitReason {
        case .stopLoss:
            if viewModel.isHardStopLossBreakActive {
                return "Перерыв по stop-loss: \(viewModel.hardStopLossBreakRemainingText)."
            }
            return "Сессия остановлена по stop-loss."
        case .stopWin:
            return "Сессия завершена по stop-win."
        case nil:
            return "Сессия активна."
        }
    }

    private var sessionLimitStatusColor: Color {
        switch viewModel.sessionLimitReason {
        case .stopLoss:
            return viewModel.isHardStopLossBreakActive ? .orange : .red
        case .stopWin:
            return .green
        case nil:
            return .gray
        }
    }
}

private struct FixedSheetWindowConfigurator: NSViewRepresentable {
    let width: CGFloat
    let height: CGFloat

    func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onWindowAvailable = applyWindowConstraints
        return view
    }

    func updateNSView(_ nsView: WindowObserverView, context: Context) {
        nsView.onWindowAvailable = applyWindowConstraints
        nsView.applyIfPossible()
    }

    private func applyWindowConstraints(_ window: NSWindow) {
        let fixedSize = NSSize(width: width, height: height)
        window.styleMask.remove(.resizable)
        window.minSize = fixedSize
        window.maxSize = fixedSize
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }

    final class WindowObserverView: NSView {
        var onWindowAvailable: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyIfPossible()
        }

        func applyIfPossible() {
            guard let window else { return }
            onWindowAvailable?(window)

            // SwiftUI может обновить styleMask после первого прохода layout.
            DispatchQueue.main.async { [weak self] in
                guard let self, let delayedWindow = self.window else { return }
                self.onWindowAvailable?(delayedWindow)
            }
        }
    }
}

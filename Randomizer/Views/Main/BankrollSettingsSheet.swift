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

    /// Текстовое значение результата записи журнала в долларах
    @State private var shotResultText = ""

    /// Текст комментария для записи журнала
    @State private var shotCommentText = ""

    /// Признак применения результата записи к текущему банкроллу
    @State private var applyShotResultToBankroll = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
        dismiss()

        guard openJournal else { return }
        DispatchQueue.main.async {
            openWindow(id: AppWindowID.shotJournal)
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

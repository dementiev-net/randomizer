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
/// - Нижний индикатор в виде 3 ступеней (по ~33%)
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

    /// Общий ViewModel приложения
    @ObservedObject var viewModel: RandomizerView

    /// Флаг для анимации пульсации в критическом состоянии
    @State private var isPulsing = false

    /// Флаг отображения настроек банкролла
    @State private var isBankrollSettingsPresented = false

    var body: some View {
        VStack(spacing: 8) {

            Text(String(format: "%03d", viewModel.state.currentNumber))
                .font(.custom("HelveticaNeue-Bold", size: 150))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(viewModel.randomizerNumberColor)
                .contentShape(Rectangle())
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            if let statusText = viewModel.sessionStatusText {
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.sessionStatusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            RatingView(number: viewModel.state.currentNumber, activeColor: viewModel.barColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 5)

            VStack(spacing: 4) {
                HStack {
                    Text("Сессия")
                        .foregroundColor(.gray)

                    Spacer()

                    HStack(spacing: 6) {
                        Text(TimeHelper.format(seconds: viewModel.state.sessionDuration))
                            .foregroundColor(.white)
                            .monospacedDigit()

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

                    HStack(spacing: 6) {
                        Text(TimeHelper.format(seconds: viewModel.state.allTimeDuration))
                            .foregroundColor(viewModel.timerColor)
                            .monospacedDigit()
                            .fontWeight(viewModel.fatigueState == .normal ? .regular : .bold)
                            .opacity(viewModel.fatigueState == .critical && isPulsing ? 0.5 : 1.0)
                            .animation(
                                viewModel.fatigueState == .critical
                                ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                                : .default,
                                value: isPulsing
                            )
                            .onAppear { isPulsing = true }

                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 16, height: 14)
                            .opacity(0)
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Text("Шот NL\(viewModel.shotLimitNL)")
                        .foregroundColor(.gray)

                    Spacer()

                    HStack(spacing: 6) {
                        Text(
                            viewModel.isShotLocked
                            ? "ШОТ ЗАКРЫТ"
                            : viewModel.isShotAvailable
                            ? "ГОТОВ (\(formatBuyIns(viewModel.bankrollReserveForShotInBuyIns)) BI)"
                            : "нужно $\(formatAmount(viewModel.missingBankrollForShot))"
                        )
                        .foregroundColor(
                            viewModel.isShotLocked
                            ? .red
                            : (viewModel.isShotAvailable ? .green : .orange)
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
        .background(Color.black.opacity(0.01))
        .sheet(isPresented: $isBankrollSettingsPresented) {
            BankrollSettingsSheet(viewModel: viewModel)
        }
        .onTapGesture {
            guard !viewModel.isSessionPlayBlocked else { return }
            let generator = NSHapticFeedbackManager.defaultPerformer
            generator.perform(.alignment, performanceTime: .now)
            viewModel.generateNewData()
        }
    }

    private func formatAmount(_ value: Double) -> String {
        String(Int(value.rounded(.up)))
    }

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

//
//  RandomizerApp.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

// MARK: - Randomizer App

/// Главная точка входа в приложение Randomizer
///
/// Создаёт плавающее полупрозрачное окно, которое остаётся поверх других приложений.
/// Окно можно перемещать за любую область фона и имеет фиксированный размер.
///
/// ## Особенности окна:
/// - Плавающий уровень (`.floating`) - всегда поверх других окон
/// - Полупрозрачный чёрный фон (80% непрозрачности)
/// - Скрытая строка заголовка
/// - Перемещение за любую область окна
/// - Фиксированный размер 210×220
@main
struct RandomizerApp: App {

    /// Делегат приложения для управления жизненным циклом
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Общий ViewModel приложения для всех окон
    @StateObject private var viewModel = RandomizerView(notificationService: NotificationService())

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(width: 210, height: 220)
                .onAppear {
                    configureWindow()
                }
        }
        .windowResizability(.contentSize) // Фиксированный размер окна
        .windowStyle(.hiddenTitleBar) // Скрываем стандартную строку заголовка

        Window("Журнал шотов", id: AppWindowID.shotJournal) {
            ShotJournalWindowView(viewModel: viewModel)
        }
        .defaultSize(width: 820, height: 520)
    }

    /// Настраивает свойства главного окна приложения
    ///
    /// Устанавливает:
    /// - Плавающий уровень для отображения поверх других окон
    /// - Возможность перемещения окна за любую область фона
    /// - Полупрозрачный чёрный фон (80% непрозрачности)
    private func configureWindow() {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating // Поверх всех окон
            window.isMovableByWindowBackground = true // Перемещение за фон
            window.backgroundColor = NSColor.black.withAlphaComponent(0.8) // 80% непрозрачности
        }
    }
}

// MARK: - App Delegate

/// Делегат приложения для управления поведением при закрытии окон
///
/// Обеспечивает полное завершение приложения при закрытии последнего окна
/// вместо сохранения процесса в фоне (стандартное поведение macOS).
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Определяет, должно ли приложение завершиться при закрытии последнего окна
    ///
    /// - Parameter sender: Экземпляр NSApplication
    /// - Returns: `true` - приложение завершится полностью
    ///
    /// - Note: Возвращает `true` для немедленного завершения процесса
    ///   вместо оставления приложения активным в Dock
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

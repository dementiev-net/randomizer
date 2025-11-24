//
//  RandomizerApp.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

@main
struct RandomizerApp: App {
    // Эта строка связывает SwiftUI с вашим AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Размеры окна
                .frame(width: 210, height: 190)
                .onAppear {
                    // Настройка плавающего окна
                    if let window = NSApplication.shared.windows.first {
                        window.level = .floating // Поверх всех окон
                        window.isMovableByWindowBackground = true // Можно таскать за фон
                        // Полупрозрачный черный фон (0.8 = 80% непрозрачности)
                        window.backgroundColor = NSColor.black.withAlphaComponent(0.8)
                    }
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

// --- Вставьте этот класс в конец файла ---

class AppDelegate: NSObject, NSApplicationDelegate {
    // Этот метод закрывает приложение полностью, когда закрыто окно
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

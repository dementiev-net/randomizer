//
//  NotificationService.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 05.03.2026.
//

import Foundation
import UserNotifications

/// Абстракция отправки локальных уведомлений приложения
protocol NotificationServiceProtocol {
    /// Запрашивает разрешение на уведомления (один раз за жизненный цикл сервиса)
    func requestAuthorizationIfNeeded(completion: @escaping @Sendable (Bool) -> Void)

    /// Показывает локальное уведомление, если разрешение выдано
    func postNotification(id: String, title: String, body: String)
}

/// Реализация уведомлений через системный центр уведомлений macOS
struct NotificationService: NotificationServiceProtocol {
    func requestAuthorizationIfNeeded(completion: @escaping @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    func postNotification(id: String, title: String, body: String) {
        requestAuthorizationIfNeeded { granted in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { _ in
                // Тихо игнорируем ошибку, чтобы не ломать UX при сбоях центра уведомлений.
            }
        }
    }
}

/// Пустая реализация для тестов и режимов без уведомлений
struct NoopNotificationService: NotificationServiceProtocol {
    func requestAuthorizationIfNeeded(completion: @escaping @Sendable (Bool) -> Void) {
        completion(false)
    }

    func postNotification(id: String, title: String, body: String) {
        // no-op
    }
}

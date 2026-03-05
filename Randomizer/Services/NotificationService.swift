//
//  NotificationService.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 05.03.2026.
//

import Foundation
@preconcurrency import UserNotifications

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
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                DispatchQueue.main.async {
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if let error {
                            NSLog("Randomizer notification auth error: \(error.localizedDescription)")
                        }
                        completion(granted)
                    }
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

            // На macOS уведомление с небольшим delay доставляется стабильнее, чем trigger=nil.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.25, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    NSLog("Randomizer notification error: \(error.localizedDescription)")
                }
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

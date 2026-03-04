//
//  BankrollSettingsFileModel.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

/// JSON-модель для хранения настроек банкролла
struct BankrollSettingsFileModel: Codable {
    let currentBankrollUSD: Double
    let shotLimitNL: Int
    let shotBankrollThresholdBuyIns: Int
    let shotAttempts: Int
    let currentShotResultUSD: Double
    let isShotLocked: Bool
    let sessionStopLossUSD: Double
    let sessionStopWinUSD: Double
    let sessionResultUSD: Double
    let sessionLimitReason: String?

    private enum CodingKeys: String, CodingKey {
        case currentBankrollUSD
        case shotLimitNL
        case shotBankrollThresholdBuyIns
        case shotAttempts
        case currentShotResultUSD
        case isShotLocked
        case sessionStopLossUSD
        case sessionStopWinUSD
        case sessionResultUSD
        case sessionLimitReason
    }

    init(
        currentBankrollUSD: Double,
        shotLimitNL: Int,
        shotBankrollThresholdBuyIns: Int,
        shotAttempts: Int,
        currentShotResultUSD: Double,
        isShotLocked: Bool,
        sessionStopLossUSD: Double,
        sessionStopWinUSD: Double,
        sessionResultUSD: Double,
        sessionLimitReason: String?
    ) {
        self.currentBankrollUSD = currentBankrollUSD
        self.shotLimitNL = shotLimitNL
        self.shotBankrollThresholdBuyIns = shotBankrollThresholdBuyIns
        self.shotAttempts = shotAttempts
        self.currentShotResultUSD = currentShotResultUSD
        self.isShotLocked = isShotLocked
        self.sessionStopLossUSD = sessionStopLossUSD
        self.sessionStopWinUSD = sessionStopWinUSD
        self.sessionResultUSD = sessionResultUSD
        self.sessionLimitReason = sessionLimitReason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentBankrollUSD = try container.decodeIfPresent(Double.self, forKey: .currentBankrollUSD) ?? 0
        shotLimitNL = try container.decodeIfPresent(Int.self, forKey: .shotLimitNL) ?? 25
        shotBankrollThresholdBuyIns = try container.decodeIfPresent(Int.self, forKey: .shotBankrollThresholdBuyIns) ?? 25
        shotAttempts = try container.decodeIfPresent(Int.self, forKey: .shotAttempts) ?? 2
        currentShotResultUSD = try container.decodeIfPresent(Double.self, forKey: .currentShotResultUSD) ?? 0
        isShotLocked = try container.decodeIfPresent(Bool.self, forKey: .isShotLocked) ?? false
        sessionStopLossUSD = try container.decodeIfPresent(Double.self, forKey: .sessionStopLossUSD) ?? 0
        sessionStopWinUSD = try container.decodeIfPresent(Double.self, forKey: .sessionStopWinUSD) ?? 0
        sessionResultUSD = try container.decodeIfPresent(Double.self, forKey: .sessionResultUSD) ?? 0
        sessionLimitReason = try container.decodeIfPresent(String.self, forKey: .sessionLimitReason)
    }

    static let defaults = BankrollSettingsFileModel(
        currentBankrollUSD: 0,
        shotLimitNL: 25,
        shotBankrollThresholdBuyIns: 25,
        shotAttempts: 2,
        currentShotResultUSD: 0,
        isShotLocked: false,
        sessionStopLossUSD: 0,
        sessionStopWinUSD: 0,
        sessionResultUSD: 0,
        sessionLimitReason: nil
    )
}

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

    private enum CodingKeys: String, CodingKey {
        case currentBankrollUSD
        case shotLimitNL
        case shotBankrollThresholdBuyIns
        case shotAttempts
        case currentShotResultUSD
        case isShotLocked
    }

    init(
        currentBankrollUSD: Double,
        shotLimitNL: Int,
        shotBankrollThresholdBuyIns: Int,
        shotAttempts: Int,
        currentShotResultUSD: Double,
        isShotLocked: Bool
    ) {
        self.currentBankrollUSD = currentBankrollUSD
        self.shotLimitNL = shotLimitNL
        self.shotBankrollThresholdBuyIns = shotBankrollThresholdBuyIns
        self.shotAttempts = shotAttempts
        self.currentShotResultUSD = currentShotResultUSD
        self.isShotLocked = isShotLocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentBankrollUSD = try container.decodeIfPresent(Double.self, forKey: .currentBankrollUSD) ?? 0
        shotLimitNL = try container.decodeIfPresent(Int.self, forKey: .shotLimitNL) ?? 25
        shotBankrollThresholdBuyIns = try container.decodeIfPresent(Int.self, forKey: .shotBankrollThresholdBuyIns) ?? 25
        shotAttempts = try container.decodeIfPresent(Int.self, forKey: .shotAttempts) ?? 2
        currentShotResultUSD = try container.decodeIfPresent(Double.self, forKey: .currentShotResultUSD) ?? 0
        isShotLocked = try container.decodeIfPresent(Bool.self, forKey: .isShotLocked) ?? false
    }

    static let defaults = BankrollSettingsFileModel(
        currentBankrollUSD: 0,
        shotLimitNL: 25,
        shotBankrollThresholdBuyIns: 25,
        shotAttempts: 2,
        currentShotResultUSD: 0,
        isShotLocked: false
    )
}

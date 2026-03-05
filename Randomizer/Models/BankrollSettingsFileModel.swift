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
    let fatigueWarningMinutes: Int
    let fatigueCriticalMinutes: Int
    let randomizerLowUpperBound: Int
    let randomizerMidUpperBound: Int
    let currentShotResultUSD: Double
    let isShotLocked: Bool
    let sessionStopLossUSD: Double
    let hardStopLossEnabled: Bool
    let hardStopLossBreakMinutes: Int
    let stopLossBlockUntil: Date?
    let sessionStopWinUSD: Double
    let sessionResultUSD: Double
    let sessionLimitReason: String?

    private enum CodingKeys: String, CodingKey {
        case currentBankrollUSD
        case shotLimitNL
        case shotBankrollThresholdBuyIns
        case shotAttempts
        case fatigueWarningMinutes
        case fatigueCriticalMinutes
        case randomizerLowUpperBound
        case randomizerMidUpperBound
        case currentShotResultUSD
        case isShotLocked
        case sessionStopLossUSD
        case hardStopLossEnabled
        case hardStopLossBreakMinutes
        case stopLossBlockUntil
        case sessionStopWinUSD
        case sessionResultUSD
        case sessionLimitReason
    }

    init(
        currentBankrollUSD: Double,
        shotLimitNL: Int,
        shotBankrollThresholdBuyIns: Int,
        shotAttempts: Int,
        fatigueWarningMinutes: Int,
        fatigueCriticalMinutes: Int,
        randomizerLowUpperBound: Int,
        randomizerMidUpperBound: Int,
        currentShotResultUSD: Double,
        isShotLocked: Bool,
        sessionStopLossUSD: Double,
        hardStopLossEnabled: Bool,
        hardStopLossBreakMinutes: Int,
        stopLossBlockUntil: Date?,
        sessionStopWinUSD: Double,
        sessionResultUSD: Double,
        sessionLimitReason: String?
    ) {
        self.currentBankrollUSD = currentBankrollUSD
        self.shotLimitNL = shotLimitNL
        self.shotBankrollThresholdBuyIns = shotBankrollThresholdBuyIns
        self.shotAttempts = shotAttempts
        self.fatigueWarningMinutes = fatigueWarningMinutes
        self.fatigueCriticalMinutes = fatigueCriticalMinutes
        self.randomizerLowUpperBound = randomizerLowUpperBound
        self.randomizerMidUpperBound = randomizerMidUpperBound
        self.currentShotResultUSD = currentShotResultUSD
        self.isShotLocked = isShotLocked
        self.sessionStopLossUSD = sessionStopLossUSD
        self.hardStopLossEnabled = hardStopLossEnabled
        self.hardStopLossBreakMinutes = hardStopLossBreakMinutes
        self.stopLossBlockUntil = stopLossBlockUntil
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
        fatigueWarningMinutes = try container.decodeIfPresent(Int.self, forKey: .fatigueWarningMinutes) ?? 60
        fatigueCriticalMinutes = try container.decodeIfPresent(Int.self, forKey: .fatigueCriticalMinutes) ?? 120
        randomizerLowUpperBound = try container.decodeIfPresent(Int.self, forKey: .randomizerLowUpperBound) ?? 33
        randomizerMidUpperBound = try container.decodeIfPresent(Int.self, forKey: .randomizerMidUpperBound) ?? 66
        currentShotResultUSD = try container.decodeIfPresent(Double.self, forKey: .currentShotResultUSD) ?? 0
        isShotLocked = try container.decodeIfPresent(Bool.self, forKey: .isShotLocked) ?? false
        sessionStopLossUSD = try container.decodeIfPresent(Double.self, forKey: .sessionStopLossUSD) ?? 0
        hardStopLossEnabled = try container.decodeIfPresent(Bool.self, forKey: .hardStopLossEnabled) ?? false
        hardStopLossBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .hardStopLossBreakMinutes) ?? 15
        stopLossBlockUntil = try container.decodeIfPresent(Date.self, forKey: .stopLossBlockUntil)
        sessionStopWinUSD = try container.decodeIfPresent(Double.self, forKey: .sessionStopWinUSD) ?? 0
        sessionResultUSD = try container.decodeIfPresent(Double.self, forKey: .sessionResultUSD) ?? 0
        sessionLimitReason = try container.decodeIfPresent(String.self, forKey: .sessionLimitReason)
    }

    static let defaults = BankrollSettingsFileModel(
        currentBankrollUSD: 0,
        shotLimitNL: 25,
        shotBankrollThresholdBuyIns: 25,
        shotAttempts: 2,
        fatigueWarningMinutes: 60,
        fatigueCriticalMinutes: 120,
        randomizerLowUpperBound: 33,
        randomizerMidUpperBound: 66,
        currentShotResultUSD: 0,
        isShotLocked: false,
        sessionStopLossUSD: 0,
        hardStopLossEnabled: false,
        hardStopLossBreakMinutes: 15,
        stopLossBlockUntil: nil,
        sessionStopWinUSD: 0,
        sessionResultUSD: 0,
        sessionLimitReason: nil
    )
}

//
//  ShotJournalEntry.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import Foundation

/// Запись журнала шота
struct ShotJournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let limitNL: Int
    let sessionDurationSeconds: Int
    let resultUSD: Double
    let resultBuyIns: Double
    let applyToBankroll: Bool
    let bankrollAfterUSD: Double
    let comment: String

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case limitNL
        case sessionDurationSeconds
        case resultUSD
        case resultBuyIns
        case applyToBankroll
        case bankrollAfterUSD
        case comment
    }

    init(
        id: UUID,
        date: Date,
        limitNL: Int,
        sessionDurationSeconds: Int,
        resultUSD: Double,
        resultBuyIns: Double,
        applyToBankroll: Bool,
        bankrollAfterUSD: Double,
        comment: String
    ) {
        self.id = id
        self.date = date
        self.limitNL = limitNL
        self.sessionDurationSeconds = max(0, sessionDurationSeconds)
        self.resultUSD = resultUSD
        self.resultBuyIns = resultBuyIns
        self.applyToBankroll = applyToBankroll
        self.bankrollAfterUSD = bankrollAfterUSD
        self.comment = comment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        limitNL = try container.decode(Int.self, forKey: .limitNL)
        sessionDurationSeconds = max(0, try container.decodeIfPresent(Int.self, forKey: .sessionDurationSeconds) ?? 0)
        resultUSD = try container.decode(Double.self, forKey: .resultUSD)
        resultBuyIns = try container.decode(Double.self, forKey: .resultBuyIns)
        applyToBankroll = try container.decode(Bool.self, forKey: .applyToBankroll)
        bankrollAfterUSD = try container.decode(Double.self, forKey: .bankrollAfterUSD)
        comment = try container.decode(String.self, forKey: .comment)
    }
}

//
//  ShotJournalWindowView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI

struct ShotJournalWindowView: View {

    @ObservedObject var viewModel: RandomizerView

    @State private var selection: ShotJournalEntry.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Журнал шотов")
                .font(.system(size: 18, weight: .semibold))

            if viewModel.shotJournalEntries.isEmpty {
                Text("Записей пока нет")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Table(viewModel.shotJournalEntries, selection: $selection) {
                    TableColumn("Дата") { entry in
                        Text(Self.dateFormatter.string(from: entry.date))
                    }
                    .width(min: 110, ideal: 120, max: 140)

                    TableColumn("NL") { entry in
                        Text("NL\(entry.limitNL)")
                    }
                    .width(min: 55, ideal: 60, max: 70)

                    TableColumn("Сессия") { entry in
                        Text(TimeHelper.format(seconds: TimeInterval(entry.sessionDurationSeconds)))
                    }
                    .width(min: 90, ideal: 100, max: 110)

                    TableColumn("Результат") { entry in
                        Text(formattedResultUSD(entry.resultUSD))
                            .foregroundColor(entry.resultUSD >= 0 ? .green : .orange)
                    }
                    .width(min: 85, ideal: 95, max: 105)

                    TableColumn("BI") { entry in
                        Text(formattedBuyIns(entry.resultBuyIns))
                    }
                    .width(min: 55, ideal: 65, max: 75)

                    TableColumn("Банкролл") { entry in
                        Text(formattedAmount(entry.bankrollAfterUSD))
                    }
                    .width(min: 80, ideal: 90, max: 110)

                    TableColumn("Комментарий") { entry in
                        Text(entry.comment.isEmpty ? "—" : entry.comment)
                            .lineLimit(1)
                    }
                }
            }

            Text("График банкролла добавим в следующем шаге.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(minWidth: 760, minHeight: 420)
    }

    private func formattedAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value))$"
        }

        return "\(String(format: "%.2f", value))$"
    }

    private func formattedResultUSD(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        if value == value.rounded() {
            return "\(sign)\(Int(value))$"
        }
        return "\(sign)\(String(format: "%.2f", value))$"
    }

    private func formattedBuyIns(_ value: Double) -> String {
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}

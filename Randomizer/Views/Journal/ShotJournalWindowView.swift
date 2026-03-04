//
//  ShotJournalWindowView.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 24.11.2025.
//

import SwiftUI
import Charts

private enum BankrollChartMode: String, CaseIterable, Identifiable {
    case entries = "По записям"
    case days = "По дням"

    var id: String { rawValue }
}

private struct BankrollChartPoint: Identifiable {
    let id: Int
    let date: Date
    let bankroll: Double
}

struct ShotJournalWindowView: View {

    @ObservedObject var viewModel: RandomizerView

    @State private var selection: ShotJournalEntry.ID?
    @State private var chartMode: BankrollChartMode = .entries

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Журнал шотов")
                .font(.system(size: 18, weight: .semibold))

            if viewModel.shotJournalEntries.isEmpty {
                Text("Записей пока нет")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("График банкролла")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Picker(selection: $chartMode) {
                            ForEach(BankrollChartMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityLabel("Режим графика")
                        .frame(width: 220)
                    }

                    Chart(chartPoints) { point in
                        AreaMark(
                            x: .value("Дата", point.date),
                            y: .value("Банкролл", point.bankroll)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [Color.cyan.opacity(0.25), Color.cyan.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Дата", point.date),
                            y: .value("Банкролл", point.bankroll)
                        )
                        .foregroundStyle(.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Дата", point.date),
                            y: .value("Банкролл", point.bankroll)
                        )
                        .foregroundStyle(.cyan.opacity(0.8))
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(axisDateLabel(for: date))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 190)

                    HStack(spacing: 16) {
                        Text("Текущий: \(formattedAmount(chartCurrentBankroll))")
                        Text("Мин: \(formattedAmount(chartMinBankroll))")
                        Text("Макс: \(formattedAmount(chartMaxBankroll))")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }

                Divider()

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
                .frame(maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(minWidth: 900, minHeight: 620)
    }

    private var chartPoints: [BankrollChartPoint] {
        let sortedEntries = viewModel.shotJournalEntries.sorted { $0.date < $1.date }

        switch chartMode {
        case .entries:
            return sortedEntries.enumerated().map { index, entry in
                BankrollChartPoint(id: index, date: entry.date, bankroll: entry.bankrollAfterUSD)
            }

        case .days:
            var lastEntryByDay: [Date: ShotJournalEntry] = [:]
            let calendar = Calendar.current

            for entry in sortedEntries {
                let day = calendar.startOfDay(for: entry.date)
                let current = lastEntryByDay[day]

                if current == nil || entry.date > current!.date {
                    lastEntryByDay[day] = entry
                }
            }

            let orderedDays = lastEntryByDay.keys.sorted()

            return orderedDays.enumerated().compactMap { index, day in
                guard let entry = lastEntryByDay[day] else { return nil }
                return BankrollChartPoint(id: index, date: day, bankroll: entry.bankrollAfterUSD)
            }
        }
    }

    private var chartCurrentBankroll: Double {
        chartPoints.last?.bankroll ?? 0
    }

    private var chartMinBankroll: Double {
        chartPoints.map(\.bankroll).min() ?? 0
    }

    private var chartMaxBankroll: Double {
        chartPoints.map(\.bankroll).max() ?? 0
    }

    private func axisDateLabel(for date: Date) -> String {
        if chartMode == .days {
            return Self.chartDayFormatter.string(from: date)
        }

        return Self.chartEntryFormatter.string(from: date)
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

    private static let chartDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter
    }()

    private static let chartEntryFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        return formatter
    }()
}

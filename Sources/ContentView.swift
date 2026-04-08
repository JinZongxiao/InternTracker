import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AttendanceStore

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                monthHeader
                CalendarGridView(month: store.selectedMonth) { date in
                    store.cycleMode(for: date)
                }
                legend
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            SidebarView()
                .frame(width: 320)
        }
        .padding(24)
    }

    private var monthHeader: some View {
        HStack {
            Button("上个月") {
                store.moveMonth(by: -1)
            }

            Spacer()

            Text(monthTitle(store.selectedMonth))
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button("下个月") {
                store.moveMonth(by: 1)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            label("未标记", color: Color.gray.opacity(0.25))
            label("线下", color: Color.blue.opacity(0.75))
            label("远程", color: Color.green.opacity(0.75))
            Text("点击日期可循环切换：未标记 -> 线下 -> 远程")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func label(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 18, height: 18)
            Text(text)
                .font(.footnote)
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

private struct CalendarGridView: View {
    @EnvironmentObject private var store: AttendanceStore

    let month: Date
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let weekTitles = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let days = gridDays(for: month)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
            ForEach(weekTitles, id: \.self) { title in
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }

            ForEach(days, id: \.self) { day in
                if calendar.isDate(day, equalTo: month, toGranularity: .month) {
                    DayCell(date: day, mode: store.mode(for: day)) {
                        onSelectDate(day)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.clear)
                        .frame(height: 72)
                }
            }
        }
    }

    private func gridDays(for month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        let monthStart = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingOffset = firstWeekday - 1

        guard let gridStart = calendar.date(byAdding: .day, value: -leadingOffset, to: monthStart) else {
            return []
        }

        return (0..<42).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }
}

private struct DayCell: View {
    let date: Date
    let mode: WorkMode?
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dayNumber)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(mode?.displayName ?? "未标记")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.85))

                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var backgroundColor: Color {
        switch mode {
        case .onsite:
            return Color.blue.opacity(0.25)
        case .remote:
            return Color.green.opacity(0.25)
        case nil:
            return Color.gray.opacity(0.12)
        }
    }

    private var borderColor: Color {
        if isToday { return .orange }
        return Color.gray.opacity(0.35)
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var store: AttendanceStore

    var body: some View {
        let stats = store.monthStats(for: store.selectedMonth)

        VStack(alignment: .leading, spacing: 18) {
            Text("统计与薪资")
                .font(.title3)
                .fontWeight(.semibold)

            GroupBox("本月统计") {
                VStack(alignment: .leading, spacing: 8) {
                    statRow("线下天数", value: "\(stats.onsiteDays)")
                    statRow("远程天数", value: "\(stats.remoteDays)")
                    statRow("总出勤天数", value: "\(stats.totalDays)")
                    Divider()
                    statRow("预估薪资", value: currency(stats.expectedSalary), isHighlight: true)
                }
                .padding(.top, 4)
            }

            GroupBox("薪资参数") {
                VStack(spacing: 10) {
                    moneyField("月基础薪资", value: $store.salaryConfig.monthlyBaseSalary)
                    moneyField("线下补贴/天", value: $store.salaryConfig.onsiteAllowancePerDay)
                    moneyField("远程补贴/天", value: $store.salaryConfig.remoteAllowancePerDay)
                    intField("每月计薪工作日", value: $store.salaryConfig.workdaysPerMonth)

                    Text("基础日薪：\(currency(store.salaryConfig.dailyBaseRate))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }

            Text("参数和打卡会自动保存到本地。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func statRow(_ title: String, value: String, isHighlight: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(isHighlight ? .semibold : .regular)
        }
        .font(isHighlight ? .body : .callout)
    }

    private func moneyField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func intField(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
    }
}

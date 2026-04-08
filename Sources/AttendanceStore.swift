import Foundation

final class AttendanceStore: ObservableObject {
    @Published private(set) var records: [Date: WorkMode] = [:]
    @Published var salaryConfig = SalaryConfig() {
        didSet {
            if salaryConfig.workdaysPerMonth < 1 {
                salaryConfig.workdaysPerMonth = 1
                return
            }
            save()
        }
    }
    @Published var selectedMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()

    private let calendar = Calendar.current
    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = appSupport.appendingPathComponent("InternTracker", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        saveURL = directory.appendingPathComponent("attendance_data.json")
        load()

        if records.isEmpty {
            seedCurrentMonthSampleData()
            save()
        }
    }

    func mode(for date: Date) -> WorkMode? {
        records[normalized(date)]
    }

    func setMode(_ mode: WorkMode?, for date: Date) {
        let key = normalized(date)
        records[key] = mode
        save()
    }

    func cycleMode(for date: Date) {
        switch mode(for: date) {
        case nil:
            setMode(.onsite, for: date)
        case .onsite:
            setMode(.remote, for: date)
        case .remote:
            setMode(nil, for: date)
        }
    }

    func monthStats(for month: Date) -> MonthlyStats {
        let range = monthDateRange(for: month)
        let monthRecords = records.filter { range.contains($0.key) }

        let onsite = monthRecords.values.filter { $0 == .onsite }.count
        let remote = monthRecords.values.filter { $0 == .remote }.count
        let total = onsite + remote

        let expected = Double(total) * salaryConfig.dailyBaseRate
            + Double(onsite) * salaryConfig.onsiteAllowancePerDay
            + Double(remote) * salaryConfig.remoteAllowancePerDay

        return MonthlyStats(month: month, onsiteDays: onsite, remoteDays: remote, totalDays: total, expectedSalary: expected)
    }

    func moveMonth(by offset: Int) {
        selectedMonth = calendar.date(byAdding: .month, value: offset, to: selectedMonth) ?? selectedMonth
    }

    func monthDateRange(for month: Date) -> ClosedRange<Date> {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        var components = DateComponents()
        components.month = 1
        components.day = -1
        let end = calendar.date(byAdding: components, to: start) ?? start
        return start...end
    }

    private func normalized(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private struct SavePayload: Codable {
        var records: [AttendanceRecord]
        var salaryConfig: SalaryConfig
    }

    private func save() {
        let payload = SavePayload(
            records: records.map { AttendanceRecord(date: $0.key, mode: $0.value) },
            salaryConfig: salaryConfig
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let payload = try? JSONDecoder().decode(SavePayload.self, from: data) else {
            return
        }

        var map: [Date: WorkMode] = [:]
        payload.records.forEach { map[normalized($0.date)] = $0.mode }
        records = map
        salaryConfig = payload.salaryConfig
    }

    private func seedCurrentMonthSampleData() {
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let dayRange = calendar.range(of: .day, in: .month, for: currentMonthStart) ?? 1..<29

        for day in dayRange where day <= 10 {
            var components = calendar.dateComponents([.year, .month], from: currentMonthStart)
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            if day % 3 == 0 {
                records[normalized(date)] = .remote
            } else if day % 2 == 0 {
                records[normalized(date)] = .onsite
            }
        }
    }
}

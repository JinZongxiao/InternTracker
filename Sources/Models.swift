import Foundation

enum WorkMode: String, Codable, CaseIterable, Identifiable {
    case onsite
    case remote

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .onsite: return "线下"
        case .remote: return "远程"
        }
    }
}

struct AttendanceRecord: Codable {
    var date: Date
    var mode: WorkMode
}

struct SalaryConfig: Codable {
    var monthlyBaseSalary: Double = 12000
    var onsiteAllowancePerDay: Double = 50
    var remoteAllowancePerDay: Double = 0
    var workdaysPerMonth: Int = 21

    var dailyBaseRate: Double {
        guard workdaysPerMonth > 0 else { return 0 }
        return monthlyBaseSalary / Double(workdaysPerMonth)
    }
}

struct MonthlyStats {
    let month: Date
    let onsiteDays: Int
    let remoteDays: Int
    let totalDays: Int
    let expectedSalary: Double
}

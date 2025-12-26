import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay, to: date.startOfDay).day ?? 0
    }

    func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date.startOfDay, to: startOfDay).day ?? 0
    }

    var relativeString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isTomorrow {
            return "Tomorrow"
        } else if isThisWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else if isThisYear {
            return formatted(.dateTime.month(.abbreviated).day())
        } else {
            return formatted(.dateTime.year().month(.abbreviated).day())
        }
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSince(rhs)
    }
}

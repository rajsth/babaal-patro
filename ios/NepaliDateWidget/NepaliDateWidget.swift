import WidgetKit
import SwiftUI

// MARK: - Nepali Calendar Converter

/// Converts Gregorian (AD) dates to Bikram Sambat (BS) dates natively.
/// Port of the nepali_utils Dart package algorithm.
struct NepaliCalendar {
    static let kathmanduTZ = TimeZone(identifier: "Asia/Kathmandu")!

    struct BSDate {
        let year: Int
        let month: Int
        let day: Int
        let weekday: Int // 1=Sunday … 7=Saturday
    }

    static let monthNames = [
        "बैशाख", "जेठ", "असार", "श्रावण", "भदौ", "असोज",
        "कार्तिक", "मंसिर", "पौष", "माघ", "फाल्गुन", "चैत्र",
    ]

    static let dayFullNames = [
        "आइतबार", "सोमबार", "मंगलबार", "बुधबार",
        "बिहिबार", "शुक्रबार", "शनिबार",
    ]

    static let nepaliDigits: [Character] = [
        "०", "१", "२", "३", "४", "५", "६", "७", "८", "९",
    ]

    static let adMonthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    // MARK: Public API

    /// Convert a `Date` to a BS date using Kathmandu timezone.
    static func fromDate(_ date: Date) -> BSDate {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kathmanduTZ
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        return fromAD(year: c.year!, month: c.month!, day: c.day!, weekday: c.weekday!)
    }

    /// Integer → Devanagari numeral string.
    static func toNepaliNumeral(_ number: Int) -> String {
        String(number).map { ch in
            if let d = ch.wholeNumberValue { return String(nepaliDigits[d]) }
            return String(ch)
        }.joined()
    }

    /// Format a `Date` as "Month Day, Year" in Kathmandu timezone.
    static func formatADDate(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kathmanduTZ
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return "\(adMonthNames[c.month! - 1]) \(c.day!), \(c.year!)"
    }

    // MARK: Private

    /// Core AD → BS conversion (same algorithm as nepali_utils).
    /// Reference: BS 1970/1/1 = AD 1913/4/13
    private static func fromAD(year: Int, month: Int, day: Int, weekday: Int) -> BSDate {
        var bsYear = 1970
        var bsMonth = 1
        var bsDay = 1

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let refDate = cal.date(from: DateComponents(year: 1913, month: 4, day: 13))!
        let target  = cal.date(from: DateComponents(year: year, month: month, day: day))!
        var diff = cal.dateComponents([.day], from: refDate, to: target).day!

        guard diff >= 0 else {
            return BSDate(year: bsYear, month: bsMonth, day: bsDay, weekday: weekday)
        }

        // Advance BS year
        while let yd = nepaliYears[bsYear], diff >= yd[0] {
            diff -= yd[0]
            bsYear += 1
        }

        // Advance BS month
        while let yd = nepaliYears[bsYear], bsMonth <= 12, diff >= yd[bsMonth] {
            diff -= yd[bsMonth]
            bsMonth += 1
        }

        bsDay += diff
        return BSDate(year: bsYear, month: bsMonth, day: bsDay, weekday: weekday)
    }

    // MARK: - Nepali Year Data

    /// Each entry: [totalDaysInYear, month1, month2, …, month12]
    /// Source: nepali_utils 3.0.8
    static let nepaliYears: [Int: [Int]] = [
        1970: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1971: [365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30],
        1972: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        1973: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        1974: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1975: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        1976: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        1977: [365, 30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
        1978: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1979: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        1980: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        1981: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
        1982: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1983: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        1984: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        1985: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        1986: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1987: [365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        1988: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        1989: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        1990: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1991: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        1992: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        1993: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        1994: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1995: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        1996: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        1997: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        1998: [365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30],
        1999: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2000: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2001: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2002: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2003: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2004: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2005: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2006: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2007: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2008: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
        2009: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2010: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2011: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2012: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2013: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2014: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2015: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2016: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2017: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2018: [365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2019: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2020: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2021: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2022: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        2023: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2024: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2025: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2026: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2027: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2028: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2029: [365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30],
        2030: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2031: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2032: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2033: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2034: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2035: [365, 30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
        2036: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2037: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2038: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2039: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2040: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2041: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2042: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2043: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2044: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2045: [365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2046: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2047: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2048: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2049: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        2050: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2051: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2052: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2053: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        2054: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2055: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2056: [365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30],
        2057: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2058: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2059: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2060: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2061: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2062: [365, 30, 32, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31],
        2063: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2064: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2065: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2066: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
        2067: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2068: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2069: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2070: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2071: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2072: [365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2073: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2074: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2075: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2076: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        2077: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2078: [365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
        2079: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2080: [365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
        2081: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2082: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2083: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2084: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2085: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2086: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2087: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2088: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2089: [365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
        2090: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2091: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2092: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2093: [365, 31, 31, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31],
        2094: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2095: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2096: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
        2097: [365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
        2098: [365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
        2099: [365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
        2100: [366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    ]
}

// MARK: - Data Model

struct NepaliDateEntry: TimelineEntry {
    let date: Date
    let nepaliDay: String
    let nepaliMonthYear: String
    let nepaliDayName: String
    let adDate: String
    let formattedTime: String
    let accentColor: Color
}

// MARK: - Timeline Provider

struct NepaliDateProvider: TimelineProvider {
    static let appGroupID = "group.com.babaal.patro"

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        f.timeZone = NepaliCalendar.kathmanduTZ
        return f
    }()

    func placeholder(in context: Context) -> NepaliDateEntry {
        NepaliDateEntry(
            date: Date(),
            nepaliDay: "८",
            nepaliMonthYear: "फागुन २०८२",
            nepaliDayName: "शनिबार",
            adDate: "March 8, 2026",
            formattedTime: Self.timeFormatter.string(from: Date()),
            accentColor: Color(hex: "#FFB388FF") ?? .purple
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NepaliDateEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NepaliDateEntry>) -> Void) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = NepaliCalendar.kathmanduTZ

        let now = Date()

        // Round down to the current minute
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        var slotComps = comps
        slotComps.second = 0
        let firstSlot = cal.date(from: slotComps) ?? now

        // Generate entries every 1 minute for the next 12 hours (720 entries).
        // Each entry computes the Nepali date natively, so midnight transitions
        // happen automatically.
        var entries: [NepaliDateEntry] = []
        for i in 0..<720 {
            let slotDate = cal.date(byAdding: .minute, value: i, to: firstSlot)!
            entries.append(makeEntry(for: slotDate))
        }

        // Refresh after the last entry expires
        let refreshDate = entries.last?.date ?? cal.date(byAdding: .hour, value: 25, to: now)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: Private

    /// Build an entry by computing the Nepali date natively.
    /// Accent color is still read from UserDefaults (set by the Flutter app).
    private func makeEntry(for date: Date) -> NepaliDateEntry {
        let bs = NepaliCalendar.fromDate(date)

        let nepaliDay      = NepaliCalendar.toNepaliNumeral(bs.day)
        let monthName      = NepaliCalendar.monthNames[bs.month - 1]
        let nepaliMonthYear = "\(monthName) \(NepaliCalendar.toNepaliNumeral(bs.year))"
        let nepaliDayName  = NepaliCalendar.dayFullNames[bs.weekday - 1]
        let adDate         = NepaliCalendar.formatADDate(date)

        // Read accent color from shared UserDefaults
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        let hexStr   = defaults?.string(forKey: "accent_color") ?? "#FFB388FF"
        let accent   = Color(hex: hexStr) ?? Color(red: 0.7, green: 0.54, blue: 1.0)

        let formattedTime = Self.timeFormatter.string(from: date)

        return NepaliDateEntry(
            date: date,
            nepaliDay: nepaliDay,
            nepaliMonthYear: nepaliMonthYear,
            nepaliDayName: nepaliDayName,
            adDate: adDate,
            formattedTime: formattedTime,
            accentColor: accent
        )
    }
}

// MARK: - Background

struct WidgetBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.102, green: 0.102, blue: 0.180), // #1A1A2E
                Color(red: 0.086, green: 0.129, blue: 0.243)  // #16213E
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - containerBackground compatibility shim

/// On iOS 17+ WidgetKit requires `.containerBackground(for:)`.
/// On iOS 14–16 we fall back to a plain ZStack background.
extension View {
    @ViewBuilder
    func widgetBackground(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget, content: content)
        } else {
            ZStack {
                content()
                self
            }
        }
    }
}

// MARK: - Small Widget View  (systemSmall)

struct SmallWidgetView: View {
    let entry: NepaliDateEntry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Fixed height frame + clipped physically removes the font's
            // built-in ascender/descender whitespace.
            Text(entry.nepaliDay)
                .font(.system(size: 90, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 95)
                .clipped()

            // ── Month + Year ──
            Text(entry.nepaliMonthYear)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(entry.accentColor)
                .minimumScaleFactor(0.8)
                .lineLimit(0)

            // ── Weekday ──
            Text(entry.nepaliDayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .widgetBackground { WidgetBackground() }
    }
}

// MARK: - Medium Widget View  (systemMedium)

struct MediumWidgetView: View {
    let entry: NepaliDateEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Top row: time + Nepali day ──
            HStack(alignment: .top) {
                Text(entry.date, style: .time)
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Spacer()

                Text(entry.nepaliDay)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(entry.accentColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // ── Divider ──
            Rectangle()
                .fill(entry.accentColor.opacity(0.3))
                .frame(height: 1)

            Spacer(minLength: 8)

            // ── Bottom row: AD date | day name | month+year ──
            HStack(alignment: .center) {
                Text(entry.adDate)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer()

                Text(entry.nepaliDayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer()

                Text(entry.nepaliMonthYear)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(entry.accentColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .widgetBackground { WidgetBackground() }
    }
}

// MARK: - Widget Definitions

struct NepaliDateSmallWidget: Widget {
    let kind: String = "NepaliDateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliDateProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Nepali Date")
        .description("Today's Nepali date and time.")
        .supportedFamilies([.systemSmall])
    }
}

struct NepaliDateMediumWidget: Widget {
    let kind: String = "NepaliDateWidgetMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliDateProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Nepali Date")
        .description("Today's Nepali date and time.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Color Helpers

extension Color {
    /// Parses #AARRGGBB or #RRGGBB hex strings (Flutter's ARGB format).
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }

        var value: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&value) else { return nil }

        let a, r, g, b: UInt64
        switch h.count {
        case 8:  // AARRGGBB
            a = (value >> 24) & 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8)  & 0xFF
            b =  value        & 0xFF
        case 6:  // RRGGBB
            a = 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8)  & 0xFF
            b =  value        & 0xFF
        default:
            return nil
        }

        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

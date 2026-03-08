import WidgetKit
import SwiftUI

// MARK: - Data Model

struct NepaliDateEntry: TimelineEntry {
    let date: Date
    let nepaliDay: String
    let nepaliMonthYear: String
    let nepaliDayName: String
    let adDate: String
    let accentColor: Color
}

// MARK: - Timeline Provider

struct NepaliDateProvider: TimelineProvider {
    static let appGroupID = "group.com.babaal.patro"
    static let kathmanduTZ = TimeZone(identifier: "Asia/Kathmandu")!

    func placeholder(in context: Context) -> NepaliDateEntry {
        NepaliDateEntry(
            date: Date(),
            nepaliDay: "८",
            nepaliMonthYear: "फागुन २०८२",
            nepaliDayName: "शनिबार",
            adDate: "March 8, 2026",
            accentColor: Color(hex: "#FFB388FF") ?? .purple
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NepaliDateEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NepaliDateEntry>) -> Void) {
        let entry = readEntry()
        // Refresh at next midnight (Kathmandu time) so date fields stay current
        let nextMidnight = Self.nextMidnightKathmandu()
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    // MARK: Private

    private func readEntry() -> NepaliDateEntry {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        let day       = defaults?.string(forKey: "nepali_day")        ?? "—"
        let monthYear = defaults?.string(forKey: "nepali_month_year") ?? "—"
        let dayName   = defaults?.string(forKey: "nepali_day_name")   ?? "—"
        let adDate    = defaults?.string(forKey: "ad_date")           ?? "—"
        let hexStr    = defaults?.string(forKey: "accent_color")      ?? "#FFB388FF"
        let accent    = Color(hex: hexStr) ?? Color(red: 0.7, green: 0.54, blue: 1.0)

        return NepaliDateEntry(
            date: Date(),
            nepaliDay: day,
            nepaliMonthYear: monthYear,
            nepaliDayName: dayName,
            adDate: adDate,
            accentColor: accent
        )
    }

    private static func nextMidnightKathmandu() -> Date {
        var cal = Calendar.current
        cal.timeZone = kathmanduTZ
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        return cal.startOfDay(for: tomorrow)
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
                Text(Date(), style: .time)
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .environment(\.timeZone, NepaliDateProvider.kathmanduTZ)

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
                .widgetURL(URL(string: "babaal-patro://open"))
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
                .widgetURL(URL(string: "babaal-patro://open"))
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

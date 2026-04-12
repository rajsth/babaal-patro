import 'package:nepali_utils/nepali_utils.dart';
import 'app_localizations.dart';

/// Pure utility class for Nepali (Bikram Sambat) date operations.
/// Completely decoupled from UI — handles all date conversions,
/// Nepali numeral formatting, and calendar grid calculations.
class NepaliDateHelper {
  NepaliDateHelper._();

  // ─── Nepali Numeral Conversion ───────────────────────────────────

  /// Converts an integer to its Devanagari numeral representation.
  static String toNepaliNumeral(int number) {
    const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return number
        .toString()
        .split('')
        .map((d) => nepaliDigits[int.parse(d)])
        .join();
  }

  /// Returns Devanagari numerals if [isNepali] is true, else Arabic numerals.
  static String localizedNumeral(int number, {bool isNepali = true}) {
    return isNepali ? toNepaliNumeral(number) : number.toString();
  }

  // ─── Nepali Labels ───────────────────────────────────────────────

  /// Full Nepali month names (index 0 = Baisakh, index 11 = Chaitra).
  static const List<String> monthNames = [
    'बैशाख',
    'जेठ',
    'असार',
    'श्रावण',
    'भदौ',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पौष',
    'माघ',
    'फाल्गुन',
    'चैत्र',
  ];

  /// Nepali day-of-week abbreviations (Sunday first — standard in Nepal).
  static const List<String> dayNames = [
    'आइत',
    'सोम',
    'मंगल',
    'बुध',
    'बिहि',
    'शुक्र',
    'शनि',
  ];

  /// Full Nepali day-of-week names.
  static const List<String> dayFullNames = [
    'आइतबार',
    'सोमबार',
    'मंगलबार',
    'बुधबार',
    'बिहिबार',
    'शुक्रबार',
    'शनिबार',
  ];

  // ─── Date Queries ────────────────────────────────────────────────

  /// Returns the current [DateTime] in Nepal Standard Time (UTC+5:45).
  /// Nepal has no DST, so the offset is always fixed.
  static DateTime nepalNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45));

  /// Returns today's date in BS, always based on Nepal Standard Time
  /// regardless of the device's local timezone.
  static NepaliDateTime today() => nepalNow().toNepaliDateTime();

  /// Returns the number of days in a given BS month/year.
  static int daysInMonth(int year, int month) {
    // NepaliDateTime months are 1-indexed.
    final totalDays = NepaliDateTime(year, month).totalDays;
    return totalDays;
  }

  /// Returns the weekday (1=Sunday … 7=Saturday) of the first day of the month.
  static int firstWeekdayOfMonth(int year, int month) {
    final firstDay = NepaliDateTime(year, month, 1);
    // NepaliDateTime.weekday: 1=Sunday, 7=Saturday (Nepali convention).
    return firstDay.weekday;
  }

  /// Builds a list of day numbers for the calendar grid.
  /// Leading nulls represent blank cells before the 1st of the month.
  static List<int?> calendarGridDays(int year, int month) {
    final totalDays = daysInMonth(year, month);
    // weekday: 1=Sun, so offset = weekday - 1 blank slots before day 1.
    final offset = firstWeekdayOfMonth(year, month) - 1;

    return [
      ...List<int?>.filled(offset, null),
      ...List<int>.generate(totalDays, (i) => i + 1),
    ];
  }

  /// Returns the number of leading blank cells before the 1st of the month.
  static int leadingBlanks(int year, int month) {
    return firstWeekdayOfMonth(year, month) - 1;
  }

  /// Returns the days from the previous month that fill leading blanks.
  static List<int> previousMonthTrailingDays(int year, int month) {
    final blanks = leadingBlanks(year, month);
    if (blanks == 0) return [];
    int prevYear = year;
    int prevMonth = month - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }
    if (prevYear < 2000) return List.filled(blanks, 0);
    final prevTotal = daysInMonth(prevYear, prevMonth);
    return List.generate(blanks, (i) => prevTotal - blanks + 1 + i);
  }

  /// Returns the abbreviated weekday name for a given BS date.
  static String weekdayName(int year, int month, int day,
      {bool isNepali = true}) {
    final nepDate = NepaliDateTime(year, month, day);
    final names = S.of(isNepali).dayFullNames;
    return names[nepDate.weekday - 1];
  }

  /// Returns the number of trailing cells needed to complete the last row.
  static int trailingBlanks(int year, int month) {
    final totalCells = leadingBlanks(year, month) + daysInMonth(year, month);
    final remainder = totalCells % 7;
    return remainder == 0 ? 0 : 7 - remainder;
  }

  /// Returns the Nepali month name for a 1-indexed month.
  static String monthName(int month, {bool isNepali = true}) =>
      S.of(isNepali).monthNames[month - 1];

  /// Formatted header string: "बैशाख २०८१" or "Baisakh 2081"
  static String formattedMonthYear(int year, int month,
      {bool isNepali = true}) {
    return '${monthName(month, isNepali: isNepali)} ${localizedNumeral(year, isNepali: isNepali)}';
  }

  /// Checks if two NepaliDateTime values represent the same calendar day.
  static bool isSameDay(NepaliDateTime a, NepaliDateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns the AD day number for a given BS date.
  static int toADDay(int bsYear, int bsMonth, int bsDay) {
    return NepaliDateTime(bsYear, bsMonth, bsDay).toDateTime().day;
  }

  /// Converts a BS date to its AD equivalent and returns a formatted string.
  static String toADString(int bsYear, int bsMonth, int bsDay) {
    final nepaliDate = NepaliDateTime(bsYear, bsMonth, bsDay);
    final adDate = nepaliDate.toDateTime();
    const adMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${adMonths[adDate.month - 1]} ${adDate.day}, ${adDate.year}';
  }
}

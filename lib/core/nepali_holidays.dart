/// Static repository of major Nepali public holidays (BS dates).
///
/// Holidays are keyed by "month-day" for fixed-date holidays, and
/// by "year-month-day" for holidays whose BS date shifts each year.
/// This covers the most widely observed national holidays.
class NepaliHolidays {
  NepaliHolidays._();

  /// Fixed holidays that fall on the same BS date every year.
  /// Key format: "month-day" (1-indexed).
  static const Map<String, String> _fixedHolidays = {
    // बैशाख (month 1)
    '1-1': 'नयाँ वर्ष',               // Nepali New Year
    '1-11': 'लोकतन्त्र दिवस',         // Democracy Day

    // जेठ (month 2)
    '2-15': 'बुद्ध जयन्ती',            // Buddha Jayanti (approx)
    '2-29': 'गणतन्त्र दिवस',          // Republic Day

    // श्रावण (month 4)
    '4-1': 'श्रावण सक्रान्ति',

    // भदौ (month 5)
    '5-3': 'श्रीकृष्ण जन्माष्टमी',    // Krishna Janmashtami (approx)
    '5-18': 'तीज',                      // Teej (approx)

    // असोज (month 6)
    '6-17': 'संविधान दिवस',            // Constitution Day

    // कार्तिक (month 7)
    '7-2': 'छठ पर्व',                  // Chhath (approx)

    // मंसिर (month 8)
    '8-1': 'मंसिर सक्रान्ति',

    // माघ (month 10)
    '10-1': 'माघे संक्रान्ति',         // Maghe Sankranti
    '10-22': 'शहीद दिवस',             // Martyrs' Day
    '10-29': 'प्रजातन्त्र दिवस',      // Praja­tantra Day

    // फाल्गुन (month 11)
    '11-8': 'महाशिवरात्रि',           // Maha Shivaratri (approx)

    // चैत्र (month 12)
    '12-15': 'होली',                    // Holi (approx)
    '12-28': 'घोडे जात्रा',           // Ghode Jatra (approx)
  };

  /// Year-specific holidays whose BS date varies.
  /// Key format: "year-month-day".
  /// This map holds Dashain/Tihar and other lunar holidays per year.
  static const Map<String, String> _yearSpecificHolidays = {
    // ─── 2081 ──────────────────────────────────
    '2081-6-27': 'फूलपाती',
    '2081-6-28': 'महाअष्टमी',
    '2081-6-29': 'महानवमी',
    '2081-6-30': 'विजया दशमी',
    '2081-7-11': 'लक्ष्मी पूजा (तिहार)',
    '2081-7-13': 'भाइटीका',

    // ─── 2082 ──────────────────────────────────
    '2082-6-16': 'फूलपाती',
    '2082-6-17': 'महाअष्टमी',
    '2082-6-18': 'महानवमी',
    '2082-6-19': 'विजया दशमी',
    '2082-7-1': 'लक्ष्मी पूजा (तिहार)',
    '2082-7-3': 'भाइटीका',

    // ─── 2083 ──────────────────────────────────
    '2083-7-5': 'फूलपाती',
    '2083-7-6': 'महाअष्टमी',
    '2083-7-7': 'महानवमी',
    '2083-7-8': 'विजया दशमी',
    '2083-7-19': 'लक्ष्मी पूजा (तिहार)',
    '2083-7-21': 'भाइटीका',

    // ─── 2084 ──────────────────────────────────
    '2084-6-24': 'फूलपाती',
    '2084-6-25': 'महाअष्टमी',
    '2084-6-26': 'महानवमी',
    '2084-6-27': 'विजया दशमी',
    '2084-7-8': 'लक्ष्मी पूजा (तिहार)',
    '2084-7-10': 'भाइटीका',

    // ─── 2085 ──────────────────────────────────
    '2085-6-14': 'फूलपाती',
    '2085-6-15': 'महाअष्टमी',
    '2085-6-16': 'महानवमी',
    '2085-6-17': 'विजया दशमी',
    '2085-6-28': 'लक्ष्मी पूजा (तिहार)',
    '2085-6-30': 'भाइटीका',
  };

  /// Returns the holiday name for a given BS date, or null if none.
  static String? getHoliday(int year, int month, int day) {
    // Check year-specific first (takes precedence).
    final yearKey = '$year-$month-$day';
    if (_yearSpecificHolidays.containsKey(yearKey)) {
      return _yearSpecificHolidays[yearKey];
    }
    // Then check fixed holidays.
    final fixedKey = '$month-$day';
    return _fixedHolidays[fixedKey];
  }

  /// Returns true if the given BS date is a holiday.
  static bool isHoliday(int year, int month, int day) {
    return getHoliday(year, month, day) != null;
  }

  /// Returns all holidays in a given month as {day: name}.
  static Map<int, String> holidaysInMonth(int year, int month) {
    final result = <int, String>{};
    // Scan fixed holidays for this month.
    for (final entry in _fixedHolidays.entries) {
      final parts = entry.key.split('-');
      if (int.parse(parts[0]) == month) {
        result[int.parse(parts[1])] = entry.value;
      }
    }
    // Scan year-specific holidays for this year+month.
    for (final entry in _yearSpecificHolidays.entries) {
      final parts = entry.key.split('-');
      if (int.parse(parts[0]) == year && int.parse(parts[1]) == month) {
        result[int.parse(parts[2])] = entry.value;
      }
    }
    return result;
  }
}

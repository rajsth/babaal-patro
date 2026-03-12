import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads public holidays from the bundled JSON data files (artifact-YYYY.json).
/// Each JSON entry with `is_public_holiday: true` is indexed by its BS date.
/// Call [initialize] once at app startup before using the lookup methods.
///
/// To add a new year, simply add the file to pubspec.yaml assets — no code
/// changes required. All `assets/data/artifact-*.json` files are loaded
/// automatically via AssetManifest.
class CalendarDataService {
  CalendarDataService._();

  // Key: "year-month-day" (BS), Value: joined event names
  static final Map<String, String> _holidays = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final files = manifest
        .listAssets()
        .where((k) =>
            k.startsWith('assets/data/artifact-') && k.endsWith('.json'))
        .toList();

    for (final file in files) {
      final jsonString = await rootBundle.loadString(file);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      for (final entry in data.entries) {
        final value = entry.value as Map<String, dynamic>;
        if (value['is_public_holiday'] != true) continue;

        final nepaliDate = value['nepali_date'] as String; // e.g. "2082/11/6"
        final events = (value['events'] as List<dynamic>).cast<String>();
        if (events.isEmpty) continue;

        // Convert "2082/11/6" → "2082-11-6"
        final key = nepaliDate.replaceAll('/', '-');
        _holidays[key] = events.join(' · ');
      }
    }

    _initialized = true;
  }

  /// Returns the holiday name(s) for a BS date, or null if not a public holiday.
  static String? getHoliday(int year, int month, int day) {
    return _holidays['$year-$month-$day'];
  }

  /// Returns true if the given BS date is a public holiday.
  static bool isHoliday(int year, int month, int day) {
    return _holidays.containsKey('$year-$month-$day');
  }

  /// Returns all public holidays in a given BS month as {day: name}.
  static Map<int, String> holidaysInMonth(int year, int month) {
    final result = <int, String>{};
    for (final entry in _holidays.entries) {
      final parts = entry.key.split('-');
      if (parts.length == 3 &&
          int.parse(parts[0]) == year &&
          int.parse(parts[1]) == month) {
        result[int.parse(parts[2])] = entry.value;
      }
    }
    return result;
  }
}

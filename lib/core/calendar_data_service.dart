import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads calendar data from the bundled JSON files (artifact-YYYY.json).
/// Indexes public holidays, panchangam, and tithi keyed by BS date.
/// Call [initialize] once at app startup before using the lookup methods.
///
/// To add a new year, add the file to pubspec.yaml assets — no code changes
/// required. All `assets/data/artifact-*.json` files are discovered automatically.
class CalendarDataService {
  CalendarDataService._();

  // Key: "year-month-day" (BS)
  static final Map<String, String> _holidays = {};
  static final Map<String, List<String>> _events = {};
  static final Map<String, List<String>> _panchangam = {};
  static final Map<String, String> _tithi = {};
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
        final nepaliDate = value['nepali_date'] as String?;
        if (nepaliDate == null) continue;

        // "2082/11/6" → "2082-11-6"
        final key = nepaliDate.replaceAll('/', '-');

        // Panchangam — all dates
        final panchangamRaw = value['panchangam'];
        if (panchangamRaw is List && panchangamRaw.isNotEmpty) {
          _panchangam[key] = List<String>.from(panchangamRaw);
        }

        // Tithi — all dates
        final tithiRaw = value['tithi'];
        if (tithiRaw is String && tithiRaw.isNotEmpty) {
          _tithi[key] = tithiRaw;
        }

        // Events
        final eventsRaw = value['events'];
        if (eventsRaw is List && eventsRaw.isNotEmpty) {
          final eventsList = List<String>.from(eventsRaw);
          if (value['is_public_holiday'] == true) {
            _holidays[key] = eventsList.join(' · ');
          } else {
            _events[key] = eventsList;
          }
        }
      }
    }

    _initialized = true;
  }

  /// Returns the holiday name(s) for a BS date, or null if not a public holiday.
  static String? getHoliday(int year, int month, int day) =>
      _holidays['$year-$month-$day'];

  /// Returns true if the given BS date is a public holiday.
  static bool isHoliday(int year, int month, int day) =>
      _holidays.containsKey('$year-$month-$day');

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

  /// Returns non-holiday events for a BS date, or empty list if none.
  static List<String> getEvents(int year, int month, int day) =>
      _events['$year-$month-$day'] ?? const [];

  /// Returns the panchangam items for a BS date, or empty list if unavailable.
  static List<String> getPanchangam(int year, int month, int day) =>
      _panchangam['$year-$month-$day'] ?? const [];

  /// Returns the tithi for a BS date, or null if unavailable.
  static String? getTithi(int year, int month, int day) =>
      _tithi['$year-$month-$day'];
}

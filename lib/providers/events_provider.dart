import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple event/reminder model.
class CalendarEvent {
  final String title;
  final String dateKey; // "year-month-day"
  final bool isRecurring; // repeats every year on same BS month-day

  const CalendarEvent({
    required this.title,
    required this.dateKey,
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'dateKey': dateKey,
        'isRecurring': isRecurring,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] as String,
      dateKey: json['dateKey'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  /// Returns the month-day portion of the dateKey (e.g. "3-15").
  String get monthDayKey {
    final parts = dateKey.split('-');
    return '${parts[1]}-${parts[2]}';
  }
}

/// State: a map of dateKey → list of events.
class EventsNotifier extends StateNotifier<Map<String, List<CalendarEvent>>> {
  EventsNotifier() : super({}) {
    _load();
  }

  static const _storageKey = 'calendar_events';

  /// Cached index: monthDay key (e.g. "3-15") → list of recurring events.
  Map<String, List<CalendarEvent>> _recurringIndex = {};

  void _rebuildRecurringIndex() {
    final index = <String, List<CalendarEvent>>{};
    for (final events in state.values) {
      for (final event in events) {
        if (event.isRecurring) {
          index.putIfAbsent(event.monthDayKey, () => []).add(event);
        }
      }
    }
    _recurringIndex = index;
  }

  void _updateState(Map<String, List<CalendarEvent>> newState) {
    state = newState;
    _rebuildRecurringIndex();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List<dynamic> list = jsonDecode(raw);
      final events = list.map((e) => CalendarEvent.fromJson(e)).toList();
      final map = <String, List<CalendarEvent>>{};
      for (final event in events) {
        map.putIfAbsent(event.dateKey, () => []).add(event);
      }
      _updateState(map);
    } catch (_) {
      // Corrupted data — clear it to prevent repeated crashes.
      await prefs.remove(_storageKey);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final allEvents = state.values.expand((e) => e).toList();
    await prefs.setString(
      _storageKey,
      jsonEncode(allEvents.map((e) => e.toJson()).toList()),
    );
  }

  /// Add a new event for the given BS date.
  Future<void> addEvent(
    int year,
    int month,
    int day,
    String title, {
    bool isRecurring = false,
  }) async {
    final key = '$year-$month-$day';
    final current = Map<String, List<CalendarEvent>>.from(state);
    current.putIfAbsent(key, () => []);
    current[key] = [
      ...current[key]!,
      CalendarEvent(title: title, dateKey: key, isRecurring: isRecurring),
    ];
    _updateState(current);
    await _persist();
  }

  /// Remove an event by index for the given date.
  Future<void> removeEvent(int year, int month, int day, int index) async {
    final key = '$year-$month-$day';
    final current = Map<String, List<CalendarEvent>>.from(state);
    if (!current.containsKey(key)) return;
    final list = List<CalendarEvent>.from(current[key]!);
    if (index < list.length) list.removeAt(index);
    if (list.isEmpty) {
      current.remove(key);
    } else {
      current[key] = list;
    }
    _updateState(current);
    await _persist();
  }

  /// Returns true if the given date has at least one event (including recurring).
  bool hasEvents(int year, int month, int day) {
    if (state.containsKey('$year-$month-$day')) return true;
    return _recurringIndex.containsKey('$month-$day');
  }

  /// Returns events for a given date (including recurring from other years).
  List<CalendarEvent> eventsFor(int year, int month, int day) {
    final direct = state['$year-$month-$day'] ?? [];
    final dateKey = '$year-$month-$day';
    final recurring = _recurringIndex['$month-$day']
            ?.where((e) => e.dateKey != dateKey)
            .toList() ??
        [];
    return [...direct, ...recurring];
  }

  /// Returns all days that have events in a given month (including recurring).
  Set<int> eventDaysInMonth(int year, int month) {
    final prefix = '$year-$month-';
    final days = <int>{};
    for (final key in state.keys) {
      if (key.startsWith(prefix)) {
        final day = int.tryParse(key.substring(prefix.length));
        if (day != null) days.add(day);
      }
    }
    // Add recurring event days for this month from the cached index.
    final monthPrefix = '$month-';
    for (final monthDay in _recurringIndex.keys) {
      if (monthDay.startsWith(monthPrefix)) {
        final day = int.tryParse(monthDay.substring(monthPrefix.length));
        if (day != null) days.add(day);
      }
    }
    return days;
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, Map<String, List<CalendarEvent>>>(
        (ref) {
  return EventsNotifier();
});

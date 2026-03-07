import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  RemindersNotifier() : super([]) {
    _load();
  }

  static const _storageKey = 'reminders_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List<dynamic> list = jsonDecode(raw);
      state = list.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> addReminder(Reminder reminder) async {
    state = [...state, reminder];
    await _persist();
    await NotificationService.instance.scheduleReminder(reminder);
  }

  Future<void> removeReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _persist();
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
  }

  /// Flips isEnabled and immediately reschedules or cancels the notification.
  Future<void> toggleReminder(String id) async {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isEnabled: !r.isEnabled) else r,
    ];
    await _persist();
    final updated = state.firstWhere((r) => r.id == id);
    if (updated.isEnabled) {
      await NotificationService.instance.scheduleReminder(updated);
    } else {
      await NotificationService.instance.cancelReminder(id);
    }
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>(
  (ref) => RemindersNotifier(),
);

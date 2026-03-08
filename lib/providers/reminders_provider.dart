import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class RemindersNotifier extends StateNotifier<List<Reminder>> {
  final Ref _ref;

  RemindersNotifier(this._ref) : super([]) {
    _load();
    // React to sign-in / sign-out
    _ref.listen<User?>(authProvider, (prev, next) {
      if (prev?.uid != next?.uid) {
        _onAuthChanged(next);
      }
    });
  }

  static const _storageKey = 'reminders_v1';

  // ── Local persistence ──────────────────────────────────────────────────────

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
    // If already signed in when app starts, sync immediately.
    final uid = _ref.read(authProvider)?.uid;
    if (uid != null) await _syncWithFirestore(uid);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.map((r) => r.toJson()).toList()),
    );
  }

  // ── Firestore sync ─────────────────────────────────────────────────────────

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _syncWithFirestore(user.uid);
    }
    // On sign-out we keep local data as-is; Firestore writes simply stop.
  }

  /// Merge local reminders with Firestore:
  /// - Local-only → upload to Firestore
  /// - Cloud-only → add locally and reschedule notification
  /// - Both exist → cloud wins (last synced from another device)
  Future<void> _syncWithFirestore(String uid) async {
    try {
      final cloudReminders = await FirestoreService.instance.fetchReminders(uid);
      final localById = {for (final r in state) r.id: r};
      final cloudById = {for (final r in cloudReminders) r.id: r};

      // Upload local-only reminders to cloud
      final localOnly = localById.keys.where((id) => !cloudById.containsKey(id));
      for (final id in localOnly) {
        await FirestoreService.instance.upsertReminder(uid, localById[id]!);
      }

      // Merge: cloud wins for conflicts, union for unique items
      final merged = {...localById, ...cloudById};
      state = merged.values.toList();
      await _persist();

      // Schedule notifications for cloud-only reminders (new device scenario)
      for (final id in cloudById.keys.where((id) => !localById.containsKey(id))) {
        final r = cloudById[id]!;
        if (r.isEnabled) {
          await NotificationService.instance.scheduleReminder(r);
        }
      }
    } catch (_) {
      // Sync failure is non-fatal — local data remains intact.
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addReminder(Reminder reminder) async {
    state = [...state, reminder];
    await _persist();
    await NotificationService.instance.scheduleReminder(reminder);
    final uid = _ref.read(authProvider)?.uid;
    if (uid != null) {
      await FirestoreService.instance.upsertReminder(uid, reminder);
    }
  }

  Future<void> removeReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _persist();
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {}
    final uid = _ref.read(authProvider)?.uid;
    if (uid != null) {
      await FirestoreService.instance.deleteReminder(uid, id);
    }
  }

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
    final uid = _ref.read(authProvider)?.uid;
    if (uid != null) {
      await FirestoreService.instance.upsertReminder(uid, updated);
    }
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<Reminder>>(
  (ref) => RemindersNotifier(ref),
);

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Screen tracking ──────────────────────────────────────────────

  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  // ── Reminder events ──────────────────────────────────────────────

  Future<void> logReminderCreated({
    required String category,
    required String recurrence,
  }) {
    return _analytics.logEvent(name: 'reminder_created', parameters: {
      'category': category,
      'recurrence': recurrence,
    });
  }

  Future<void> logReminderDeleted() {
    return _analytics.logEvent(name: 'reminder_deleted');
  }

  // ── Converter events ─────────────────────────────────────────────

  Future<void> logDateConverted({required String direction}) {
    return _analytics.logEvent(name: 'date_converted', parameters: {
      'direction': direction,
    });
  }

  // ── Sign-in events ──────────────────────────────────────────────

  Future<void> logSignIn({required bool success}) {
    if (success) {
      return _analytics.logLogin(loginMethod: 'google');
    }
    return _analytics.logEvent(name: 'sign_in_failed');
  }

  Future<void> logSignOut() {
    return _analytics.logEvent(name: 'sign_out');
  }

  // ── Settings events ─────────────────────────────────────────────

  Future<void> logSettingChanged({
    required String setting,
    required String value,
  }) {
    return _analytics.logEvent(name: 'setting_changed', parameters: {
      'setting': setting,
      'value': value,
    });
  }

  // ── App update events ───────────────────────────────────────────

  Future<void> logUpdateChecked({required bool available}) {
    return _analytics.logEvent(name: 'update_checked', parameters: {
      'available': available.toString(),
    });
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

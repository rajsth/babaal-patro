import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Singleton service that owns all flutter_local_notifications interactions.
///
/// BS → AD Conversion rule:
///   Native schedulers only understand Gregorian DateTime. Every schedule call
///   converts the user's BS date via NepaliDateTime.toDateTime(), then subtracts
///   the chosen alertOffset to produce the exact moment to fire.
///
/// BS-aware Recurrence:
///   Because BS months have variable lengths (29–32 days), Monthly and Yearly
///   repeats cannot use fixed-interval timers. Instead we pre-schedule up to
///   24 individual occurrences (monthly) or 5 (yearly), each converted
///   independently from BS → AD, correctly handling variable month lengths.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'babaal_patro_reminders';
  static const _channelName = 'स्मरणहरू';
  static const _channelDesc = 'बबाल पात्रो – स्मरण सूचनाहरू';

  /// Reads the persisted language preference and returns the appropriate title.
  /// Falls back to Nepali (the app default) if the preference is not set.
  Future<String> _localizedTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final isNepali = prefs.getBool('is_nepali') ?? true;
    return isNepali ? 'तपाईंको एउटा रिमाइन्डर छ!' : 'You have a reminder';
  }

  String _notifBody(Reminder reminder) => reminder.description.isEmpty
      ? '➤ ${reminder.title}'
      : '➤ ${reminder.title}\n${reminder.description}';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    } catch (_) {
      // Fallback: system local timezone
    }

    const androidSettings =
        AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    try {
      await _plugin.initialize(settings);
    } catch (e) {
      debugPrint('NotificationService: initialize failed: $e');
    }
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── Public API ───────────────────────────────────────────────────

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await init();
    // Cancel any previously scheduled notifications for this reminder.
    await cancelReminder(reminder.id);
    if (!reminder.isEnabled) return;

    // On Android 12 (API 31-32), SCHEDULE_EXACT_ALARM requires explicit user
    // grant. On Android 13+, USE_EXACT_ALARM is auto-granted for calendar apps.
    // Fall back to inexactAllowWhileIdle when exact alarms are unavailable so
    // notifications still fire (possibly a few minutes late).
    final mode = await _resolveScheduleMode();
    final title = await _localizedTitle();

    switch (reminder.recurrence) {
      case ReminderRecurrence.none:
      case ReminderRecurrence.once:
        await _scheduleOnce(reminder, reminder.bsYear, reminder.bsMonth,
            reminder.bsDay, 0, mode, title);
      case ReminderRecurrence.daily:
        await _scheduleDaily(reminder, mode, title);
      case ReminderRecurrence.weekly:
        await _scheduleWeekly(reminder, mode, title);
      case ReminderRecurrence.monthly:
        // Pre-schedule next 24 BS-month occurrences (2 years).
        await _scheduleBsMonthly(reminder, mode, title);
      case ReminderRecurrence.yearly:
        // Pre-schedule next 5 BS-year occurrences.
        await _scheduleBsYearly(reminder, mode, title);
    }
  }

  /// Returns [AndroidScheduleMode.alarmClock] when exact alarms are permitted,
  /// otherwise [AndroidScheduleMode.inexactAllowWhileIdle] as a safe fallback.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> cancelReminder(String id) async {
    // Cancel all possible occurrence slots (max 24 for monthly).
    final base = _baseNotifId(id);
    for (int i = 0; i < 24; i++) {
      await _plugin.cancel(base + i);
    }
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── Scheduling helpers ───────────────────────────────────────────

  /// Schedules a single notification for the given BS date.
  Future<void> _scheduleOnce(Reminder reminder, int bsY, int bsM, int bsD,
      int slotIndex, AndroidScheduleMode mode, String title) async {
    final tzDt = _resolveAdDateTime(reminder, bsY, bsM, bsD);
    if (tzDt == null) return;
    if (tzDt.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id) + slotIndex,
      title,
      _notifBody(reminder),
      tzDt,
      _buildDetails(reminder.category),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Daily repeat using the built-in DateTimeComponents.time match.
  Future<void> _scheduleDaily(Reminder reminder, AndroidScheduleMode mode, String title) async {
    var tzDt = _resolveAdDateTime(
        reminder, reminder.bsYear, reminder.bsMonth, reminder.bsDay);
    if (tzDt == null) return;

    final now = tz.TZDateTime.now(tz.local);
    if (tzDt.isBefore(now)) tzDt = tzDt.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id),
      title,
      _notifBody(reminder),
      tzDt,
      _buildDetails(reminder.category),
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Weekly repeat using the built-in dayOfWeekAndTime match.
  Future<void> _scheduleWeekly(Reminder reminder, AndroidScheduleMode mode, String title) async {
    var tzDt = _resolveAdDateTime(
        reminder, reminder.bsYear, reminder.bsMonth, reminder.bsDay);
    if (tzDt == null) return;

    final now = tz.TZDateTime.now(tz.local);
    if (tzDt.isBefore(now)) tzDt = tzDt.add(const Duration(days: 7));

    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id),
      title,
      _notifBody(reminder),
      tzDt,
      _buildDetails(reminder.category),
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// BS-aware monthly: schedule up to 24 future occurrences individually.
  /// Each occurrence is converted from BS → AD independently, so variable
  /// month lengths (29–32 days) are handled correctly.
  Future<void> _scheduleBsMonthly(Reminder reminder, AndroidScheduleMode mode, String title) async {
    int bsY = reminder.bsYear;
    int bsM = reminder.bsMonth;

    for (int i = 0; i < 24; i++) {
      // Clamp day to the actual length of this BS month.
      final maxDays = _safeTotalDays(bsY, bsM);
      final bsD = reminder.bsDay.clamp(1, maxDays);
      await _scheduleOnce(reminder, bsY, bsM, bsD, i, mode, title);

      bsM++;
      if (bsM > 12) {
        bsM = 1;
        bsY++;
      }
    }
  }

  /// BS-aware yearly: schedule up to 5 future occurrences individually.
  Future<void> _scheduleBsYearly(Reminder reminder, AndroidScheduleMode mode, String title) async {
    for (int i = 0; i < 5; i++) {
      final bsY = reminder.bsYear + i;
      final maxDays = _safeTotalDays(bsY, reminder.bsMonth);
      final bsD = reminder.bsDay.clamp(1, maxDays);
      await _scheduleOnce(reminder, bsY, reminder.bsMonth, bsD, i, mode, title);
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────

  /// Converts the BS date + time to AD DateTime and applies the alert offset.
  /// Returns null if the BS date is invalid.
  ///
  /// The resulting TZDateTime is always in Asia/Kathmandu regardless of the
  /// device's system timezone (important for emulators set to UTC).
  tz.TZDateTime? _resolveAdDateTime(
      Reminder reminder, int bsY, int bsM, int bsD) {
    try {
      final adBase = NepaliDateTime(bsY, bsM, bsD).toDateTime();
      final kathmandu = tz.getLocation('Asia/Kathmandu');
      // Build the scheduled moment directly in NPT so the device timezone
      // does not affect the result.
      final dt = tz.TZDateTime(
          kathmandu, adBase.year, adBase.month, adBase.day,
          reminder.hour, reminder.minute);
      return _applyOffset(dt, reminder.alertOffset);
    } catch (_) {
      return null;
    }
  }

  tz.TZDateTime _applyOffset(tz.TZDateTime dt, AlertOffset offset) {
    switch (offset) {
      case AlertOffset.fifteenMin:
        return dt.subtract(const Duration(minutes: 15));
      case AlertOffset.oneHour:
        return dt.subtract(const Duration(hours: 1));
      case AlertOffset.oneDay:
        return dt.subtract(const Duration(days: 1));
      case AlertOffset.atTime:
        return dt;
    }
  }

  /// Stable integer notification ID derived from the reminder's string ID.
  /// We reserve 24 consecutive slots per reminder for recurrence occurrences.
  int _baseNotifId(String reminderId) =>
      (reminderId.hashCode.abs() % 9000000) * 24;

  int _safeTotalDays(int bsY, int bsM) {
    try {
      return NepaliDateTime(bsY, bsM).totalDays;
    } catch (_) {
      return 30;
    }
  }

  NotificationDetails _buildDetails(ReminderCategory category) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

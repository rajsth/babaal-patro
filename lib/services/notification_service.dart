import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nepali_utils/nepali_utils.dart';
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

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    } catch (_) {
      // Fallback: system local timezone
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
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

    switch (reminder.recurrence) {
      case ReminderRecurrence.none:
        await _scheduleOnce(reminder, reminder.bsYear, reminder.bsMonth,
            reminder.bsDay, 0);
      case ReminderRecurrence.daily:
        await _scheduleDaily(reminder);
      case ReminderRecurrence.weekly:
        await _scheduleWeekly(reminder);
      case ReminderRecurrence.monthly:
        // Pre-schedule next 24 BS-month occurrences (2 years).
        await _scheduleBsMonthly(reminder);
      case ReminderRecurrence.yearly:
        // Pre-schedule next 5 BS-year occurrences.
        await _scheduleBsYearly(reminder);
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
  Future<void> _scheduleOnce(
      Reminder reminder, int bsY, int bsM, int bsD, int slotIndex) async {
    final adDateTime = _resolveAdDateTime(reminder, bsY, bsM, bsD);
    if (adDateTime == null) return;
    if (adDateTime.isBefore(DateTime.now())) return;

    final tzDt = tz.TZDateTime.from(adDateTime, tz.local);
    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id) + slotIndex,
      reminder.title,
      reminder.description.isEmpty ? null : reminder.description,
      tzDt,
      _buildDetails(reminder.category),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Daily repeat using the built-in DateTimeComponents.time match.
  Future<void> _scheduleDaily(Reminder reminder) async {
    final adDateTime = _resolveAdDateTime(
        reminder, reminder.bsYear, reminder.bsMonth, reminder.bsDay);
    if (adDateTime == null) return;

    var dt = adDateTime.isBefore(DateTime.now())
        ? adDateTime.add(const Duration(days: 1))
        : adDateTime;

    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id),
      reminder.title,
      reminder.description.isEmpty ? null : reminder.description,
      tz.TZDateTime.from(dt, tz.local),
      _buildDetails(reminder.category),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Weekly repeat using the built-in dayOfWeekAndTime match.
  Future<void> _scheduleWeekly(Reminder reminder) async {
    final adDateTime = _resolveAdDateTime(
        reminder, reminder.bsYear, reminder.bsMonth, reminder.bsDay);
    if (adDateTime == null) return;

    var dt = adDateTime.isBefore(DateTime.now())
        ? adDateTime.add(const Duration(days: 7))
        : adDateTime;

    await _plugin.zonedSchedule(
      _baseNotifId(reminder.id),
      reminder.title,
      reminder.description.isEmpty ? null : reminder.description,
      tz.TZDateTime.from(dt, tz.local),
      _buildDetails(reminder.category),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// BS-aware monthly: schedule up to 24 future occurrences individually.
  /// Each occurrence is converted from BS → AD independently, so variable
  /// month lengths (29–32 days) are handled correctly.
  Future<void> _scheduleBsMonthly(Reminder reminder) async {
    int bsY = reminder.bsYear;
    int bsM = reminder.bsMonth;

    for (int i = 0; i < 24; i++) {
      // Clamp day to the actual length of this BS month.
      final maxDays = _safeTotalDays(bsY, bsM);
      final bsD = reminder.bsDay.clamp(1, maxDays);
      await _scheduleOnce(reminder, bsY, bsM, bsD, i);

      bsM++;
      if (bsM > 12) {
        bsM = 1;
        bsY++;
      }
    }
  }

  /// BS-aware yearly: schedule up to 5 future occurrences individually.
  Future<void> _scheduleBsYearly(Reminder reminder) async {
    for (int i = 0; i < 5; i++) {
      final bsY = reminder.bsYear + i;
      final maxDays = _safeTotalDays(bsY, reminder.bsMonth);
      final bsD = reminder.bsDay.clamp(1, maxDays);
      await _scheduleOnce(reminder, bsY, reminder.bsMonth, bsD, i);
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────

  /// Converts the BS date + time to AD DateTime and applies the alert offset.
  /// Returns null if the BS date is invalid.
  DateTime? _resolveAdDateTime(
      Reminder reminder, int bsY, int bsM, int bsD) {
    try {
      final adBase = NepaliDateTime(bsY, bsM, bsD).toDateTime();
      var dt = DateTime(
          adBase.year, adBase.month, adBase.day, reminder.hour, reminder.minute);
      return _applyOffset(dt, reminder.alertOffset);
    } catch (_) {
      return null;
    }
  }

  DateTime _applyOffset(DateTime dt, AlertOffset offset) {
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
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

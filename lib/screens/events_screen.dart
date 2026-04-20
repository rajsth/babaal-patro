import 'dart:async';

import 'package:flutter/material.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/reminders_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/add_event_dialog.dart' show showAddReminderSheet;

bool _isUpcoming(Reminder r, NepaliDateTime today) {
  if (r.recurrence == ReminderRecurrence.daily ||
      r.recurrence == ReminderRecurrence.weekly ||
      r.recurrence == ReminderRecurrence.monthly ||
      r.recurrence == ReminderRecurrence.yearly) {
    return true;
  }
  final cmp = r.bsYear != today.year
      ? r.bsYear - today.year
      : r.bsMonth != today.month
          ? r.bsMonth - today.month
          : r.bsDay - today.day;
  return cmp >= 0;
}

int _dateCompareAsc(Reminder a, Reminder b) {
  if (a.bsYear != b.bsYear) return a.bsYear - b.bsYear;
  if (a.bsMonth != b.bsMonth) return a.bsMonth - b.bsMonth;
  if (a.bsDay != b.bsDay) return a.bsDay - b.bsDay;
  if (a.hour != b.hour) return a.hour - b.hour;
  return a.minute - b.minute;
}

/// Sortable (year, month, day, hour, minute) key for the next occurrence
/// of [r] on or after [today]. For recurring reminders the original bsYear
/// (e.g. birth year) is ignored — only the next upcoming date matters.
List<int> _nextOccurrenceKey(Reminder r, NepaliDateTime today) {
  switch (r.recurrence) {
    case ReminderRecurrence.daily:
      return [today.year, today.month, today.day, r.hour, r.minute];
    case ReminderRecurrence.weekly:
      final origAd =
          NepaliDateTime(r.bsYear, r.bsMonth, r.bsDay).toDateTime();
      final todayAd = today.toDateTime();
      final offset = (origAd.weekday - todayAd.weekday + 7) % 7;
      final nextAd = todayAd.add(Duration(days: offset));
      final nextBs =
          NepaliDateHelper.adToBS(nextAd.year, nextAd.month, nextAd.day);
      return [nextBs.year, nextBs.month, nextBs.day, r.hour, r.minute];
    case ReminderRecurrence.monthly:
      final passed = today.day > r.bsDay;
      var year = today.year;
      var month = today.month + (passed ? 1 : 0);
      if (month > 12) {
        month = 1;
        year++;
      }
      return [year, month, r.bsDay, r.hour, r.minute];
    case ReminderRecurrence.yearly:
      final passed = today.month > r.bsMonth ||
          (today.month == r.bsMonth && today.day > r.bsDay);
      final year = passed ? today.year + 1 : today.year;
      return [year, r.bsMonth, r.bsDay, r.hour, r.minute];
    case ReminderRecurrence.none:
    case ReminderRecurrence.once:
      return [r.bsYear, r.bsMonth, r.bsDay, r.hour, r.minute];
  }
}

int _dayDiff(List<int> key, NepaliDateTime today) {
  final ad = NepaliDateTime(key[0], key[1], key[2]).toDateTime();
  final tAd = today.toDateTime();
  return DateTime.utc(ad.year, ad.month, ad.day)
      .difference(DateTime.utc(tAd.year, tAd.month, tAd.day))
      .inDays;
}

/// Both labels for a reminder tile's proximity/annotation line.
typedef _ReminderLabels = ({String? annotation, String? relative});

/// Builds the proximity label (near/far in calendar units) and an optional
/// annotation (turns-N for birthdays, Nth-year for anniversaries).
///
/// Design rules:
/// - Daily reminders: skipped entirely ("Today" is tautological).
/// - Recurring: always look forward — showing "X ago" for a yearly
///   birthday is misleading since it's also 365-X away.
/// - Bucketing uses BS calendar diffs; weeks only fill the gap when the
///   BS month hasn't rolled over (e.g. same-month reminders 7-27 days out).
/// - Age for birthdays/anniversaries is computed from AD years (matches
///   real-world age counts; BS-year diff can be off by 1 near New Year).
/// - Suppresses the annotation when `bsYear` looks like a placeholder
///   (equal to or after today's BS year).
_ReminderLabels _reminderLabels(
    Reminder r, NepaliDateTime today, S s, bool isNepali) {
  if (r.recurrence == ReminderRecurrence.daily) {
    return (annotation: null, relative: null);
  }

  final isRecurring = r.recurrence != ReminderRecurrence.none &&
      r.recurrence != ReminderRecurrence.once;

  final key = isRecurring
      ? _nextOccurrenceKey(r, today)
      : [r.bsYear, r.bsMonth, r.bsDay, r.hour, r.minute];
  final diff = _dayDiff(key, today);
  final absDays = diff.abs();
  final past = diff < 0;
  final monthDiff =
      ((key[0] - today.year) * 12 + (key[1] - today.month)).abs();

  String n(int v) => NepaliDateHelper.localizedNumeral(v, isNepali: isNepali);

  final String relative;
  if (diff == 0) {
    relative = s.todayLabel;
  } else if (diff == 1) {
    relative = s.tomorrowLabel;
  } else if (diff == -1) {
    relative = s.yesterdayLabel;
  } else if (absDays <= 6) {
    relative = past ? s.daysAgo(n(absDays)) : s.daysLater(n(absDays));
  } else if (monthDiff >= 12) {
    final y = monthDiff ~/ 12;
    relative = past ? s.yearsAgo(n(y)) : s.yearsLater(n(y));
  } else if (monthDiff >= 1) {
    relative = past ? s.monthsAgo(n(monthDiff)) : s.monthsLater(n(monthDiff));
  } else {
    // 7-27 days inside the same BS month — weeks read more naturally.
    final w = absDays ~/ 7;
    relative = past ? s.weeksAgo(n(w)) : s.weeksLater(n(w));
  }

  String? annotation;
  if (r.recurrence == ReminderRecurrence.yearly && r.bsYear < today.year) {
    final originalAd =
        NepaliDateTime(r.bsYear, r.bsMonth, r.bsDay).toDateTime();
    final nextAd = NepaliDateTime(key[0], key[1], key[2]).toDateTime();
    final age = nextAd.year - originalAd.year;
    if (age >= 1) {
      if (r.category == ReminderCategory.birthday) {
        annotation = s.turnsAge(n(age));
      } else if (r.category == ReminderCategory.anniversary) {
        annotation = _anniversaryLabel(age, isNepali);
      }
    }
  }

  return (annotation: annotation, relative: relative);
}

String _anniversaryLabel(int years, bool isNepali) {
  final n = NepaliDateHelper.localizedNumeral(years, isNepali: isNepali);
  if (isNepali) return '$n औँ वर्ष';
  return '$n${_enOrdinalSuffix(years)} year';
}

String _enOrdinalSuffix(int v) {
  if (v % 100 >= 11 && v % 100 <= 13) return 'th';
  return switch (v % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}

int _compareReminders(Reminder a, Reminder b, NepaliDateTime today) {
  if (a.isEnabled != b.isEnabled) return a.isEnabled ? -1 : 1;
  final aUp = _isUpcoming(a, today);
  final bUp = _isUpcoming(b, today);
  if (aUp != bUp) return aUp ? -1 : 1;
  if (aUp) {
    final ka = _nextOccurrenceKey(a, today);
    final kb = _nextOccurrenceKey(b, today);
    for (var i = 0; i < ka.length; i++) {
      if (ka[i] != kb[i]) return ka[i] - kb[i];
    }
    return 0;
  }
  // Past: most recent first (descending).
  return _dateCompareAsc(b, a);
}

/// Reminders screen — lists all scheduled local-notification reminders.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  ReminderCategory? _activeFilter;
  bool _bannerDismissed = false;
  Timer? _dayTicker;
  int _lastBsDay = NepaliDateHelper.today().day;

  @override
  void initState() {
    super.initState();
    // Rebuild once per minute iff the BS day has rolled over so "Today",
    // "Tomorrow", and the relative countdowns don't go stale past midnight.
    _dayTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      final d = NepaliDateHelper.today().day;
      if (d != _lastBsDay && mounted) {
        _lastBsDay = d;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _dayTicker?.cancel();
    super.dispose();
  }

  void _showBackupNudge() {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.saveReminders,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.backupDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ref.read(authProvider.notifier).signInWithGoogle();
                  ref.read(analyticsServiceProvider).logSignIn(success: ok);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  s.signInWithGoogle,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                s.later,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    final today = NepaliDateHelper.today();
    final sorted = ref.watch(
      remindersProvider.select(
        (list) => [...list]..sort((a, b) => _compareReminders(a, b, today)),
      ),
    );
    final user = ref.watch(authProvider);

    // Show cloud sync confirmation when user signs in
    ref.listen<dynamic>(authProvider, (prev, next) {
      if (prev == null && next != null) {
        setState(() => _bannerDismissed = true);
        final ls = S.of(ref.read(languageProvider));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ls.remindersSyncedToCloud,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ls.allRemindersSyncAuto,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    // Detect first reminder added while not signed in → show nudge
    ref.listen<List<Reminder>>(remindersProvider, (prev, next) {
      if (user == null && (prev?.isEmpty ?? true) && next.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBackupNudge();
        });
      }
    });

    final visible = _activeFilter == null
        ? sorted
        : sorted.where((r) => r.category == _activeFilter).toList();

    // Precompute the proximity/annotation labels once per render so each
    // tile build doesn't re-run the BS→AD conversion chain.
    final labelCache = <String, _ReminderLabels>{
      for (final r in visible)
        r.id: _reminderLabels(r, today, s, isNepali),
    };

    final usedCategories = {for (final r in sorted) r.category};
    final showBanner = user == null && sorted.isNotEmpty && !_bannerDismissed;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddReminderSheet(context),
        backgroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                s.reminders,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),

            // ── Sync banner ──────────────────────────────────────────
            if (showBanner)
              _SyncBanner(
                colors: colors,
                isNepali: isNepali,
                onSignIn: () async {
                  final ok = await ref
                      .read(authProvider.notifier)
                      .signInWithGoogle();
                  ref.read(analyticsServiceProvider).logSignIn(success: ok);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.signInFailed)),
                    );
                  }
                },
                onDismiss: () => setState(() => _bannerDismissed = true),
              ),

            // ── Category filter bar ──────────────────────────────────
            if (sorted.isNotEmpty)
              _FilterBar(
                usedCategories: usedCategories,
                activeFilter: _activeFilter,
                isNepali: isNepali,
                onSelect: (cat) => setState(
                  () => _activeFilter = _activeFilter == cat ? null : cat,
                ),
                colors: colors,
              ),

            // ── Reminder list ────────────────────────────────────────
            Expanded(
              child: user != null
                  ? RefreshIndicator(
                      color: AppTheme.accent,
                      onRefresh: () => ref
                          .read(remindersProvider.notifier)
                          .refreshFromCloud(),
                      child: visible.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: _EmptyState(
                                    filtered: _activeFilter != null,
                                    isNepali: isNepali,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              itemCount: visible.length,
                              itemBuilder: (context, i) {
                                final reminder = visible[i];
                                return _ReminderTile(
                                  key: ValueKey(reminder.id),
                                  reminder: reminder,
                                  labels: labelCache[reminder.id]!,
                                  colors: colors,
                                  isNepali: isNepali,
                                  onDelete: () {
                                    Haptic.light();
                                    ref
                                        .read(remindersProvider.notifier)
                                        .removeReminder(reminder.id);
                                  },
                                );
                              },
                            ),
                    )
                  : visible.isEmpty
                      ? _EmptyState(
                          filtered: _activeFilter != null,
                          isNepali: isNepali,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final reminder = visible[i];
                            return _ReminderTile(
                              key: ValueKey(reminder.id),
                              reminder: reminder,
                              labels: labelCache[reminder.id]!,
                              colors: colors,
                              isNepali: isNepali,
                              onDelete: () {
                                Haptic.light();
                                ref
                                    .read(remindersProvider.notifier)
                                    .removeReminder(reminder.id);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sync banner ──────────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  final NepaliThemeColors colors;
  final bool isNepali;
  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  const _SyncBanner({
    required this.colors,
    required this.isNepali,
    required this.onSignIn,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(isNepali);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: SelectionArea(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.signInToKeepSafe,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                s.signIn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 16, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final Set<ReminderCategory> usedCategories;
  final ReminderCategory? activeFilter;
  final void Function(ReminderCategory) onSelect;
  final NepaliThemeColors colors;
  final bool isNepali;

  const _FilterBar({
    required this.usedCategories,
    required this.activeFilter,
    required this.onSelect,
    required this.colors,
    required this.isNepali,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ReminderCategory.values.where(usedCategories.contains).map((
          cat,
        ) {
          final isSelected = activeFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Haptic.selection();
                onSelect(cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.6)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 13,
                      color: isSelected
                          ? AppTheme.accent
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.localizedLabel(isNepali),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.accent
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool filtered;
  final bool isNepali;
  const _EmptyState({this.filtered = false, required this.isNepali});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final s = S.of(isNepali);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered
                ? Icons.filter_list_off_rounded
                : Icons.notifications_none_rounded,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            filtered ? s.noCategoryReminders : s.noRemindersAdded,
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? s.chooseDifferentCategory
                : s.tapPlusToAdd,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final _ReminderLabels labels;
  final NepaliThemeColors colors;
  final bool isNepali;
  final VoidCallback onDelete;

  const _ReminderTile({
    super.key,
    required this.reminder,
    required this.labels,
    required this.colors,
    required this.isNepali,
    required this.onDelete,
  });

  String get _bsDateStr =>
      '${NepaliDateHelper.localizedNumeral(reminder.bsDay, isNepali: isNepali)} '
      '${NepaliDateHelper.monthName(reminder.bsMonth, isNepali: isNepali)} '
      '${NepaliDateHelper.localizedNumeral(reminder.bsYear, isNepali: isNepali)}';

  String get _adDateStr {
    try {
      final ad = NepaliDateTime(
        reminder.bsYear,
        reminder.bsMonth,
        reminder.bsDay,
      ).toDateTime();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${m[ad.month - 1]} ${ad.day}, ${ad.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adDateStr = _adDateStr;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.saturday.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_outline, color: AppTheme.saturday, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Haptic.selection();
              showAddReminderSheet(context, existingReminder: reminder);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      reminder.category.icon,
                      size: 20,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            reminder.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                adDateStr.isEmpty
                                    ? _bsDateStr
                                    : '$_bsDateStr  ·  $adDateStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (labels.relative != null ||
                            labels.annotation != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (labels.relative != null)
                                Text(
                                  labels.relative!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              if (labels.relative != null &&
                                  labels.annotation != null)
                                const SizedBox(width: 8),
                              if (labels.annotation != null)
                                Flexible(
                                  child: Text(
                                    labels.annotation!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _InfoBadge(
                              icon: Icons.access_time_rounded,
                              label: reminder.timeLabel,
                              colors: colors,
                            ),
                            _InfoBadge(
                              icon: Icons.repeat_rounded,
                              label: reminder.recurrence.localizedLabel(isNepali),
                              colors: colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final NepaliThemeColors colors;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colors.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/calendar_data_service.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
import '../providers/calendar_provider.dart';
import '../providers/reminders_provider.dart';
import '../providers/language_provider.dart';
import 'add_event_dialog.dart' show showAddReminderSheet;

/// A bottom card that shows details of the selected date:
/// day of week, BS date, AD date, tithi, holiday, panchangam,
/// user reminders, and an add-reminder CTA.
class SelectedDateBanner extends ConsumerWidget {
  const SelectedDateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final selected = state.selectedDate;

    if (selected == null) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    final dayName = s.dayFullNames[selected.weekday - 1];
    final nepaliDate =
        '${NepaliDateHelper.localizedNumeral(selected.day, isNepali: isNepali)} '
        '${NepaliDateHelper.monthName(selected.month, isNepali: isNepali)} '
        '${NepaliDateHelper.localizedNumeral(selected.year, isNepali: isNepali)}';
    final adDate = NepaliDateHelper.toADString(
        selected.year, selected.month, selected.day);

    final calendarData = ref.watch(calendarDataProvider);
    final holiday =
        calendarData.getHoliday(selected.year, selected.month, selected.day);
    final events =
        calendarData.getEvents(selected.year, selected.month, selected.day);
    final tithi =
        calendarData.getTithi(selected.year, selected.month, selected.day);
    final panchangam =
        calendarData.getPanchangam(selected.year, selected.month, selected.day);

    // Filter reminders for the selected BS date.
    final reminders = ref.watch(remindersProvider).where((r) =>
        r.bsYear == selected.year &&
        r.bsMonth == selected.month &&
        r.bsDay == selected.day).toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(
            '${selected.year}-${selected.month}-${selected.day}-${reminders.length}'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Day of week ──────────────────────────────────────────
            Text(
              dayName,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.accentLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            // ── BS Date ──────────────────────────────────────────────
            Text(
              nepaliDate,
              style: TextStyle(
                fontSize: 24,
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            // ── AD Date · Tithi ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  adDate,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                if (tithi != null) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary.withValues(alpha: 0.5)),
                  ),
                  Text(
                    tithi,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ],
            ),

            // ── Holiday badge ─────────────────────────────────────────
            if (holiday != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.todayHighlight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  holiday,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.todayHighlight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // ── Non-holiday events ───────────────────────────────────
            if (events.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.events,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent.withValues(alpha: 0.7),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...events.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Panchangam section ────────────────────────────────────
            if (panchangam.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.panchangam,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...panchangam.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── User reminders ────────────────────────────────────────
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...reminders.map((reminder) {
                return Dismissible(
                  key: ValueKey(reminder.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref
                        .read(remindersProvider.notifier)
                        .removeReminder(reminder.id);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.saturday.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.delete_outline,
                      color: AppTheme.saturday,
                      size: 20,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          reminder.category.icon,
                          size: 15,
                          color: AppTheme.accent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (reminder.description.isNotEmpty)
                                Text(
                                  reminder.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reminder.timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swipe_left_outlined,
                          size: 14,
                          color: colors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // ── Add reminder CTA ──────────────────────────────────────
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showAddReminderSheet(context, initialDate: selected);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    s.addReminder,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

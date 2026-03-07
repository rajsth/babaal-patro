import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../core/nepali_holidays.dart';
import '../providers/calendar_provider.dart';
import '../providers/events_provider.dart';
import 'add_event_dialog.dart';

/// A bottom card that shows details of the selected date,
/// including the Nepali full day name, AD equivalent,
/// holiday name, and user events with add/delete.
class SelectedDateBanner extends ConsumerWidget {
  const SelectedDateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final selected = state.selectedDate;

    if (selected == null) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final dayName = NepaliDateHelper.dayFullNames[selected.weekday - 1];
    final nepaliDate =
        '${NepaliDateHelper.toNepaliNumeral(selected.day)} '
        '${NepaliDateHelper.monthName(selected.month)} '
        '${NepaliDateHelper.toNepaliNumeral(selected.year)}';
    final adDate = NepaliDateHelper.toADString(
      selected.year,
      selected.month,
      selected.day,
    );
    final holiday = NepaliHolidays.getHoliday(
      selected.year,
      selected.month,
      selected.day,
    );

    // Watch the provider but derive only events for the selected date.
    ref.watch(eventsProvider);
    final events = ref.read(eventsProvider.notifier).eventsFor(
          selected.year, selected.month, selected.day);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(
            '${selected.year}-${selected.month}-${selected.day}-${events.length}'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.accentLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nepaliDate,
              style: TextStyle(
                fontSize: 22,
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              adDate,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            // Holiday badge
            if (holiday != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.todayHighlight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  holiday,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.todayHighlight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            // Events list
            if (events.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...events.asMap().entries.map((entry) {
                return Dismissible(
                  key: ValueKey(
                      '${selected.year}-${selected.month}-${selected.day}-${entry.key}-${entry.value.title}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(eventsProvider.notifier).removeEvent(
                          selected.year,
                          selected.month,
                          selected.day,
                          entry.key,
                        );
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
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: entry.value.isRecurring
                                ? AppTheme.accent
                                : AppTheme.eventDot,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(width: 8, height: 8),
                        ),
                        const SizedBox(width: 10),
                        if (entry.value.isRecurring) ...[
                          Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: AppTheme.accent.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            entry.value.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
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
            // Add event button
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AddEventDialog(date: selected),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    'घटना थप्नुहोस्',
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

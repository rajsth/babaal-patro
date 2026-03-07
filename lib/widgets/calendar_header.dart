import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/calendar_provider.dart';
import 'month_year_picker.dart';

/// Displays the current Nepali month/year with navigation arrows,
/// the corresponding AD month range, and a "today" button.
/// Tapping the title opens the year/month picker.
class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AD date range subtitle
          Text(
            state.adRangeSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // Bottom row: month/year + dropdown (left) | today + nav arrows (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month-Year title (tappable)
              GestureDetector(
                onTap: () => showMonthYearPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.headerTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Today button + navigation arrows
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: notifier.goToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'आज',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.previousMonth();
                    },
                    icon: const Icon(Icons.chevron_left, size: 26),
                    tooltip: 'अघिल्लो महिना',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.nextMonth();
                    },
                    icon: const Icon(Icons.chevron_right, size: 26),
                    tooltip: 'अर्को महिना',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

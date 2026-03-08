import 'package:flutter/material.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../core/nepali_holidays.dart';
import '../providers/calendar_provider.dart';

/// Displays all holidays for the currently shown month.
class MonthlyHolidays extends ConsumerWidget {
  const MonthlyHolidays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when year or month changes, not on date selection.
    final year = ref.watch(calendarProvider.select((s) => s.year));
    final month = ref.watch(calendarProvider.select((s) => s.month));
    final holidays = NepaliHolidays.holidaysInMonth(year, month);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    if (holidays.isEmpty) return const SizedBox.shrink();

    // Sort by day.
    final sortedEntries = holidays.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${NepaliDateHelper.monthName(month)}का बिदाहरू',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedEntries.map((entry) => GestureDetector(
                onTap: () {
                  Haptic.light();
                  ref.read(calendarProvider.notifier).selectDay(entry.key);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.saturday.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${NepaliDateHelper.toNepaliNumeral(entry.key)} गते',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.saturday,
                              ),
                            ),
                            Text(
                              NepaliDateHelper.weekdayName(
                                  year, month, entry.key),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.saturday
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

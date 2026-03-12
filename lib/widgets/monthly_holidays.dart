import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../core/calendar_data_service.dart';
import '../providers/calendar_provider.dart';
import '../providers/language_provider.dart';

/// Displays all holidays for the currently shown month.
class MonthlyHolidays extends ConsumerWidget {
  const MonthlyHolidays({super.key});

  /// Returns the number of days between today and the given BS date.
  /// Negative = past, positive = future, 0 = today.
  int _dayDifference(int year, int month, int day) {
    final holidayAd = NepaliDateTime(year, month, day).toDateTime();
    final todayAd = DateTime.now();
    final hDate = DateTime(holidayAd.year, holidayAd.month, holidayAd.day);
    final tDate = DateTime(todayAd.year, todayAd.month, todayAd.day);
    return hDate.difference(tDate).inDays;
  }

  String _relativeLabel(int diff, S s, bool isNepali) {
    if (diff == 0) return s.todayLabel;
    if (diff == -1) return s.yesterdayLabel;
    if (diff == 1) return s.tomorrowLabel;
    if (diff < 0) {
      final n = isNepali
          ? NepaliDateHelper.toNepaliNumeral(-diff)
          : '${-diff}';
      return s.daysAgo(n);
    }
    final n = isNepali
        ? NepaliDateHelper.toNepaliNumeral(diff)
        : '$diff';
    return s.daysLater(n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when year or month changes, not on date selection.
    final year = ref.watch(calendarProvider.select((s) => s.year));
    final month = ref.watch(calendarProvider.select((s) => s.month));
    final holidays = CalendarDataService.holidaysInMonth(year, month);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

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
            s.holidaysOf(NepaliDateHelper.monthName(month, isNepali: isNepali)),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedEntries.map((entry) {
            final diff = _dayDifference(year, month, entry.key);
            final relLabel = _relativeLabel(diff, s, isNepali);
            return GestureDetector(
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
                              s.gate(NepaliDateHelper.localizedNumeral(entry.key, isNepali: isNepali)),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.saturday,
                              ),
                            ),
                            Text(
                              NepaliDateHelper.weekdayName(
                                  year, month, entry.key,
                                  isNepali: isNepali),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              relLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: diff == 0
                                    ? AppTheme.accent
                                    : colors.textSecondary,
                                fontWeight: diff == 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
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
              );
          }),
        ],
      ),
    );
  }
}

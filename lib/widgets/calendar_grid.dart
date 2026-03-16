import 'package:flutter/material.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../core/calendar_data_service.dart';
import '../providers/calendar_provider.dart';
import '../providers/reminders_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';

/// The main calendar grid displaying day numbers in a 7-column layout,
/// with holiday dots, event dots, Material ripple, haptic feedback,
/// and accessibility semantics on every cell.
class CalendarGrid extends ConsumerWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final gridDays = state.gridDays;
    final holidays = CalendarDataService.holidaysInMonth(
      state.year,
      state.month,
    );
    final eventDays = ref
        .watch(remindersProvider)
        .where((r) => r.bsYear == state.year && r.bsMonth == state.month)
        .map((r) => r.bsDay)
        .toSet();
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final showBorder = ref.watch(
      settingsProvider.select((s) => s.showGridBorder),
    );
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    final leadingDays = NepaliDateHelper.previousMonthTrailingDays(
      state.year,
      state.month,
    );
    final trailingCount = NepaliDateHelper.trailingBlanks(
      state.year,
      state.month,
    );
    final totalCells = gridDays.length + trailingCount;

    // Pre-compute AD day numbers for all days in the month to avoid
    // creating NepaliDateTime objects per cell during build.
    final daysInMonth = NepaliDateHelper.daysInMonth(state.year, state.month);
    final adDays = List<int>.generate(
      daysInMonth,
      (i) => NepaliDateHelper.toADDay(state.year, state.month, i + 1),
    );

    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final dateFontSize = isTablet ? 28.0 : 18.0;
    final fadedDateFontSize = isTablet ? 26.0 : 14.0;
    final adDayFontSize = isTablet ? 14.0 : 10.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        // Leading days from previous month
        if (index < leadingDays.length) {
          return Container(
            decoration: showBorder
                ? BoxDecoration(
                    border: Border.all(
                      color: colors.divider.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(3),
            child: Center(
              child: Text(
                NepaliDateHelper.toNepaliNumeral(leadingDays[index]),
                style: TextStyle(
                  fontSize: fadedDateFontSize,
                  color: colors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }

        // Trailing days from next month
        if (index >= gridDays.length) {
          final trailingDay = index - gridDays.length + 1;
          return Container(
            decoration: showBorder
                ? BoxDecoration(
                    border: Border.all(
                      color: colors.divider.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(3),
            child: Center(
              child: Text(
                NepaliDateHelper.toNepaliNumeral(trailingDay),
                style: TextStyle(
                  fontSize: fadedDateFontSize,
                  color: colors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }

        final day = gridDays[index];
        if (day == null) return const SizedBox.shrink();

        final isToday = state.isToday(day);
        final isSelected = state.isSelected(day);
        final isSaturday = index % 7 == 6;
        final isHoliday = holidays.containsKey(day);
        final hasEvent = eventDays.contains(day);
        final holidayName = holidays[day];

        // Build semantic label for screen readers.
        final dayName = s.dayFullNames[index % 7];
        final semanticParts = <String>[
          NepaliDateHelper.toNepaliNumeral(day),
          NepaliDateHelper.monthName(state.month, isNepali: isNepali),
          dayName,
        ];
        if (isToday) semanticParts.add(s.todaySemantic);
        if (isHoliday) semanticParts.add(s.holidaySemantic(holidayName!));
        if (hasEvent) semanticParts.add(s.hasEventSemantic);

        return Semantics(
          label: semanticParts.join(', '),
          button: true,
          selected: isSelected,
          child: Container(
            decoration: showBorder
                ? BoxDecoration(
                    border: Border.all(
                      color: colors.divider.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(3),
            child: Material(
              color: isSelected
                  ? AppTheme.accent
                  : isToday
                  ? AppTheme.todayHighlight.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Haptic.light();
                  notifier.selectDay(day);
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: AppTheme.accent.withValues(alpha: 0.25),
                highlightColor: AppTheme.accent.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.todayHighlight, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Centered BS date + dot indicators
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NepaliDateHelper.toNepaliNumeral(day),
                              style: TextStyle(
                                fontSize: dateFontSize,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                    ? AppTheme.todayHighlight
                                    : (isSaturday || isHoliday)
                                    ? AppTheme.saturday
                                    : colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isHoliday)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.todayHighlight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasEvent)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.eventDot,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (!isHoliday && !hasEvent)
                                  const SizedBox(height: 5),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // AD day number at bottom-left
                      Positioned(
                        right: 4,
                        bottom: 2,
                        child: Text(
                          adDays[day - 1].toString(),
                          style: TextStyle(
                            fontSize: adDayFontSize,
                            color: isSelected
                                ? Colors.white70
                                : colors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../providers/calendar_provider.dart';
import '../providers/language_provider.dart';
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
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BS month/year row with dropdown + today + nav arrows
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
                      state.localizedHeaderTitle(isNepali),
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
                        s.today,
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
                      Haptic.light();
                      notifier.previousMonth();
                    },
                    icon: const Icon(Icons.chevron_left, size: 26),
                    tooltip: s.previousMonth,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Haptic.light();
                      notifier.nextMonth();
                    },
                    icon: const Icon(Icons.chevron_right, size: 26),
                    tooltip: s.nextMonth,
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
          const SizedBox(height: 2),
          // AD date range subtitle
          Text(
            state.adRangeSubtitle,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

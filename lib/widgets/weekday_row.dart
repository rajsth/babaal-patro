import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';

/// A single row showing the abbreviated Nepali day-of-week labels.
/// Saturday (last column) is highlighted red per Nepali convention.
class WeekdayRow extends StatelessWidget {
  const WeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final isSaturday = index == 6;
          return Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: isSaturday
                    ? BoxDecoration(
                        color: AppTheme.saturday.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  NepaliDateHelper.dayNames[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSaturday
                        ? AppTheme.saturday
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

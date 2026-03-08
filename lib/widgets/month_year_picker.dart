import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../providers/calendar_provider.dart';
import '../providers/language_provider.dart';

/// A bottom-sheet dialog that lets users quickly jump to any BS year/month.
class MonthYearPicker extends ConsumerStatefulWidget {
  const MonthYearPicker({super.key});

  @override
  ConsumerState<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends ConsumerState<MonthYearPicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late final FixedExtentScrollController _yearController;

  static const int _minYear = 2000;
  static const int _maxYear = 2090;

  @override
  void initState() {
    super.initState();
    final state = ref.read(calendarProvider);
    _selectedYear = state.year;
    _selectedMonth = state.month;
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _minYear,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            s.selectYearMonth,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Year wheel picker
          SizedBox(
            height: 120,
            child: ListWheelScrollView.useDelegate(
              controller: _yearController,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() => _selectedYear = _minYear + index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _maxYear - _minYear + 1,
                builder: (context, index) {
                  final year = _minYear + index;
                  final isActive = year == _selectedYear;
                  return Center(
                    child: Text(
                      NepaliDateHelper.localizedNumeral(year, isNepali: isNepali),
                      style: TextStyle(
                        fontSize: isActive ? 22 : 16,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive
                            ? AppTheme.accent
                            : colors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Month grid (4 x 3)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isActive = month == _selectedMonth;
              return GestureDetector(
                onTap: () => setState(() => _selectedMonth = month),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accent : colors.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? AppTheme.accent : colors.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.monthNames[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref
                    .read(calendarProvider.notifier)
                    .goToMonth(_selectedYear, _selectedMonth);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s.go,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to show the picker as a modal bottom sheet.
void showMonthYearPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const MonthYearPicker(),
  );
}

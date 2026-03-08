import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/nepali_date_helper.dart';

/// Immutable state representing the currently displayed month and any
/// selected date in the calendar.
/// Direction of the most recent month navigation (used for slide animation).
enum SlideDirection { none, left, right }

class CalendarState {
  final int year;
  final int month;
  final NepaliDateTime? selectedDate;
  final NepaliDateTime today;
  /// Cached grid to avoid recomputation on every widget rebuild.
  final List<int?> gridDays;
  /// Direction of the last navigation for slide transitions.
  final SlideDirection slideDirection;

  CalendarState({
    required this.year,
    required this.month,
    required this.today,
    this.selectedDate,
    this.slideDirection = SlideDirection.none,
  }) : gridDays = NepaliDateHelper.calendarGridDays(year, month);

  CalendarState copyWith({
    int? year,
    int? month,
    NepaliDateTime? selectedDate,
    bool clearSelection = false,
    SlideDirection? slideDirection,
  }) {
    return CalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      today: today,
      selectedDate: clearSelection ? null : (selectedDate ?? this.selectedDate),
      slideDirection: slideDirection ?? SlideDirection.none,
    );
  }

  /// Formatted header for the current month: "बैशाख २०८२" or "Baisakh 2082"
  String get headerTitle => NepaliDateHelper.formattedMonthYear(year, month);

  /// Language-aware header title.
  String localizedHeaderTitle(bool isNepali) =>
      NepaliDateHelper.formattedMonthYear(year, month, isNepali: isNepali);

  /// AD month range string for the current BS month (e.g., "Mar - Apr 2026").
  String get adRangeSubtitle {
    final firstAD = NepaliDateTime(year, month, 1).toDateTime();
    final lastDay = NepaliDateHelper.daysInMonth(year, month);
    final lastAD = NepaliDateTime(year, month, lastDay).toDateTime();
    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final startMonth = shortMonths[firstAD.month - 1];
    final endMonth = shortMonths[lastAD.month - 1];
    if (firstAD.year == lastAD.year) {
      if (startMonth == endMonth) return '$startMonth ${firstAD.year}';
      return '$startMonth - $endMonth ${firstAD.year}';
    }
    return '$startMonth ${firstAD.year} - $endMonth ${lastAD.year}';
  }

  bool isToday(int day) {
    return year == today.year && month == today.month && day == today.day;
  }

  bool isSelected(int day) {
    if (selectedDate == null) return false;
    return year == selectedDate!.year &&
        month == selectedDate!.month &&
        day == selectedDate!.day;
  }
}

/// Notifier that manages calendar navigation and date selection.
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(
          CalendarState(
            year: NepaliDateHelper.today().year,
            month: NepaliDateHelper.today().month,
            today: NepaliDateHelper.today(),
            // Auto-select today on launch.
            selectedDate: NepaliDateHelper.today(),
          ),
        );

  /// Supported BS year range from nepali_utils.
  static const int _minYear = 2000;
  static const int _maxYear = 2090;

  void nextMonth() {
    int newMonth = state.month + 1;
    int newYear = state.year;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    if (newYear > _maxYear) return; // guard upper bound
    state = state.copyWith(
      year: newYear,
      month: newMonth,
      clearSelection: true,
      slideDirection: SlideDirection.left,
    );
  }

  void previousMonth() {
    int newMonth = state.month - 1;
    int newYear = state.year;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    if (newYear < _minYear) return; // guard lower bound
    state = state.copyWith(
      year: newYear,
      month: newMonth,
      clearSelection: true,
      slideDirection: SlideDirection.right,
    );
  }

  /// Jump to a specific year and month (used by the picker).
  void goToMonth(int year, int month) {
    final clampedYear = year.clamp(_minYear, _maxYear);
    state = state.copyWith(
      year: clampedYear,
      month: month,
      clearSelection: true,
    );
  }

  void goToToday() {
    final now = NepaliDateHelper.today();
    state = state.copyWith(
      year: now.year,
      month: now.month,
      selectedDate: now,
    );
  }

  void selectDay(int day) {
    state = state.copyWith(
      selectedDate: NepaliDateTime(state.year, state.month, day),
    );
  }
}

/// The single global provider for calendar state.
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});

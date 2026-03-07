import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/calendar_header.dart';
import '../widgets/weekday_row.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/selected_date_banner.dart';
import '../widgets/monthly_holidays.dart';

/// Main screen that composes the calendar header, day labels,
/// date grid, and selected-date banner. Supports horizontal swipe
/// to navigate between months with directional slide transitions.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    _applyStatusBar();
  }

  void _applyStatusBar() {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }

  Widget _buildGridSwitcher(CalendarState state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final isIncoming =
            child.key == ValueKey('${state.year}-${state.month}');
        final direction = state.slideDirection;
        Offset beginOffset;

        if (direction == SlideDirection.left) {
          beginOffset =
              isIncoming ? const Offset(1, 0) : const Offset(-1, 0);
        } else if (direction == SlideDirection.right) {
          beginOffset =
              isIncoming ? const Offset(-1, 0) : const Offset(1, 0);
        } else {
          return FadeTransition(opacity: animation, child: child);
        }

        final offsetAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation);

        return ClipRect(
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey('${state.year}-${state.month}'),
        children: const [
          CalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context, CalendarState state, NepaliThemeColors colors) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildGridSwitcher(state),
            const SizedBox(height: 8),
            const SelectedDateBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(color: colors.divider, height: 1),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: MonthlyHolidays(
                key: ValueKey('holidays-${state.year}-${state.month}'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(
      BuildContext context, CalendarState state, NepaliThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Calendar header, weekday row, grid
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const CalendarHeader(),
              const WeekdayRow(),
              Expanded(
                child: SelectionArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildGridSwitcher(state),
                        SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colors.divider,
          indent: 8,
          endIndent: 8,
        ),
        // Right: Selected date banner + holiday list
        Expanded(
          flex: 2,
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const SelectedDateBanner(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Divider(color: colors.divider, height: 1),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: MonthlyHolidays(
                      key: ValueKey('holidays-${state.year}-${state.month}'),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 300) {
      HapticFeedback.lightImpact();
      ref.read(calendarProvider.notifier).previousMonth();
    } else if (velocity < -300) {
      HapticFeedback.lightImpact();
      ref.read(calendarProvider.notifier).nextMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    // Update status bar when theme changes.
    ref.listen(themeProvider, (_, _) => _applyStatusBar());

    return SafeArea(
      child: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              return _buildWideLayout(context, state, colors);
            }

            return Column(
              children: [
                const CalendarHeader(),
                const WeekdayRow(),
                Expanded(
                  child: _buildNarrowLayout(context, state, colors),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
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

  void _showAccentColorPicker(BuildContext context, NepaliThemeColors colors) {
    final currentIndex = ref.read(settingsProvider).accentColorIndex;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: AppTheme.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'एक्सेन्ट रङ छान्नुहोस्',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    AppTheme.accentOptions.length,
                    (index) {
                      final option = AppTheme.accentOptions[index];
                      final isSelected = index == currentIndex;
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(settingsProvider.notifier)
                              .setAccentColor(index);
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: option.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: colors.textPrimary, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: option.color
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 24)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    final themeMode = ref.watch(themeProvider);
    final showGridBorder = ref.watch(settingsProvider.select((s) => s.showGridBorder));

    final isOnCurrentMonth =
        state.year == state.today.year && state.month == state.today.month;

    return Scaffold(
      floatingActionButton: isOnCurrentMonth
          ? null
          : SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(calendarProvider.notifier).goToToday();
                },
                backgroundColor: AppTheme.accent,
                tooltip: 'आजको मिति',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'आज',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      appBar: AppBar(
        title: const Text('बबाल पात्रो'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Settings',
            color: colors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  ref.read(themeProvider.notifier).toggle();
                case 'grid_border':
                  ref.read(settingsProvider.notifier).toggleGridBorder();
                case 'accent_color':
                  _showAccentColorPicker(context, colors);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      themeMode == ThemeMode.dark
                          ? 'लाइट मोड'
                          : 'डार्क मोड',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'grid_border',
                child: Row(
                  children: [
                    Icon(
                      showGridBorder
                          ? Icons.grid_off_outlined
                          : Icons.grid_on_outlined,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      showGridBorder
                          ? 'ग्रिड बोर्डर हटाउनुहोस्'
                          : 'ग्रिड बोर्डर देखाउनुहोस्',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'accent_color',
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'एक्सेन्ट रङ',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              return Column(
                children: [
                  Divider(color: colors.divider, height: 1),
                  Expanded(
                    child: _buildWideLayout(context, state, colors),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Divider(color: colors.divider, height: 1),
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

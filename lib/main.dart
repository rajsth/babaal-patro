import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'core/home_widget_updater.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/events_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Push today's date to the Android home screen widget.
  HomeWidgetUpdater.update();
  runApp(const ProviderScope(child: NepaliCalendarApp()));
}

/// Root widget — applies the persisted theme and sets up bottom navigation.
class NepaliCalendarApp extends ConsumerWidget {
  const NepaliCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    // Watch accent color so theme rebuilds when it changes.
    ref.watch(settingsProvider.select((s) => s.accentColorIndex));

    return MaterialApp(
      title: 'बबाल पात्रो',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}

/// Bottom navigation shell with Calendar and Converter tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _showSplash = true;

  static const _screens = [
    CalendarScreen(),
    EventsScreen(),
    ConverterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () => setState(() => _showSplash = false),
      );
    }

    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: colors.surfaceVariant,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppTheme.accent),
            label: 'पात्रो',
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note, color: AppTheme.accent),
            label: 'घटनाहरू',
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz, color: AppTheme.accent),
            label: 'रूपान्तरण',
          ),
        ],
      ),
    );
  }
}

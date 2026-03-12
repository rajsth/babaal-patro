import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/app_localizations.dart';
import 'core/calendar_data_service.dart';
import 'core/home_widget_updater.dart';
import 'providers/language_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/events_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CalendarDataService.initialize();
  // Push today's date to the home screen widget (Android + iOS).
  if (!kIsWeb) {
    HomeWidgetUpdater.update();
  }
  // Initialise local notifications and request runtime permissions (mobile only).
  if (!kIsWeb) {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  }
  runApp(const ProviderScope(child: BabaalPatroApp()));
}

/// Root widget — applies the persisted theme and sets up bottom navigation.
class BabaalPatroApp extends ConsumerWidget {
  const BabaalPatroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    // Watch accent color so theme rebuilds when it changes.
    ref.watch(settingsProvider.select((s) => s.accentColorIndex));
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return MaterialApp(
      title: s.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}

/// Bottom navigation shell with Calendar and Converter tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  bool _showSplash = true;

  static const _screens = [
    CalendarScreen(),
    EventsScreen(),
    ConverterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () => setState(() => _showSplash = false),
      );
    }

    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: colors.surfaceVariant,
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.calendar_month_outlined, Icons.calendar_month, s.navCalendar, 0),
            _navItem(Icons.notifications_none_rounded, Icons.notifications_rounded, s.navReminders, 1),
            _navItem(Icons.swap_horiz_outlined, Icons.swap_horiz, s.navConverter, 2),
            _navItem(Icons.settings_outlined, Icons.settings, s.navSettings, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppTheme.accent : null,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.accent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

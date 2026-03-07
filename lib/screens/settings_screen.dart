import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAccentColorPicker(
      BuildContext context, WidgetRef ref, NepaliThemeColors colors) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final themeMode = ref.watch(themeProvider);
    final showGridBorder =
        ref.watch(settingsProvider.select((s) => s.showGridBorder));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'सेटिङ्स',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Theme toggle
          _SettingsTile(
            icon: themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            title: themeMode == ThemeMode.dark ? 'लाइट मोड' : 'डार्क मोड',
            subtitle: themeMode == ThemeMode.dark
                ? 'लाइट थिममा स्विच गर्नुहोस्'
                : 'डार्क थिममा स्विच गर्नुहोस्',
            colors: colors,
            onTap: () => ref.read(themeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 12),
          // Grid border toggle
          _SettingsTile(
            icon: showGridBorder
                ? Icons.grid_off_outlined
                : Icons.grid_on_outlined,
            title: showGridBorder
                ? 'ग्रिड बोर्डर हटाउनुहोस्'
                : 'ग्रिड बोर्डर देखाउनुहोस्',
            subtitle: 'क्यालेन्डर ग्रिडमा बोर्डर देखाउने/हटाउने',
            colors: colors,
            onTap: () =>
                ref.read(settingsProvider.notifier).toggleGridBorder(),
          ),
          const SizedBox(height: 12),
          // Accent color picker
          _SettingsTile(
            iconWidget: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            title: 'एक्सेन्ट रङ',
            subtitle: 'एपको मुख्य रङ छान्नुहोस्',
            colors: colors,
            onTap: () => _showAccentColorPicker(context, ref, colors),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final NepaliThemeColors colors;
  final VoidCallback onTap;

  const _SettingsTile({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconWidget ??
                    Icon(icon, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

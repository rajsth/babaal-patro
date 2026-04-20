import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../providers/app_update_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAccentColorPicker(
      BuildContext context, WidgetRef ref, NepaliThemeColors colors, S s) {
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
                      s.chooseAccentColor,
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
                          ref.read(analyticsServiceProvider).logSettingChanged(
                            setting: 'accent_color',
                            value: index.toString(),
                          );
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
                              s.accentColorNames[index],
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
    final user = ref.watch(authProvider);
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              s.settings,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Account tile
          if (user == null)
            _SignInWarningTile(
              colors: colors,
              s: s,
              onTap: () async {
                final ok =
                    await ref.read(authProvider.notifier).signInWithGoogle();
                ref.read(analyticsServiceProvider).logSignIn(success: ok);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.signInFailed)),
                  );
                }
              },
            )
          else
            _AccountTile(user: user, colors: colors, ref: ref, s: s),
          const SizedBox(height: 12),
          // Language toggle
          _SettingsTile(
            icon: Icons.language_outlined,
            title: s.language,
            subtitle: isNepali ? s.nepali : s.english,
            colors: colors,
            onTap: () {
              ref.read(languageProvider.notifier).toggle();
              ref.read(analyticsServiceProvider).logSettingChanged(
                setting: 'language',
                value: ref.read(languageProvider) ? 'nepali' : 'english',
              );
            },
          ),
          const SizedBox(height: 12),
          // Theme toggle
          _SettingsTile(
            icon: themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            title: themeMode == ThemeMode.dark ? s.lightMode : s.darkMode,
            subtitle: themeMode == ThemeMode.dark
                ? s.switchToLight
                : s.switchToDark,
            colors: colors,
            onTap: () {
              ref.read(themeProvider.notifier).toggle();
              ref.read(analyticsServiceProvider).logSettingChanged(
                setting: 'theme',
                value: ref.read(themeProvider) == ThemeMode.dark ? 'dark' : 'light',
              );
            },
          ),
          const SizedBox(height: 12),
          // Grid border toggle
          _SettingsTile(
            icon: showGridBorder
                ? Icons.grid_off_outlined
                : Icons.grid_on_outlined,
            title: showGridBorder
                ? s.hideGridBorder
                : s.showGridBorder,
            subtitle: s.gridBorderSubtitle,
            colors: colors,
            onTap: () {
              ref.read(settingsProvider.notifier).toggleGridBorder();
              ref.read(analyticsServiceProvider).logSettingChanged(
                setting: 'grid_border',
                value: ref.read(settingsProvider).showGridBorder ? 'on' : 'off',
              );
            },
          ),
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 12),
            // Check for updates
            _SettingsTile(
              icon: Icons.system_update_outlined,
              title: s.checkForUpdates,
              subtitle: s.checkForUpdatesSubtitle,
              colors: colors,
              onTap: () {
                ref.read(appUpdateProvider.notifier).checkForUpdate(force: true);
                showDialog(
                  context: context,
                  builder: (_) => const UpdateDialog(),
                );
              },
            ),
          ],
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
            title: s.accentColor,
            subtitle: s.accentColorSubtitle,
            colors: colors,
            onTap: () => _showAccentColorPicker(context, ref, colors, s),
          ),
        ],
      ),
    );
  }
}

class _SignInWarningTile extends StatelessWidget {
  final NepaliThemeColors colors;
  final S s;
  final VoidCallback onTap;

  const _SignInWarningTile({required this.colors, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.noBackup,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.dataLossWarning,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.signIn,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final dynamic user;
  final NepaliThemeColors colors;
  final WidgetRef ref;
  final S s;

  const _AccountTile({
    required this.user,
    required this.colors,
    required this.ref,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL as String)
                      : null,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                  child: user.photoURL == null
                      ? Icon(Icons.person, color: AppTheme.accent, size: 22)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.cardColor, width: 1.5),
                    ),
                    child: const Icon(Icons.check,
                        size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName as String? ?? s.user,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_rounded,
                          size: 11, color: Colors.green),
                      const SizedBox(width: 3),
                      Text(
                        s.syncing,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(analyticsServiceProvider).logSignOut();
                ref.read(authProvider.notifier).signOut();
              },
              child: Text(
                s.signOut,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
        ),
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

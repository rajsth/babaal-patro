import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../providers/app_update_provider.dart';
import '../providers/language_provider.dart';

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return PopScope(
      canPop: state.status != UpdateStatus.downloading,
      child: Dialog(
        backgroundColor: colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (state.status) {
            UpdateStatus.checking => _buildChecking(colors, s),
            UpdateStatus.updateAvailable => _buildAvailable(context, ref, state, colors, s),
            UpdateStatus.downloading => _buildDownloading(ref, state, colors, s),
            UpdateStatus.installed => _buildInstalled(context, colors, s),
            UpdateStatus.error => _buildError(context, ref, state, colors, s),
            UpdateStatus.idle => _buildUpToDate(context, colors, s),
          },
        ),
      ),
    );
  }

  Widget _buildChecking(NepaliThemeColors colors, S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.checkingForUpdates,
          style: TextStyle(fontSize: 15, color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAvailable(
    BuildContext context,
    WidgetRef ref,
    AppUpdateState state,
    NepaliThemeColors colors,
    S s,
  ) {
    final info = state.updateInfo!;
    return Column(
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
              child: Icon(Icons.system_update_outlined, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              s.updateAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Version info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _versionRow(s.currentVersionLabel, 'v${info.currentVersion}', colors),
              const SizedBox(height: 6),
              _versionRow(s.newVersionLabel, 'v${info.latestVersion}', colors,
                  highlight: true),
            ],
          ),
        ),
        // Release notes
        if (info.releaseNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              s.whatsNew,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                info.releaseNotes,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Buttons
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  ref.read(appUpdateProvider.notifier).dismiss();
                  Navigator.pop(context);
                },
                child: Text(
                  s.later,
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    ref.read(appUpdateProvider.notifier).downloadAndInstall(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.updateNow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloading(
    WidgetRef ref,
    AppUpdateState state,
    NepaliThemeColors colors,
    S s,
  ) {
    final pct = (state.downloadProgress * 100).toInt();
    return Column(
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
              child: Icon(Icons.downloading_outlined, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${s.downloading} $pct%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(appUpdateProvider.notifier).cancelDownload(),
              icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.downloadProgress,
            minHeight: 8,
            backgroundColor: colors.surfaceVariant,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInstalled(BuildContext context, NepaliThemeColors colors, S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text(
          s.installing,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.close, style: TextStyle(color: colors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    AppUpdateState state,
    NepaliThemeColors colors,
    S s,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Text(
          s.downloadFailed,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  ref.read(appUpdateProvider.notifier).dismiss();
                  Navigator.pop(context);
                },
                child: Text(s.close, style: TextStyle(color: colors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    ref.read(appUpdateProvider.notifier).downloadAndInstall(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.retry,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpToDate(BuildContext context, NepaliThemeColors colors, S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text(
          s.upToDate,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.noUpdateAvailable,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.close, style: TextStyle(color: colors.textSecondary)),
        ),
      ],
    );
  }

  Widget _versionRow(String label, String version, NepaliThemeColors colors,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        Text(
          version,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? AppTheme.accent : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../core/haptic_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
import '../providers/auth_provider.dart';
import '../providers/reminders_provider.dart';
import '../widgets/add_event_dialog.dart';

int _compareReminders(Reminder a, Reminder b) {
  if (a.isEnabled != b.isEnabled) return a.isEnabled ? -1 : 1;
  if (a.bsYear != b.bsYear) return a.bsYear - b.bsYear;
  if (a.bsMonth != b.bsMonth) return a.bsMonth - b.bsMonth;
  if (a.bsDay != b.bsDay) return a.bsDay - b.bsDay;
  if (a.hour != b.hour) return a.hour - b.hour;
  return a.minute - b.minute;
}

/// Reminders screen — lists all scheduled local-notification reminders.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  ReminderCategory? _activeFilter;
  bool _bannerDismissed = false;

  void _showBackupNudge() {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'स्मरण सुरक्षित गर्नुहोस्!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'अहिले तपाईंका स्मरणहरू यस डिभाइसमा मात्र छन्। फोन बदल्दा वा एप मेटाउँदा सबै डाटा गुम्न सक्छ।\n\nGoogle खाताबाट साइन इन गरेर क्लाउडमा ब्याकअप गर्नुहोस्।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).signInWithGoogle();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Google बाट साइन इन गर्नुहोस्',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'पछि गर्छु',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    final sorted = ref.watch(
      remindersProvider.select((list) => [...list]..sort(_compareReminders)),
    );
    final user = ref.watch(authProvider);

    // Show cloud sync confirmation when user signs in
    ref.listen<dynamic>(authProvider, (prev, next) {
      if (prev == null && next != null) {
        setState(() => _bannerDismissed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'स्मरणहरू क्लाउडमा सुरक्षित भयो!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'अहिले र भविष्यका सबै स्मरणहरू स्वतः सिंक हुनेछन्।',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    // Detect first reminder added while not signed in → show nudge
    ref.listen<List<Reminder>>(remindersProvider, (prev, next) {
      if (user == null && (prev?.isEmpty ?? true) && next.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBackupNudge();
        });
      }
    });

    final visible = _activeFilter == null
        ? sorted
        : sorted.where((r) => r.category == _activeFilter).toList();

    final usedCategories = {for (final r in sorted) r.category};
    final showBanner = user == null && sorted.isNotEmpty && !_bannerDismissed;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddReminderDialog(),
        ),
        backgroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'स्मरणहरू',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),

            // ── Sync banner ──────────────────────────────────────────
            if (showBanner)
              _SyncBanner(
                colors: colors,
                onSignIn: () async {
                  final ok = await ref
                      .read(authProvider.notifier)
                      .signInWithGoogle();
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('साइन इन असफल भयो')),
                    );
                  }
                },
                onDismiss: () => setState(() => _bannerDismissed = true),
              ),

            // ── Category filter bar ──────────────────────────────────
            if (sorted.isNotEmpty)
              _FilterBar(
                usedCategories: usedCategories,
                activeFilter: _activeFilter,
                onSelect: (cat) => setState(
                  () => _activeFilter = _activeFilter == cat ? null : cat,
                ),
                colors: colors,
              ),

            // ── Reminder list ────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(filtered: _activeFilter != null)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final reminder = visible[i];
                        return _ReminderTile(
                          key: ValueKey(reminder.id),
                          reminder: reminder,
                          colors: colors,
                          onToggle: () => ref
                              .read(remindersProvider.notifier)
                              .toggleReminder(reminder.id),
                          onDelete: () {
                            Haptic.light();
                            ref
                                .read(remindersProvider.notifier)
                                .removeReminder(reminder.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sync banner ──────────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  final NepaliThemeColors colors;
  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  const _SyncBanner({
    required this.colors,
    required this.onSignIn,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: SelectionArea(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'स्मरणहरू सुरक्षित साथ राख्नको लागी साइन इन गर्नुहोस्',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'साइन इन',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 16, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final Set<ReminderCategory> usedCategories;
  final ReminderCategory? activeFilter;
  final void Function(ReminderCategory) onSelect;
  final NepaliThemeColors colors;

  const _FilterBar({
    required this.usedCategories,
    required this.activeFilter,
    required this.onSelect,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ReminderCategory.values.where(usedCategories.contains).map((
          cat,
        ) {
          final isSelected = activeFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Haptic.selection();
                onSelect(cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.6)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 13,
                      color: isSelected
                          ? AppTheme.accent
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.accent
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({this.filtered = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered
                ? Icons.filter_list_off_rounded
                : Icons.notifications_none_rounded,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            filtered ? 'यस श्रेणीमा कुनै स्मरण छैन' : 'कुनै स्मरण थपिएको छैन',
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'अर्को श्रेणी छान्नुहोस् वा फिल्टर हटाउनुहोस्'
                : '+ थिचेर नयाँ स्मरण थप्नुहोस्',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final NepaliThemeColors colors;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderTile({
    super.key,
    required this.reminder,
    required this.colors,
    required this.onToggle,
    required this.onDelete,
  });

  String get _bsDateStr =>
      '${NepaliDateHelper.toNepaliNumeral(reminder.bsDay)} '
      '${NepaliDateHelper.monthName(reminder.bsMonth)} '
      '${NepaliDateHelper.toNepaliNumeral(reminder.bsYear)}';

  String get _adDateStr {
    try {
      final ad = NepaliDateTime(
        reminder.bsYear,
        reminder.bsMonth,
        reminder.bsDay,
      ).toDateTime();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${m[ad.month - 1]} ${ad.day}, ${ad.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adDateStr = _adDateStr;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.saturday.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_outline, color: AppTheme.saturday, size: 22),
      ),
      child: AnimatedOpacity(
        opacity: reminder.isEnabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.divider),
          ),
          child: SelectionArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      reminder.category.icon,
                      size: 20,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            reminder.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _bsDateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            if (adDateStr.isNotEmpty)
                              Text(
                                '  ·  $adDateStr',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _InfoBadge(
                              icon: Icons.access_time_rounded,
                              label: reminder.timeLabel,
                              colors: colors,
                            ),
                            _InfoBadge(
                              icon: Icons.repeat_rounded,
                              label: reminder.recurrence.label,
                              colors: colors,
                            ),
                            if (reminder.alertOffset != AlertOffset.atTime)
                              _InfoBadge(
                                icon: Icons.alarm_rounded,
                                label: reminder.alertOffset.label,
                                colors: colors,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: reminder.isEnabled,
                    onChanged: (_) {
                      Haptic.selection();
                      onToggle();
                    },
                    activeThumbColor: AppTheme.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final NepaliThemeColors colors;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: colors.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

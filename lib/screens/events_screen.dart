import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
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
  // null = "All" (no filter active)
  ReminderCategory? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    final sorted = ref.watch(
      remindersProvider.select(
        (list) => [...list]..sort(_compareReminders),
      ),
    );

    final visible = _activeFilter == null
        ? sorted
        : sorted.where((r) => r.category == _activeFilter).toList();

    // Which categories actually have at least one reminder (for pill visibility).
    final usedCategories = {for (final r in sorted) r.category};

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

            // ── Category filter bar ──────────────────────────────────
            if (sorted.isNotEmpty)
              _FilterBar(
                usedCategories: usedCategories,
                activeFilter: _activeFilter,
                onSelect: (cat) =>
                    setState(() => _activeFilter = _activeFilter == cat ? null : cat),
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
                            HapticFeedback.lightImpact();
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
        children: ReminderCategory.values
            .where(usedCategories.contains)
            .map((cat) {
          final isSelected = activeFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            filtered
                ? 'यस श्रेणीमा कुनै स्मरण छैन'
                : 'कुनै स्मरण थपिएको छैन',
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
      final ad =
          NepaliDateTime(reminder.bsYear, reminder.bsMonth, reminder.bsDay)
              .toDateTime();
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
                  child: Icon(reminder.category.icon,
                      size: 20, color: AppTheme.accent),
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
                              fontSize: 12, color: colors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _bsDateStr,
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary),
                          ),
                          if (adDateStr.isNotEmpty)
                            Text(
                              '  ·  $adDateStr',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary
                                    .withValues(alpha: 0.6),
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
                    HapticFeedback.selectionClick();
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

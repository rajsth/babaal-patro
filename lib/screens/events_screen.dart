import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../providers/events_provider.dart';

/// Screen that lists all user-added events, reminders, and birthdays.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsMap = ref.watch(eventsProvider);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    // Flatten and pre-compute all derived data once.
    final allEvents = <_EventEntry>[];
    for (final entry in eventsMap.entries) {
      final parts = entry.key.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) continue;
      for (int i = 0; i < entry.value.length; i++) {
        allEvents.add(_EventEntry.create(
          year: year,
          month: month,
          day: day,
          index: i,
          event: entry.value[i],
        ));
      }
    }

    // Separate recurring and one-time events.
    final recurring =
        allEvents.where((e) => e.event.isRecurring).toList()
          ..sort((a, b) => (a.daysRemaining ?? 999).compareTo(b.daysRemaining ?? 999));
    final oneTime =
        allEvents.where((e) => !e.event.isRecurring).toList()
          ..sort((a, b) {
            final yearCmp = a.year.compareTo(b.year);
            if (yearCmp != 0) return yearCmp;
            final monthCmp = a.month.compareTo(b.month);
            return monthCmp != 0 ? monthCmp : a.day.compareTo(b.day);
          });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const _AddEventWithDateDialog(),
          );
        },
        backgroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'घटनाहरू',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: allEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 64,
                    color: colors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'कुनै घटना थपिएको छैन',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'पात्रोमा मिति छानेर घटना थप्नुहोस्',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (recurring.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.repeat_rounded,
                      label: 'वार्षिक घटनाहरू',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    ...recurring.map((e) => _EventTile(
                          entry: e,
                          colors: colors,
                          onDelete: () => _deleteEvent(ref, e),
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (oneTime.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.event_outlined,
                      label: 'एक पटकका घटनाहरू',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    ...oneTime.map((e) => _EventTile(
                          entry: e,
                          colors: colors,
                          onDelete: () => _deleteEvent(ref, e),
                        )),
                  ],
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEvent(WidgetRef ref, _EventEntry entry) {
    HapticFeedback.lightImpact();
    ref.read(eventsProvider.notifier).removeEvent(
          entry.year,
          entry.month,
          entry.day,
          entry.index,
        );
  }
}

class _EventEntry {
  final int year;
  final int month;
  final int day;
  final int index;
  final CalendarEvent event;
  final int? daysRemaining;
  final String adDateString;

  _EventEntry({
    required this.year,
    required this.month,
    required this.day,
    required this.index,
    required this.event,
    required this.daysRemaining,
    required this.adDateString,
  });

  factory _EventEntry.create({
    required int year,
    required int month,
    required int day,
    required int index,
    required CalendarEvent event,
  }) {
    return _EventEntry(
      year: year,
      month: month,
      day: day,
      index: index,
      event: event,
      daysRemaining: event.isRecurring ? _calcDaysRemaining(month, day) : null,
      adDateString: _calcAdDate(year, month, day, event.isRecurring),
    );
  }

  static int? _calcDaysRemaining(int eventMonth, int eventDay) {
    final now = NepaliDateTime.now();
    try {
      var nextAd = NepaliDateTime(now.year, eventMonth, eventDay).toDateTime();
      final todayAd = DateTime(now.toDateTime().year, now.toDateTime().month, now.toDateTime().day);
      final nextDate = DateTime(nextAd.year, nextAd.month, nextAd.day);
      var diff = nextDate.difference(todayAd).inDays;
      if (diff < 0) {
        nextAd = NepaliDateTime(now.year + 1, eventMonth, eventDay).toDateTime();
        final nextDateNextYear = DateTime(nextAd.year, nextAd.month, nextAd.day);
        diff = nextDateNextYear.difference(todayAd).inDays;
      }
      return diff;
    } catch (_) {
      return null;
    }
  }

  static const _adMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _calcAdDate(int year, int month, int day, bool isRecurring) {
    try {
      if (isRecurring) {
        final now = NepaliDateTime.now();
        var adDate = NepaliDateTime(now.year, month, day).toDateTime();
        final today = DateTime(now.toDateTime().year, now.toDateTime().month, now.toDateTime().day);
        if (DateTime(adDate.year, adDate.month, adDate.day).isBefore(today)) {
          adDate = NepaliDateTime(now.year + 1, month, day).toDateTime();
        }
        return '${_adMonths[adDate.month - 1]} ${adDate.day}, ${adDate.year}';
      }
      final adDate = NepaliDateTime(year, month, day).toDateTime();
      return '${_adMonths[adDate.month - 1]} ${adDate.day}, ${adDate.year}';
    } catch (_) {
      return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final NepaliThemeColors colors;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final _EventEntry entry;
  final NepaliThemeColors colors;
  final VoidCallback onDelete;

  const _EventTile({
    required this.entry,
    required this.colors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nepaliDate =
        '${NepaliDateHelper.toNepaliNumeral(entry.day)} '
        '${NepaliDateHelper.monthName(entry.month)}';
    final fullDate = entry.event.isRecurring
        ? nepaliDate
        : '$nepaliDate ${NepaliDateHelper.toNepaliNumeral(entry.year)}';

    return Dismissible(
      key: ValueKey(
          '${entry.year}-${entry.month}-${entry.day}-${entry.index}-${entry.event.title}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.saturday.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete_outline,
          color: AppTheme.saturday,
          size: 20,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: entry.event.isRecurring
                    ? AppTheme.accent.withValues(alpha: 0.12)
                    : AppTheme.eventDot.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fullDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: entry.event.isRecurring
                          ? AppTheme.accent
                          : AppTheme.eventDot,
                    ),
                  ),
                  if (entry.adDateString.isNotEmpty)
                    Text(
                      entry.adDateString,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Event title + days remaining
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.event.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (entry.event.isRecurring && entry.daysRemaining != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.daysRemaining == 0
                          ? 'आज!'
                          : '${NepaliDateHelper.toNepaliNumeral(entry.daysRemaining!)} दिन बाँकी',
                      style: TextStyle(
                        fontSize: 11,
                        color: entry.daysRemaining == 0
                            ? AppTheme.accent
                            : colors.textSecondary,
                        fontWeight:
                            entry.daysRemaining == 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog with BS date picker, event title input, and recurring toggle.
class _AddEventWithDateDialog extends ConsumerStatefulWidget {
  const _AddEventWithDateDialog();

  @override
  ConsumerState<_AddEventWithDateDialog> createState() =>
      _AddEventWithDateDialogState();
}

class _AddEventWithDateDialogState
    extends ConsumerState<_AddEventWithDateDialog> {
  final _controller = TextEditingController();
  bool _isRecurring = false;

  late int _year;
  late int _month;
  late int _day;

  static final List<int> _years = List.generate(91, (i) => 2000 + i);
  static final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final now = NepaliDateTime.now();
    _year = now.year;
    _month = now.month;
    _day = now.day;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _daysInMonth() {
    try {
      return NepaliDateTime(_year, _month).totalDays;
    } catch (_) {
      return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final maxDay = _daysInMonth();
    if (_day > maxDay) _day = maxDay;
    final days = List.generate(maxDay, (i) => i + 1);

    return Dialog(
      backgroundColor: colors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      color: AppTheme.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'नयाँ घटना थप्नुहोस्',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // BS Date picker row
              Text(
                'बि.सं. मिति',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Year
                  Expanded(
                    flex: 3,
                    child: _dropdown(
                      value: _year,
                      items: _years,
                      displayBuilder: (v) =>
                          NepaliDateHelper.toNepaliNumeral(v),
                      onChanged: (v) => setState(() => _year = v!),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Month
                  Expanded(
                    flex: 4,
                    child: _dropdown(
                      value: _month,
                      items: _months,
                      displayBuilder: (v) =>
                          NepaliDateHelper.monthNames[v - 1],
                      onChanged: (v) => setState(() => _month = v!),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Day
                  Expanded(
                    flex: 2,
                    child: _dropdown(
                      value: _day,
                      items: days,
                      displayBuilder: (v) =>
                          NepaliDateHelper.toNepaliNumeral(v),
                      onChanged: (v) => setState(() => _day = v!),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Event title input
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 200,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'घटनाको शीर्षक लेख्नुहोस्...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Recurring toggle
              GestureDetector(
                onTap: () => setState(() => _isRecurring = !_isRecurring),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isRecurring
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: _isRecurring
                        ? Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 20,
                        color: _isRecurring
                            ? AppTheme.accent
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'हरेक वर्ष दोहोर्याउनुहोस्',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'जन्मदिन, वार्षिकोत्सव आदि',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                        activeThumbColor: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colors.divider),
                      ),
                      child: Text(
                        'रद्द',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final title = _controller.text.trim();
                        if (title.isNotEmpty) {
                          ref.read(eventsProvider.notifier).addEvent(
                                _year,
                                _month,
                                _day,
                                title,
                                isRecurring: _isRecurring,
                              );
                        }
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'सुरक्षित गर्नुहोस्',
                        style: TextStyle(
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
          ),
        ),
      ),
      ),
    );
  }

  Widget _dropdown({
    required int value,
    required List<int> items,
    required String Function(int) displayBuilder,
    required ValueChanged<int?> onChanged,
    required NepaliThemeColors colors,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.cardColor,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.textSecondary,
          size: 18,
        ),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(displayBuilder(v)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

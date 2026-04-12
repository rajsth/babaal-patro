import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
import '../providers/language_provider.dart';
import '../providers/reminders_provider.dart';

void showAddReminderSheet(BuildContext context, {NepaliDateTime? initialDate, Reminder? existingReminder}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddReminderSheet(initialDate: initialDate, existingReminder: existingReminder),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Main bottom-sheet widget
// ═══════════════════════════════════════════════════════════════════════════

class _AddReminderSheet extends ConsumerStatefulWidget {
  final NepaliDateTime? initialDate;
  final Reminder? existingReminder;
  const _AddReminderSheet({this.initialDate, this.existingReminder});

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleController = TextEditingController();
  late int _year, _month, _day, _hour, _minute;
  ReminderCategory _category = ReminderCategory.personal;
  ReminderRecurrence _recurrence = ReminderRecurrence.daily;
  AlertOffset _alertOffset = AlertOffset.atTime;
  bool _showTitleError = false;
  bool _showMoreOptions = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      _year = r.bsYear;
      _month = r.bsMonth;
      _day = r.bsDay;
      _hour = r.hour;
      _minute = r.minute;
      _category = r.category;
      _recurrence = r.recurrence;
      _alertOffset = r.alertOffset;
      _showMoreOptions = true; // Expand options to show they're set
    } else {
      final now = widget.initialDate ?? NepaliDateHelper.today();
      _year = now.year;
      _month = now.month;
      _day = now.day;
      final adNow = NepaliDateHelper.nepalNow();
      // Round up to next hour for convenience.
      _hour = adNow.minute > 0 ? (adNow.hour + 1) % 24 : adNow.hour;
      _minute = 0;
    }
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ── Smart defaults ───────────────────────────────────────────────────

  void _onTitleChanged() {
    if (_showTitleError && _titleController.text.trim().isNotEmpty) {
      setState(() => _showTitleError = false);
    }
    _autoDetectCategory();
  }

  void _autoDetectCategory() {
    final title = _titleController.text.trim().toLowerCase();
    if (title.isEmpty) return;

    ReminderCategory? detected;
    ReminderRecurrence? detectedRecurrence;

    if (_has(title, ['birthday', 'bday', 'जन्मदिन'])) {
      detected = ReminderCategory.birthday;
      detectedRecurrence = ReminderRecurrence.yearly;
    } else if (_has(title, ['anniversary', 'वार्षिकोत्सव'])) {
      detected = ReminderCategory.anniversary;
      detectedRecurrence = ReminderRecurrence.yearly;
    } else if (_has(title, ['doctor', 'hospital', 'clinic', 'checkup', 'अस्पताल', 'डाक्टर'])) {
      detected = ReminderCategory.healthcare;
    } else if (_has(title, ['medicine', 'pill', 'tablet', 'औषधि'])) {
      detected = ReminderCategory.medicine;
    } else if (_has(title, ['school', 'class', 'exam', 'college', 'विद्यालय'])) {
      detected = ReminderCategory.school;
    } else if (_has(title, ['pay', 'rent', 'loan', 'bill', 'emi', 'तिर्नु'])) {
      detected = ReminderCategory.financial;
    } else if (_has(title, ['buy', 'shop', 'grocery', 'किनमेल'])) {
      detected = ReminderCategory.shopping;
    } else if (_has(title, ['festival', 'puja', 'dashain', 'tihar', 'चाड'])) {
      detected = ReminderCategory.cultural;
    } else if (_has(title, ['wedding', 'party', 'invite', 'निमन्त्रणा'])) {
      detected = ReminderCategory.invitation;
    }

    if (detected != null && detected != _category) {
      setState(() {
        _category = detected!;
        if (detectedRecurrence != null) _recurrence = detectedRecurrence;
      });
    }
  }

  static bool _has(String t, List<String> kw) => kw.any(t.contains);

  // ── Pickers ──────────────────────────────────────────────────────────

  int _daysInMonth([int? y, int? m]) {
    try {
      return NepaliDateTime(y ?? _year, m ?? _month).totalDays;
    } catch (_) {
      return 30;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _pickDate() async {
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    int tempYear = _year;
    int tempMonth = _month;
    int tempDay = _day;

    const startYear = 2000;
    final years = List.generate(91, (i) => startYear + i);
    final months = List.generate(12, (i) => i + 1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          int maxDay = _daysInMonth(tempYear, tempMonth);
          if (tempDay > maxDay) tempDay = maxDay;
          final days = List.generate(maxDay, (i) => i + 1);

          return SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
                  // ── Handle + title row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Column(children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.bsDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              )),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _year = tempYear;
                                _month = tempMonth;
                                _day = tempDay;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Text(s.save,
                                style: TextStyle(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ]),
                  ),
                  // ── Scroll wheels ──
                  Expanded(
                    child: Row(children: [
                      _wheel(
                        flex: 3,
                        initial: tempYear - startYear,
                        count: years.length,
                        label: (i) => NepaliDateHelper.localizedNumeral(
                            years[i],
                            isNepali: isNepali),
                        onChanged: (i) => setPickerState(() {
                          tempYear = years[i];
                          final m = _daysInMonth(tempYear, tempMonth);
                          if (tempDay > m) tempDay = m;
                        }),
                        colors: colors,
                      ),
                      _wheel(
                        flex: 3,
                        initial: tempMonth - 1,
                        count: 12,
                        label: (i) => s.monthNames[i],
                        onChanged: (i) => setPickerState(() {
                          tempMonth = months[i];
                          final m = _daysInMonth(tempYear, tempMonth);
                          if (tempDay > m) tempDay = m;
                        }),
                        colors: colors,
                      ),
                      _wheel(
                        flex: 2,
                        initial: tempDay - 1,
                        count: days.length,
                        label: (i) => NepaliDateHelper.localizedNumeral(
                            days[i],
                            isNepali: isNepali),
                        onChanged: (i) =>
                            setPickerState(() => tempDay = days[i]),
                        colors: colors,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _wheel({
    required int flex,
    required int initial,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    required NepaliThemeColors colors,
  }) {
    return Expanded(
      flex: flex,
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: initial),
        itemExtent: 40,
        diameterRatio: 1.2,
        squeeze: 1.0,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: AppTheme.accent.withValues(alpha: 0.08),
        ),
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
          (i) => Center(
            child: Text(label(i),
                style: TextStyle(fontSize: 17, color: colors.textPrimary)),
          ),
        ),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }

    final maxDay = _daysInMonth();
    final day = _day > maxDay ? maxDay : _day;

    final isEdit = widget.existingReminder != null;

    final reminder = Reminder(
      id: isEdit ? widget.existingReminder!.id : '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
      title: title,
      description: isEdit ? widget.existingReminder!.description : '',
      bsYear: _year,
      bsMonth: _month,
      bsDay: day,
      hour: _hour,
      minute: _minute,
      category: _category,
      recurrence: _recurrence,
      alertOffset: _alertOffset,
      isEnabled: isEdit ? widget.existingReminder!.isEnabled : true,
    );

    if (isEdit) {
      ref.read(remindersProvider.notifier).updateReminder(reminder);
    } else {
      ref.read(remindersProvider.notifier).addReminder(reminder);
    }
    Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);
    final maxDay = _daysInMonth();
    if (_day > maxDay) _day = maxDay;

    final timeLabel =
        '${_hour % 12 == 0 ? 12 : _hour % 12}:${_minute.toString().padLeft(2, '0')} '
        '${_hour < 12 ? 'AM' : 'PM'}';

    final dateLabel =
        '${NepaliDateHelper.localizedNumeral(_day, isNepali: isNepali)} '
        '${s.monthNames[_month - 1]} '
        '${NepaliDateHelper.localizedNumeral(_year, isNepali: isNepali)}';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ──
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_rounded,
                        color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        widget.existingReminder != null
                            ? "Edit Reminder"
                            : s.addNewReminder,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        )),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        color: colors.textSecondary, size: 22),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Title field ──
                _buildTextField(
                  controller: _titleController,
                  hint: s.titleHint,
                  autofocus: true,
                  hasError: _showTitleError,
                  colors: colors,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: _showTitleError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded,
                                size: 13,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 5),
                            Text(s.titleRequired,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.error)),
                          ]),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),

                // ── Date + Time row ──
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: _tappableField(
                      icon: Icons.calendar_today_rounded,
                      label: dateLabel,
                      onTap: _pickDate,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _tappableField(
                      icon: Icons.access_time_rounded,
                      label: timeLabel,
                      onTap: _pickTime,
                      colors: colors,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── More options toggle ──
                GestureDetector(
                  onTap: () =>
                      setState(() => _showMoreOptions = !_showMoreOptions),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(
                        _showMoreOptions
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(s.moreOptions,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          )),
                      // Show selected category badge when collapsed
                      if (!_showMoreOptions &&
                          _category != ReminderCategory.personal) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_category.icon,
                                    size: 12, color: AppTheme.accent),
                                const SizedBox(width: 4),
                                Text(
                                  _category.localizedLabel(isNepali),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ]),
                        ),
                      ],
                    ]),
                  ),
                ),

                // ── Expandable section ──
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildMoreOptions(colors, isNepali, s),
                  crossFadeState: _showMoreOptions
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  sizeCurve: Curves.easeInOut,
                ),
                const SizedBox(height: 20),

                // ── Save button (full width) ──
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.save,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  // ── More options panel ───────────────────────────────────────────────

  Widget _buildMoreOptions(NepaliThemeColors colors, bool isNepali, S s) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category icon grid
          _sectionLabel(s.category, colors),
          const SizedBox(height: 8),
          _CategoryGrid(
            selected: _category,
            isNepali: isNepali,
            onTap: (v) {
              setState(() {
                _category = v;
                if (v == ReminderCategory.birthday || v == ReminderCategory.anniversary) {
                  _recurrence = ReminderRecurrence.yearly;
                }
              });
            },
            colors: colors,
          ),
          const SizedBox(height: 16),

          // Recurrence horizontal chips
          _sectionLabel(s.recurrence, colors),
          const SizedBox(height: 8),
          _HorizontalChips<ReminderRecurrence>(
            values: ReminderRecurrence.values,
            selected: _recurrence,
            label: (v) => v.localizedLabel(isNepali),
            onTap: (v) => setState(() => _recurrence = v),
            colors: colors,
          ),
          const SizedBox(height: 16),

          // Alert horizontal chips
          _sectionLabel(s.alertWhen, colors),
          const SizedBox(height: 8),
          _HorizontalChips<AlertOffset>(
            values: AlertOffset.values,
            selected: _alertOffset,
            label: (v) => v.localizedLabel(isNepali),
            onTap: (v) => setState(() => _alertOffset = v),
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────

  Widget _sectionLabel(String text, NepaliThemeColors colors) {
    return Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary));
  }

  Widget _tappableField({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required NepaliThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.textSecondary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required NepaliThemeColors colors,
    bool autofocus = false,
    bool hasError = false,
    int maxLines = 1,
  }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
        filled: true,
        fillColor: hasError
            ? errorColor.withValues(alpha: 0.06)
            : colors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: hasError
              ? BorderSide(
                  color: errorColor.withValues(alpha: 0.6), width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: hasError
              ? BorderSide(color: errorColor, width: 1.5)
              : BorderSide(
                  color: AppTheme.accent.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Category icon grid — 2 rows × 5 columns
// ═══════════════════════════════════════════════════════════════════════════

class _CategoryGrid extends StatelessWidget {
  final ReminderCategory selected;
  final bool isNepali;
  final void Function(ReminderCategory) onTap;
  final NepaliThemeColors colors;

  const _CategoryGrid({
    required this.selected,
    required this.isNepali,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final cats = ReminderCategory.values;
    return Column(children: [
      Row(children: cats.sublist(0, 5).map(_cell).toList()),
      const SizedBox(height: 8),
      Row(children: cats.sublist(5, 10).map(_cell).toList()),
    ]);
  }

  Widget _cell(ReminderCategory cat) {
    final isSelected = cat == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.15)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(cat.icon,
                size: 20,
                color: isSelected ? AppTheme.accent : colors.textSecondary),
            const SizedBox(height: 4),
            Text(
              cat.localizedLabel(isNepali),
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.accent : colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Horizontal scrolling chip selector
// ═══════════════════════════════════════════════════════════════════════════

class _HorizontalChips<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onTap;
  final NepaliThemeColors colors;

  const _HorizontalChips({
    required this.values,
    required this.selected,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                child: Text(
                  label(v),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppTheme.accent : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

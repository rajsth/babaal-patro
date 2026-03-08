import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../models/reminder.dart';
import '../providers/language_provider.dart';
import '../providers/reminders_provider.dart';

/// Dialog for adding a new BS-based local-notification reminder.
///
/// Fields: title, description, BS date picker, time picker, category,
/// recurrence, and alert offset.
class AddReminderDialog extends ConsumerStatefulWidget {
  /// Pre-populate the BS date when opened from the calendar grid.
  final NepaliDateTime? initialDate;

  const AddReminderDialog({super.key, this.initialDate});

  @override
  ConsumerState<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends ConsumerState<AddReminderDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late int _year;
  late int _month;
  late int _day;
  late int _hour;
  late int _minute;

  ReminderCategory _category = ReminderCategory.personal;
  ReminderRecurrence _recurrence = ReminderRecurrence.none;
  AlertOffset _alertOffset = AlertOffset.atTime;

  bool _showTitleError = false;

  static final List<int> _years = List.generate(91, (i) => 2000 + i);
  static final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? NepaliDateTime.now();
    _year = now.year;
    _month = now.month;
    _day = now.day;
    final adNow = DateTime.now();
    _hour = adNow.hour;
    _minute = adNow.minute;
    // Clear validation error as soon as the user starts typing.
    _titleController.addListener(() {
      if (_showTitleError && _titleController.text.trim().isNotEmpty) {
        setState(() => _showTitleError = false);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int _daysInMonth() {
    try {
      return NepaliDateTime(_year, _month).totalDays;
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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }

    final reminder = Reminder(
      id: '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
      title: title,
      description: _descController.text.trim(),
      bsYear: _year,
      bsMonth: _month,
      bsDay: _day,
      hour: _hour,
      minute: _minute,
      category: _category,
      recurrence: _recurrence,
      alertOffset: _alertOffset,
    );

    ref.read(remindersProvider.notifier).addReminder(reminder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);
    final maxDay = _daysInMonth();
    if (_day > maxDay) _day = maxDay;
    final days = List.generate(maxDay, (i) => i + 1);

    final timeLabel =
        '${_hour % 12 == 0 ? 12 : _hour % 12}:${_minute.toString().padLeft(2, '0')} '
        '${_hour < 12 ? 'AM' : 'PM'}';

    return Dialog(
      backgroundColor: colors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_rounded,
                        color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    s.addNewReminder,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Title ────────────────────────────────────────────────
              _sectionLabel(s.title, colors),
              const SizedBox(height: 6),
              _textField(
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
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 13,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 5),
                            Text(
                              s.titleRequired,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),

              // ── Description ──────────────────────────────────────────
              _sectionLabel(s.descriptionOptional, colors),
              const SizedBox(height: 6),
              _textField(
                controller: _descController,
                hint: s.descriptionHint,
                maxLines: 2,
                colors: colors,
              ),
              const SizedBox(height: 18),

              // ── BS Date ──────────────────────────────────────────────
              _sectionLabel(s.bsDate, colors),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _dropdown(
                      value: _year,
                      items: _years,
                      display: (v) => NepaliDateHelper.localizedNumeral(v, isNepali: isNepali),
                      onChanged: (v) => setState(() => _year = v!),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _dropdown(
                      value: _month,
                      items: _months,
                      display: (v) => s.monthNames[v - 1],
                      onChanged: (v) => setState(() => _month = v!),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _dropdown(
                      value: days.contains(_day) ? _day : days.first,
                      items: days,
                      display: (v) => NepaliDateHelper.localizedNumeral(v, isNepali: isNepali),
                      onChanged: (v) => setState(() => _day = v!),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Time ─────────────────────────────────────────────────
              _sectionLabel(s.time, colors),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 18, color: colors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Category ─────────────────────────────────────────────
              _sectionLabel(s.category, colors),
              const SizedBox(height: 8),
              _PillSelector<ReminderCategory>(
                values: ReminderCategory.values,
                selected: _category,
                label: (v) => v.localizedLabel(isNepali),
                icon: (v) => v.icon,
                onTap: (v) => setState(() => _category = v),
                colors: colors,
              ),
              const SizedBox(height: 16),

              // ── Recurrence ───────────────────────────────────────────
              _sectionLabel(s.recurrence, colors),
              const SizedBox(height: 8),
              _PillSelector<ReminderRecurrence>(
                values: ReminderRecurrence.values,
                selected: _recurrence,
                label: (v) => v.localizedLabel(isNepali),
                onTap: (v) => setState(() => _recurrence = v),
                colors: colors,
              ),
              const SizedBox(height: 16),

              // ── Alert offset ─────────────────────────────────────────
              _sectionLabel(s.alertWhen, colors),
              const SizedBox(height: 8),
              _PillSelector<AlertOffset>(
                values: AlertOffset.values,
                selected: _alertOffset,
                label: (v) => v.localizedLabel(isNepali),
                onTap: (v) => setState(() => _alertOffset = v),
                colors: colors,
              ),
              const SizedBox(height: 24),

              // ── Actions ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: colors.divider),
                      ),
                      child: Text(
                        s.cancel,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        s.save,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────

  Widget _sectionLabel(String text, NepaliThemeColors colors) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _textField({
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: hasError
              ? BorderSide(color: errorColor.withValues(alpha: 0.6), width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: hasError
              ? BorderSide(color: errorColor, width: 1.5)
              : BorderSide(color: AppTheme.accent.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
    required NepaliThemeColors colors,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<T>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.cardColor,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary, size: 18),
        style: TextStyle(
            color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(display(v))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// Horizontally-wrapping pill chip selector for enum values.
class _PillSelector<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final IconData Function(T)? icon;
  final void Function(T) onTap;
  final NepaliThemeColors colors;

  const _PillSelector({
    required this.values,
    required this.selected,
    required this.label,
    required this.onTap,
    required this.colors,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onTap(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                if (icon != null) ...[
                  Icon(
                    icon!(v),
                    size: 13,
                    color: isSelected ? AppTheme.accent : colors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label(v),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? AppTheme.accent : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

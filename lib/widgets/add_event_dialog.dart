import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/nepali_date_helper.dart';
import '../providers/events_provider.dart';

/// Dialog to add a new event/reminder for a specific BS date.
class AddEventDialog extends ConsumerStatefulWidget {
  final NepaliDateTime date;

  const AddEventDialog({super.key, required this.date});

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _controller = TextEditingController();
  bool _isRecurring = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final dateLabel =
        '${NepaliDateHelper.toNepaliNumeral(widget.date.day)} '
        '${NepaliDateHelper.monthName(widget.date.month)} '
        '${NepaliDateHelper.toNepaliNumeral(widget.date.year)}';

    final dayName = NepaliDateHelper.dayFullNames[widget.date.weekday - 1];

    return Dialog(
      backgroundColor: colors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'घटना थप्नुहोस्',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateLabel, $dayName',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Input field
            TextField(
              controller: _controller,
              autofocus: true,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              widget.date.year,
                              widget.date.month,
                              widget.date.day,
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
    );
  }
}

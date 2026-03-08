import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../core/app_theme.dart';
import '../core/app_localizations.dart';
import '../core/nepali_date_helper.dart';
import '../providers/language_provider.dart';

/// Screen for converting dates between AD (Gregorian) and BS (Bikram Sambat).
class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AD → BS
  int _adYear = DateTime.now().year;
  int _adMonth = DateTime.now().month;
  int _adDay = DateTime.now().day;
  String? _adToBsResult;

  static const List<String> _adMonthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static final List<int> _adYears = List.generate(90, (i) => 1944 + i);
  static final List<int> _months12 = List.generate(12, (i) => i + 1);
  static final List<int> _bsYears = List.generate(91, (i) => 2000 + i);
  static final List<int> _bsDays32 = List.generate(32, (i) => i + 1);

  int _daysInAdMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // BS → AD
  int _bsYear = NepaliDateTime.now().year;
  int _bsMonth = NepaliDateTime.now().month;
  int _bsDay = NepaliDateTime.now().day;
  String? _bsToAdResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _convertAdToBs() {
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    try {
      final adDate = DateTime(_adYear, _adMonth, _adDay);
      final nepaliDate = adDate.toNepaliDateTime();
      setState(() {
        _adToBsResult =
            '${NepaliDateHelper.localizedNumeral(nepaliDate.day, isNepali: isNepali)} '
            '${NepaliDateHelper.monthName(nepaliDate.month, isNepali: isNepali)} '
            '${NepaliDateHelper.localizedNumeral(nepaliDate.year, isNepali: isNepali)}, '
            '${s.dayFullNames[nepaliDate.weekday - 1]}';
      });
    } catch (_) {
      setState(() {
        _adToBsResult = s.invalidDate;
      });
    }
  }

  void _convertBsToAd() {
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    try {
      final adDate =
          NepaliDateTime(_bsYear, _bsMonth, _bsDay).toDateTime();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      setState(() {
        _bsToAdResult =
            '${days[adDate.weekday - 1]}, '
            '${months[adDate.month - 1]} ${adDate.day}, ${adDate.year}';
      });
    } catch (_) {
      setState(() {
        _bsToAdResult = s.invalidDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;
    final isNepali = ref.watch(languageProvider);
    final s = S.of(isNepali);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              s.dateConversion,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'AD → BS'),
                  Tab(text: 'BS → AD'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SelectionArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAdToBsTab(colors, s),
                  _buildBsToAdTab(colors, s, isNepali),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdToBsTab(NepaliThemeColors colors, S s) {
    final maxDay = _daysInAdMonth(_adYear, _adMonth);
    if (_adDay > maxDay) _adDay = maxDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
        children: [
          // Date selection card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.selectADDate,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Year
                _styledDropdown(
                  label: 'Year',
                  value: _adYear,
                  items: _adYears,
                  displayBuilder: (v) => v.toString(),
                  onChanged: (v) => setState(() => _adYear = v!),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                // Month and Day row
                Row(
                  children: [
                    Expanded(
                      child: _styledDropdown(
                        label: 'Month',
                        value: _adMonth,
                        items: _months12,
                        displayBuilder: (v) => _adMonthNames[v - 1],
                        onChanged: (v) => setState(() => _adMonth = v!),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _styledDropdown(
                        label: 'Day',
                        value: _adDay,
                        items: List.generate(maxDay, (i) => i + 1),
                        displayBuilder: (v) => v.toString(),
                        onChanged: (v) => setState(() => _adDay = v!),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Convert button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _convertAdToBs,
              icon: const Icon(Icons.swap_vert_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                s.convert,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Result
          if (_adToBsResult != null)
            _resultCard(
              label: s.bsDateLabel,
              value: _adToBsResult!,
              icon: Icons.event_outlined,
              colors: colors,
            ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildBsToAdTab(NepaliThemeColors colors, S s, bool isNepali) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
        children: [
          // Date selection card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.enterBSDate,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Year
                _styledDropdown(
                  label: s.year,
                  value: _bsYear,
                  items: _bsYears,
                  displayBuilder: (v) =>
                      NepaliDateHelper.localizedNumeral(v, isNepali: isNepali),
                  onChanged: (v) => setState(() => _bsYear = v!),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                // Month and Day row
                Row(
                  children: [
                    Expanded(
                      child: _styledDropdown(
                        label: s.month,
                        value: _bsMonth,
                        items: _months12,
                        displayBuilder: (v) =>
                            s.monthNames[v - 1],
                        onChanged: (v) => setState(() => _bsMonth = v!),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _styledDropdown(
                        label: s.day,
                        value: _bsDay,
                        items: _bsDays32,
                        displayBuilder: (v) =>
                            NepaliDateHelper.localizedNumeral(v, isNepali: isNepali),
                        onChanged: (v) => setState(() => _bsDay = v!),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Convert button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _convertBsToAd,
              icon: const Icon(Icons.swap_vert_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                s.convert,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Result
          if (_bsToAdResult != null)
            _resultCard(
              label: s.adDateLabel,
              value: _bsToAdResult!,
              icon: Icons.today_outlined,
              colors: colors,
            ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _styledDropdown({
    required String label,
    required int value,
    required List<int> items,
    required String Function(int) displayBuilder,
    required ValueChanged<int?> onChanged,
    required NepaliThemeColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
              size: 20,
            ),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
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
        ),
      ],
    );
  }

  Widget _resultCard({
    required String label,
    required String value,
    required IconData icon,
    required NepaliThemeColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

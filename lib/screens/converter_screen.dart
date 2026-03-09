import 'package:flutter/cupertino.dart';
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

  int _daysInAdMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _daysInBsMonth([int? y, int? m]) {
    try {
      return NepaliDateTime(y ?? _bsYear, m ?? _bsMonth).totalDays;
    } catch (_) {
      return 30;
    }
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

  Future<void> _pickAdDate() async {
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    int tempYear = _adYear;
    int tempMonth = _adMonth;
    int tempDay = _adDay;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          int maxDay = _daysInAdMonth(tempYear, tempMonth);
          if (tempDay > maxDay) tempDay = maxDay;
          final days = List.generate(maxDay, (i) => i + 1);

          return SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
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
                          Text("AD Date",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              )),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _adYear = tempYear;
                                _adMonth = tempMonth;
                                _adDay = tempDay;
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
                  Expanded(
                    child: Row(children: [
                      _wheel(
                        flex: 3,
                        initial: _adYears.indexOf(tempYear),
                        count: _adYears.length,
                        label: (i) => _adYears[i].toString(),
                        onChanged: (i) => setPickerState(() {
                          tempYear = _adYears[i];
                          final m = _daysInAdMonth(tempYear, tempMonth);
                          if (tempDay > m) tempDay = m;
                        }),
                        colors: colors,
                      ),
                      _wheel(
                        flex: 3,
                        initial: tempMonth - 1,
                        count: 12,
                        label: (i) => _adMonthNames[i],
                        onChanged: (i) => setPickerState(() {
                          tempMonth = _months12[i];
                          final m = _daysInAdMonth(tempYear, tempMonth);
                          if (tempDay > m) tempDay = m;
                        }),
                        colors: colors,
                      ),
                      _wheel(
                        flex: 2,
                        initial: tempDay - 1,
                        count: days.length,
                        label: (i) => days[i].toString(),
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

  Future<void> _pickBsDate() async {
    final isNepali = ref.read(languageProvider);
    final s = S.of(isNepali);
    final colors = Theme.of(context).extension<NepaliThemeColors>()!;

    int tempYear = _bsYear;
    int tempMonth = _bsMonth;
    int tempDay = _bsDay;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          int maxDay = _daysInBsMonth(tempYear, tempMonth);
          if (tempDay > maxDay) tempDay = maxDay;
          final days = List.generate(maxDay, (i) => i + 1);

          return SafeArea(
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
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
                                _bsYear = tempYear;
                                _bsMonth = tempMonth;
                                _bsDay = tempDay;
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
                  Expanded(
                    child: Row(children: [
                      _wheel(
                        flex: 3,
                        initial: _bsYears.indexOf(tempYear),
                        count: _bsYears.length,
                        label: (i) => NepaliDateHelper.localizedNumeral(
                            _bsYears[i],
                            isNepali: isNepali),
                        onChanged: (i) => setPickerState(() {
                          tempYear = _bsYears[i];
                          final m = _daysInBsMonth(tempYear, tempMonth);
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
                          tempMonth = _months12[i];
                          final m = _daysInBsMonth(tempYear, tempMonth);
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
    
    final dateLabel = '$_adDay ${_adMonthNames[_adMonth - 1]} $_adYear';

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
                _tappableField(
                  icon: Icons.calendar_today_rounded,
                  label: dateLabel,
                  onTap: _pickAdDate,
                  colors: colors,
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
    final maxDay = _daysInBsMonth(_bsYear, _bsMonth);
    if (_bsDay > maxDay) _bsDay = maxDay;
    
    final dateLabel =
        '${NepaliDateHelper.localizedNumeral(_bsDay, isNepali: isNepali)} '
        '${s.monthNames[_bsMonth - 1]} '
        '${NepaliDateHelper.localizedNumeral(_bsYear, isNepali: isNepali)}';

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
                _tappableField(
                  icon: Icons.calendar_today_rounded,
                  label: dateLabel,
                  onTap: _pickBsDate,
                  colors: colors,
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
                    fontSize: 15,
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

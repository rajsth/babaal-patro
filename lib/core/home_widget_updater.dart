import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'app_theme.dart';
import 'nepali_date_helper.dart';

/// Updates the Android home screen widget with today's Nepali date.
/// Call this on app launch and whenever the calendar screen is opened.
class HomeWidgetUpdater {
  HomeWidgetUpdater._();

  static const _androidWidgetName = 'NepaliDateWidget';

  static const _adMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Future<void> update() async {
    final now = NepaliDateTime.now();
    final adNow = DateTime.now();

    await HomeWidget.saveWidgetData<String>(
      'nepali_day',
      NepaliDateHelper.toNepaliNumeral(now.day),
    );
    await HomeWidget.saveWidgetData<String>(
      'nepali_month_year',
      NepaliDateHelper.formattedMonthYear(now.year, now.month),
    );
    await HomeWidget.saveWidgetData<String>(
      'nepali_day_name',
      NepaliDateHelper.dayFullNames[now.weekday - 1],
    );
    await HomeWidget.saveWidgetData<String>(
      'ad_date',
      '${_adMonths[adNow.month - 1]} ${adNow.day}, ${adNow.year}',
    );
    await HomeWidget.saveWidgetData<String>(
      'accent_color',
      _colorToHex(AppTheme.accentLight),
    );

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/home_widget_updater.dart';

class SettingsState {
  final bool showGridBorder;
  final int accentColorIndex;

  const SettingsState({this.showGridBorder = false, this.accentColorIndex = 0});

  SettingsState copyWith({bool? showGridBorder, int? accentColorIndex}) {
    return SettingsState(
      showGridBorder: showGridBorder ?? this.showGridBorder,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _gridBorderKey = 'show_grid_border';
  static const _accentColorKey = 'accent_color_index';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final accentIndex = prefs.getInt(_accentColorKey) ?? 0;
    AppTheme.setAccent(accentIndex);
    state = SettingsState(
      showGridBorder: prefs.getBool(_gridBorderKey) ?? false,
      accentColorIndex: accentIndex,
    );
  }

  Future<void> toggleGridBorder() async {
    state = state.copyWith(showGridBorder: !state.showGridBorder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridBorderKey, state.showGridBorder);
  }

  Future<void> setAccentColor(int index) async {
    AppTheme.setAccent(index);
    state = state.copyWith(accentColorIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, index);
    HomeWidgetUpdater.update();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app language preference (Nepali or English).
/// Nepali is the default language.
class LanguageNotifier extends StateNotifier<bool> {
  LanguageNotifier() : super(true) {
    _load();
  }

  static const _key = 'is_nepali';

  /// `true` = Nepali (default), `false` = English.
  bool get isNepali => state;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> setNepali(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// `true` = Nepali, `false` = English.
final languageProvider =
    StateNotifierProvider<LanguageNotifier, bool>((ref) {
  return LanguageNotifier();
});

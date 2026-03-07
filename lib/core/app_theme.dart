import 'package:flutter/material.dart';

/// A named accent color option.
class AccentColorOption {
  final String label;
  final Color color;
  final Color light;
  final Color holidayColor; // contrasting color for holidays/Saturdays

  const AccentColorOption(this.label, this.color, this.light, this.holidayColor);
}

/// Centralised theme for the Nepali Calendar app.
/// Uses bundled NotoSansDevanagari font (no network dependency).
class AppTheme {
  AppTheme._();

  // ─── Shared Font ─────────────────────────────────────────────────

  static const String fontFamily = 'NotoSansDevanagari';

  // ─── Accent Color Presets ────────────────────────────────────────

  static const Color _defaultHoliday = Color(0xFFFF5252);
  static const Color _coolHoliday = Color(0xFF448AFF); // blue for warm accents

  static const List<AccentColorOption> accentOptions = [
    // Cool accents — use default red for holidays
    AccentColorOption('बैजनी', Color(0xFF7C4DFF), Color(0xFFB388FF), _defaultHoliday),
    AccentColorOption('निलो', Color(0xFF2979FF), Color(0xFF82B1FF), _defaultHoliday),
    AccentColorOption('हरियो', Color(0xFF00C853), Color(0xFF69F0AE), _defaultHoliday),
    AccentColorOption('सियान', Color(0xFF00BCD4), Color(0xFF80DEEA), _defaultHoliday),
    // Warm accents — use blue for holidays to avoid clash
    AccentColorOption('सुन्तला', Color(0xFFFF6D00), Color(0xFFFFAB40), _coolHoliday),
    AccentColorOption('रातो', Color(0xFFFF1744), Color(0xFFFF8A80), _coolHoliday),
    AccentColorOption('गुलाबी', Color(0xFFE91E63), Color(0xFFF48FB1), _coolHoliday),
    AccentColorOption('एम्बर', Color(0xFFFFAB00), Color(0xFFFFD54F), _coolHoliday),
  ];

  static Color accent = accentOptions[0].color;
  static Color accentLight = accentOptions[0].light;
  static Color saturday = accentOptions[0].holidayColor;
  static Color todayHighlight = accentOptions[0].holidayColor;

  static void setAccent(int index) {
    final option = accentOptions[index.clamp(0, accentOptions.length - 1)];
    accent = option.color;
    accentLight = option.light;
    saturday = option.holidayColor;
    todayHighlight = option.holidayColor;
  }

  // ─── Dark Color Palette ──────────────────────────────────────────

  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color eventDot = Color(0xFF448AFF);

  // ─── Light Color Palette ─────────────────────────────────────────

  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightSurfaceVariant = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ─── Theme-aware getters (used by widgets via ThemeExtension) ────

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: darkSurface,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: darkSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardColor: darkCard,
      dividerColor: darkDivider,
      iconTheme: const IconThemeData(color: darkTextPrimary),
      useMaterial3: true,
      extensions: const [
        NepaliThemeColors(
          surface: darkSurface,
          surfaceVariant: darkSurfaceVariant,
          cardColor: darkCard,
          textPrimary: darkTextPrimary,
          textSecondary: darkTextSecondary,
          divider: darkDivider,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: lightSurface,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: lightSurfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurfaceVariant,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardColor: lightCard,
      dividerColor: lightDivider,
      iconTheme: const IconThemeData(color: lightTextPrimary),
      useMaterial3: true,
      extensions: const [
        NepaliThemeColors(
          surface: lightSurface,
          surfaceVariant: lightSurfaceVariant,
          cardColor: lightCard,
          textPrimary: lightTextPrimary,
          textSecondary: lightTextSecondary,
          divider: lightDivider,
        ),
      ],
    );
  }
}

/// Theme extension to expose semantic colors that change per theme.
/// Widgets use `Theme.of(context).extension<NepaliThemeColors>()!`.
class NepaliThemeColors extends ThemeExtension<NepaliThemeColors> {
  final Color surface;
  final Color surfaceVariant;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const NepaliThemeColors({
    required this.surface,
    required this.surfaceVariant,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  @override
  NepaliThemeColors copyWith({
    Color? surface,
    Color? surfaceVariant,
    Color? cardColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
  }) {
    return NepaliThemeColors(
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      cardColor: cardColor ?? this.cardColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
    );
  }

  @override
  NepaliThemeColors lerp(NepaliThemeColors? other, double t) {
    if (other is! NepaliThemeColors) return this;
    return NepaliThemeColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

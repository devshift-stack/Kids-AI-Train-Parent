import 'package:flutter/material.dart';
import 'package:kids_ai_shared/kids_ai_shared.dart';

/// Parent Dashboard Theme
/// Nutzt Shared-Farben, aber DARK Mode für Eltern
class ParentTheme {
  ParentTheme._();

  // Dark Background Colors
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF252542);
  static const Color surfaceVariant = Color(0xFF2D2D4A);

  // Re-export Primary Colors from Shared
  static const Color primary = KidsColors.primary;
  static const Color primaryLight = KidsColors.primaryLight;
  static const Color secondary = KidsColors.secondary;
  static const Color accent = KidsColors.accent;

  // Status Colors from Shared
  static const Color success = KidsColors.success;
  static const Color error = KidsColors.error;
  static const Color warning = KidsColors.warning;

  // Text Colors (inverted for dark theme)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6E6E80);

  // Gradients
  static const LinearGradient primaryGradient = KidsGradients.primary;
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF252542)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Spacing from Shared
  static const double spacingSm = KidsSpacing.sm;
  static const double spacingMd = KidsSpacing.md;
  static const double spacingLg = KidsSpacing.lg;
  static const double spacingXl = KidsSpacing.xl;

  // Border Radius from Shared
  static const double radiusSm = KidsSpacing.radiusSm;
  static const double radiusMd = KidsSpacing.radiusMd;
  static const double radiusLg = KidsSpacing.radiusLg;

  /// Dark Theme Data
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: KidsTypography.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: KidsTypography.headlineMedium.copyWith(
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: KidsTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          padding: EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: KidsTypography.bodyMedium.copyWith(
          color: textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        labelStyle: KidsTypography.labelMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KidsSpacing.radiusRound),
        ),
      ),
    );
  }
}

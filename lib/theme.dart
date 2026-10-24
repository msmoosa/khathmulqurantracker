import 'package:flutter/material.dart';

/// Islamic-inspired color palette.
class AppColors {
  // Primary: deep emerald green — the color of Islam
  static const emerald = Color(0xFF09523A);
  static const emeraldLight = Color(0xFF0D6B4B);
  static const emeraldDark = Color(0xFF043322);
  // Brighter green for text/icons on dark surfaces
  static const emeraldBright = Color(0xFF14956A);

  // Accent: warm gold — inspired by mosque domes and calligraphy
  static const gold = Color(0xFFD4A845);
  static const goldLight = Color(0xFFF0D68A);
  static const goldDark = Color(0xFFB8912E);

  // Neutrals
  static const cream = Color(0xFFFAF6F0);
  static const sand = Color(0xFFF0EAE0);
  static const charcoal = Color(0xFF1E1E1E);

  // Dark mode surfaces
  static const darkSurface = Color(0xFF0A100D);
  static const darkCard = Color(0xFF121A16);
}

ThemeData lightTheme() {
  final colorScheme = ColorScheme.light(
    primary: AppColors.emerald,
    onPrimary: Colors.white,
    primaryContainer: AppColors.emerald.withAlpha(30),
    onPrimaryContainer: AppColors.emeraldDark,
    secondary: AppColors.gold,
    onSecondary: AppColors.charcoal,
    secondaryContainer: AppColors.goldLight.withAlpha(80),
    onSecondaryContainer: AppColors.goldDark,
    tertiary: AppColors.goldDark,
    surface: AppColors.cream,
    onSurface: AppColors.charcoal,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.cream,
    surfaceContainer: AppColors.sand,
    surfaceContainerHigh: AppColors.sand,
    onSurfaceVariant: const Color(0xFF5F6B64),
    outline: const Color(0xFFCBC5BB),
    outlineVariant: const Color(0xFFE4DED4),
    error: const Color(0xFFBA1A1A),
    errorContainer: const Color(0xFFFFDAD6),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.sand, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.emerald,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: AppColors.emerald.withAlpha(100)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.emerald.withAlpha(30),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.emerald, size: 26);
        }
        return IconThemeData(
          color: AppColors.charcoal.withAlpha(140),
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.emerald,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal.withAlpha(140),
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.emeraldDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData darkTheme() {
  final colorScheme = ColorScheme.dark(
    primary: AppColors.emeraldBright,
    onPrimary: Colors.white,
    primaryContainer: AppColors.emerald.withAlpha(60),
    onPrimaryContainer: const Color(0xFF9FDFBF),
    secondary: AppColors.gold,
    onSecondary: AppColors.charcoal,
    secondaryContainer: AppColors.goldDark.withAlpha(60),
    onSecondaryContainer: AppColors.goldLight,
    tertiary: AppColors.goldLight,
    surface: AppColors.darkSurface,
    onSurface: const Color(0xFFE2E3DE),
    surfaceContainerLowest: const Color(0xFF060A08),
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkCard,
    surfaceContainerHigh: const Color(0xFF18221D),
    onSurfaceVariant: const Color(0xFF9EA99F),
    outline: const Color(0xFF2E3B33),
    outlineVariant: const Color(0xFF1F2924),
    error: const Color(0xFFFFB4AB),
    errorContainer: const Color(0xFF93000A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFFE2E3DE),
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF1F2924), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.emeraldBright,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: AppColors.emeraldBright.withAlpha(100)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.emeraldBright.withAlpha(40),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.emeraldBright, size: 26);
        }
        return const IconThemeData(color: Color(0xFF7A857C), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.emeraldBright,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF7A857C),
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.emeraldDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

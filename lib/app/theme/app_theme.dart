import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Centralised Material 3 theme for the app.
/// All ThemeData is built here — no theme properties scattered in widgets.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get amoled => _build(Brightness.dark, isAmoled: true);

  static ThemeData _build(Brightness brightness, {bool isAmoled = false}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? (isAmoled ? _amoledColorScheme : _darkColorScheme)
        : _lightColorScheme;

    final bgColor = isDark
        ? (isAmoled ? AppColors.backgroundAmoled : AppColors.backgroundDark)
        : AppColors.backgroundLight;

    final surfaceColor = isDark
        ? (isAmoled ? AppColors.surfaceAmoled : AppColors.surfaceDark)
        : AppColors.surfaceLight;

    final cardColor = isDark
        ? (isAmoled ? AppColors.cardAmoled : AppColors.cardDark)
        : AppColors.cardLight;

    final dividerColor = isDark
        ? (isAmoled ? AppColors.dividerAmoled : AppColors.dividerDark)
        : AppColors.dividerLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        displayColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      scaffoldBackgroundColor: bgColor,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(AppTypography.labelSmall),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: dividerColor,
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
      ),

      // ── Elevated Button ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(0, 48),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        thickness: 0.5,
        space: 0,
      ),

      // ── List Tile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        minVerticalPadding: AppSpacing.md,
        titleTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: AppTypography.labelSmall,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ── Snack Bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceVariantDark : AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.backgroundLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFFCCF4FC),
    onPrimaryContainer: Color(0xFF00445A),
    secondary: Color(0xFF00B8D9),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFCCF4FC),
    onSecondaryContainer: Color(0xFF00445A),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.dividerLight,
    outlineVariant: AppColors.dividerLight,
    shadow: Colors.black12,
    scrim: Colors.black26,
    inverseSurface: AppColors.textPrimaryLight,
    onInverseSurface: AppColors.backgroundLight,
    inversePrimary: AppColors.primaryDark,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFF00445A),
    onPrimaryContainer: Color(0xFFCCF4FC),
    secondary: Color(0xFF00B8D9),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF00445A),
    onSecondaryContainer: Color(0xFFCCF4FC),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.dividerDark,
    outlineVariant: AppColors.dividerDark,
    shadow: Colors.black45,
    scrim: Colors.black54,
    inverseSurface: AppColors.textPrimaryDark,
    onInverseSurface: AppColors.backgroundDark,
    inversePrimary: AppColors.primary,
  );

  static const ColorScheme _amoledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFF003848),
    onPrimaryContainer: Color(0xFF80E2F4),
    secondary: Color(0xFF00B8D9),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF003848),
    onSecondaryContainer: Color(0xFF80E2F4),
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFF680003),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.surfaceAmoled,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.surfaceVariantAmoled,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.dividerAmoled,
    outlineVariant: AppColors.dividerAmoled,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textPrimaryDark,
    onInverseSurface: AppColors.backgroundAmoled,
    inversePrimary: AppColors.primary,
  );
}

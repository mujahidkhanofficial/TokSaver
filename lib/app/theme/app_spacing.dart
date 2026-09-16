/// Spacing scale — 4pt base grid.
/// Use these tokens everywhere instead of raw doubles.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  /// Standard horizontal page padding.
  static const double pagePadding = base;

  /// Card internal padding.
  static const double cardPadding = base;

  /// Section gap between major groups.
  static const double sectionGap = xl;

  /// Gap between list items.
  static const double itemGap = sm;
}

/// Border radius tokens.
abstract final class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
  static const double pill = 999.0;

  /// Standard card radius.
  static const double card = lg;

  /// Button radius.
  static const double button = md;

  /// Input field radius.
  static const double input = md;

  /// Thumbnail / image radius.
  static const double thumbnail = md;

  /// Chip / badge radius.
  static const double chip = full;
}

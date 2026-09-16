import 'package:flutter/material.dart';

/// Semantic color tokens for the app.
/// No widget should reference raw Color values — always use these tokens.
abstract final class AppColors {
  AppColors._();

  // ── Brand / Primary ───────────────────────────────────────────────────────
  /// Primary action color — vivid teal-blue
  static const Color primary = Color(0xFF00B8D9);
  static const Color primaryLight = Color(0xFF33C6E0);
  static const Color primaryDark = Color(0xFF0099B8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Surfaces — Light ──────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEEEEF0);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE0E0E5);

  // ── Surfaces — Dark ───────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0E0E12);
  static const Color surfaceDark = Color(0xFF1C1C22);
  static const Color surfaceVariantDark = Color(0xFF28282F);
  static const Color cardDark = Color(0xFF1C1C22);
  static const Color dividerDark = Color(0xFF2C2C35);

  // ── Surfaces — AMOLED Pure Black ──────────────────────────────────────────
  static const Color backgroundAmoled = Color(0xFF000000);
  static const Color surfaceAmoled = Color(0xFF0A0A0E);
  static const Color surfaceVariantAmoled = Color(0xFF14141A);
  static const Color cardAmoled = Color(0xFF0A0A0E);
  static const Color dividerAmoled = Color(0xFF1C1C24);

  // ── Accents & Glows ───────────────────────────────────────────────────────
  static const Color glowCyan = Color(0x4D00B8D9);
  static const Color mintAccent = Color(0xFF30D158);
  static const Color neonPink = Color(0xFFFE2C55);

  // ── Text — Light ──────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0D0D12);
  static const Color textSecondaryLight = Color(0xFF6E6E80);
  static const Color textTertiaryLight = Color(0xFFAAAAAF);

  // ── Text — Dark ───────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF0F0F5);
  static const Color textSecondaryDark = Color(0xFF9090A8);
  static const Color textTertiaryDark = Color(0xFF606075);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);
  static const Color successContainer = Color(0xFF1A3D26);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color warningContainer = Color(0xFF3D2A00);
  static const Color error = Color(0xFFFF453A);
  static const Color errorContainer = Color(0xFF3D1414);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Download states ───────────────────────────────────────────────────────
  static const Color downloading = Color(0xFF00B8D9);
  static const Color paused = Color(0xFFFF9F0A);
  static const Color completed = Color(0xFF30D158);
  static const Color failed = Color(0xFFFF453A);
  static const Color queued = Color(0xFF9090A8);
  static const Color cancelled = Color(0xFF6E6E80);
}

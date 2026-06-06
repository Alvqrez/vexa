import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color resolver. Use [BuildContext.colors] to obtain one.
///
/// Selects the correct light / dark variant for every theme-sensitive token.
/// Brand / semantic colors (emerald, negative, category swatches…) are the
/// same in both modes and are available directly from [AppColors].
class VexaColors {
  const VexaColors._(this._dark);
  final bool _dark;

  static VexaColors of(BuildContext context) =>
      VexaColors._(Theme.of(context).brightness == Brightness.dark);

  // ── Backgrounds ─────────────────────────────────────────────────────────
  Color get background =>
      _dark ? AppColors.background : AppColors.lightBackground;
  Color get surface => _dark ? AppColors.surface : AppColors.lightSurface;
  Color get card => _dark ? AppColors.card : AppColors.lightCard;
  Color get cardElevated =>
      _dark ? AppColors.cardElevated : AppColors.lightCardElevated;

  // ── Glass / overlays ────────────────────────────────────────────────────
  Color get glass => _dark ? AppColors.glassLight : AppColors.lightGlass;
  Color get glassMedium =>
      _dark ? AppColors.glassMedium : AppColors.lightGlass;
  Color get glassBorder =>
      _dark ? AppColors.glassBorder : AppColors.lightGlassBorder;
  Color get glassBorderStrong =>
      _dark ? AppColors.glassBorderStrong : AppColors.lightGlassBorder;

  // ── Typography ──────────────────────────────────────────────────────────
  Color get textPrimary =>
      _dark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      _dark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textTertiary =>
      _dark ? AppColors.textTertiary : AppColors.lightTextTertiary;

  // ── Gradient stops ──────────────────────────────────────────────────────
  Color get gradientTop =>
      _dark ? AppColors.gradientTop : AppColors.lightBackground;
  Color get gradientBottom =>
      _dark ? AppColors.gradientBottom : AppColors.lightBackground;
}

extension VexaColorsX on BuildContext {
  VexaColors get colors => VexaColors.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

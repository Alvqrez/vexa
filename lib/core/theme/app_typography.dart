import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // No color set — styles inherit from the active theme's textTheme so they
  // work correctly in both light and dark mode. Apply .copyWith(color: …) at
  // the call-site only when a specific color is needed.
  static TextStyle get _base => GoogleFonts.plusJakartaSans(
        letterSpacing: -0.3,
      );

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayXL => _base.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        height: 0.95,
      );

  static TextStyle get displayL => _base.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.0,
      );

  static TextStyle get displayM => _base.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.08,
      );

  // ── Headings ──────────────────────────────────────────────────────────────
  static TextStyle get headingL => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
      );

  static TextStyle get headingM => _base.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headingS => _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyL => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.55,
      );

  static TextStyle get bodyM => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.5,
      );

  static TextStyle get bodyS => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
      );

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle get labelL => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.3,
      );

  static TextStyle get labelM => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.3,
      );

  static TextStyle get labelS => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.3,
      );

  // ── Eyebrow tags ──────────────────────────────────────────────────────────
  static TextStyle get eyebrow => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        height: 1.2,
      );

  // ── Mono / Numbers ────────────────────────────────────────────────────────
  static TextStyle get monoL => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      );

  static TextStyle get monoS => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      );
}

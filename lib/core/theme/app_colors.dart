import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF09090F);
  static const Color surface = Color(0xFF0F0F1B);
  static const Color card = Color(0xFF141422);
  static const Color cardElevated = Color(0xFF1A1A2E);

  // ── Glass ─────────────────────────────────────────────────────────────────
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassMedium = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBorderStrong = Color(0x26FFFFFF);

  // ── Brand Accents ─────────────────────────────────────────────────────────
  static const Color emerald = Color(0xFF00D68F);
  static const Color emeraldDim = Color(0xFF00A86B);
  static const Color emeraldGlow = Color(0x3300D68F);
  static const Color emeraldSurface = Color(0x1A00D68F);

  static const Color petroleum = Color(0xFF1A7A9A);
  static const Color petroleumLight = Color(0xFF2A9ABF);
  static const Color petroleumSurface = Color(0x1A1A7A9A);

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0EE);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color textTertiary = Color(0xFF555578);
  static const Color textInverse = Color(0xFF09090F);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color positive = Color(0xFF00D68F);
  static const Color positiveSurface = Color(0x1A00D68F);
  static const Color negative = Color(0xFFFF5F82);
  static const Color negativeSurface = Color(0x1AFF5F82);
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningSurface = Color(0x1AFFB74D);

  // ── Gradient Stops ────────────────────────────────────────────────────────
  static const Color gradientTop = Color(0xFF17173A);
  static const Color gradientBottom = Color(0xFF09090F);

  // ── Light Mode Backgrounds ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0EFE9);
  static const Color lightCardElevated = Color(0xFFE8E7DF);

  // ── Light Mode Glass ──────────────────────────────────────────────────────
  static const Color lightGlass = Color(0x0A000000);
  static const Color lightGlassBorder = Color(0x18000000);

  // ── Light Mode Typography ─────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF0D0D14);
  static const Color lightTextSecondary = Color(0xFF5A5A7A);
  static const Color lightTextTertiary = Color(0xFFA0A0B8);

  // ── Category Colors ───────────────────────────────────────────────────────
  static const Color catFood = Color(0xFFFF8C69);
  static const Color catFoodSurface = Color(0x26FF8C69);
  static const Color catTransport = Color(0xFF64B5F6);
  static const Color catTransportSurface = Color(0x2664B5F6);
  static const Color catShopping = Color(0xFFCE93D8);
  static const Color catShoppingSurface = Color(0x26CE93D8);
  static const Color catEntertainment = Color(0xFFFFD54F);
  static const Color catEntertainmentSurface = Color(0x26FFD54F);
  static const Color catHealth = Color(0xFF80CBC4);
  static const Color catHealthSurface = Color(0x2680CBC4);
  static const Color catOther = Color(0xFFB0BEC5);
  static const Color catOtherSurface = Color(0x26B0BEC5);
}

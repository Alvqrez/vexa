import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Standard glass card — backdrop blur, only use on fixed/overlay elements.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 20,
    this.glassOpacity = 0.05,
    this.borderOpacity = 0.1,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final double blur;
  final double glassOpacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: glassOpacity + 0.03),
                Colors.white.withValues(alpha: glassOpacity),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Double-Bezel card — outer tray shell + inner machined core.
/// Mimics a glass plate resting in an aluminium housing.
class BezelCard extends StatelessWidget {
  const BezelCard({
    super.key,
    required this.child,
    this.padding,
    this.outerRadius = 32,
    this.gradient,
    this.glowColor,
    this.innerHighlight = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double outerRadius;
  final Gradient? gradient;
  final Color? glowColor;
  final bool innerHighlight;

  @override
  Widget build(BuildContext context) {
    const trayPadding = 3.0;
    final innerRadius = outerRadius - trayPadding;

    return Container(
      padding: const EdgeInsets.all(trayPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(innerRadius),
          gradient: gradient ??
              const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0xFF1C1C32),
                  Color(0xFF141428),
                  Color(0xFF0F0F1E),
                ],
              ),
          boxShadow: [
            // Ambient glow layer
            if (glowColor != null)
              BoxShadow(
                color: glowColor!.withValues(alpha: 0.08),
                blurRadius: 60,
                spreadRadius: -5,
                offset: const Offset(0, 20),
              ),
            // Mid ambient
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            // Contact shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          // Inner top-edge highlight — the "glass plate" illusion
          border: innerHighlight
              ? Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.5,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.02),
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.01),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Flat surface card — simpler, for list containers and stat tiles.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius ?? AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

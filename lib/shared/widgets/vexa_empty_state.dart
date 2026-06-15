import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/vexa_colors_ext.dart';

import '../../core/theme/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_curves.dart';

/// Premium empty-state widget used throughout the app.
class VexaEmptyState extends StatefulWidget {
  const VexaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  State<VexaEmptyState> createState() => _VexaEmptyStateState();
}

class _VexaEmptyStateState extends State<VexaEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: AppCurves.gentle);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppCurves.spring));
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = widget.iconColor ?? c.textTertiary;

    return SizedBox(
      width: double.infinity,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.huge,
              vertical: AppSpacing.xxxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 0.14),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(widget.icon, size: 32, color: color),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headingS.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.body,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyM.copyWith(
                    color: c.textTertiary,
                    height: 1.55,
                  ),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ActionButton(
                    label: widget.actionLabel!,
                    onTap: widget.onAction!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.emeraldSurface,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTypography.labelL.copyWith(
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

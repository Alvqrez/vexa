import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vexa_colors_ext.dart';
import '../../core/constants/app_spacing.dart';

/// Confirmation card that pops out from the FAB corner (bottom-right),
/// expands to the left, then collapses back on dismiss.
/// Touch events outside the card pass through to underlying widgets.
class SuccessCreationOverlay {
  static OverlayEntry? _currentEntry;

  /// Preferred overload — call with [Overlay.of(context)] captured before any
  /// async gap to satisfy the `use_build_context_synchronously` lint.
  static void showOnState(
    OverlayState overlay, {
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;
    _insertEntry(overlay,
        title: title, subtitle: subtitle, icon: icon, duration: duration);
  }

  /// Convenience overload for call-sites that are not async.
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 3),
  }) {
    showOnState(
      Overlay.of(context),
      title: title,
      subtitle: subtitle,
      icon: icon,
      duration: duration,
    );
  }

  static void _insertEntry(
    OverlayState overlay, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Duration duration,
  }) {
    final key = GlobalKey<_SuccessCardState>();
    late OverlayEntry entry;

    void dismiss() {
      if (_currentEntry == entry) {
        key.currentState?.startDismiss();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Full-screen transparent hit-test blocker removed intentionally —
            // IgnorePointer lets all touches pass through to the content below.
            Positioned.fill(
              child: IgnorePointer(child: const SizedBox.expand()),
            ),
            // Card anchored just above the nav bar / FAB zone.
            Positioned(
              bottom: AppSpacing.bottomNavHeight +
                  AppSpacing.bottomNavBottomPadding +
                  AppSpacing.sm,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              child: _SuccessCard(
                key: key,
                title: title,
                subtitle: subtitle,
                icon: icon,
                onDismiss: () {
                  entry.remove();
                  _currentEntry = null;
                },
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(entry);
    _currentEntry = entry;

    Future.delayed(duration, dismiss);
  }
}

class _SuccessCard extends StatefulWidget {
  const _SuccessCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  State<_SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<_SuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late CurvedAnimation _scale;
  late CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Scale expands from the right edge (FAB side) and collapses back.
    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _scale.dispose();
    _fade.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> startDismiss() async {
    if (!mounted) return;
    await _ctrl.animateBack(0, duration: const Duration(milliseconds: 300));
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ScaleTransition(
      alignment: Alignment.centerRight,
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.positiveSurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.positive,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.labelM.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.labelS.copyWith(
                            color: c.textTertiary,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: startDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    color: c.textTertiary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

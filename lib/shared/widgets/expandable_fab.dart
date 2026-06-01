import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class FabAction {
  const FabAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.actions,
    this.onOpenChanged,
  });
  final List<FabAction> actions;

  /// Called with `true` when FAB opens and `false` when it closes.
  /// Use this to render a dismissal barrier outside this widget.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<ExpandableFab> createState() => ExpandableFabState();
}

// Public so callers can hold a GlobalKey<ExpandableFabState> and call close().
class ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    // Ensure parent knows FAB closed if widget is removed while open
    if (_open) widget.onOpenChanged?.call(false);
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    widget.onOpenChanged?.call(_open);
  }

  void close() {
    if (!_open) return;
    setState(() => _open = false);
    _ctrl.reverse();
    widget.onOpenChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Child action buttons (bottom to top).
        // IgnorePointer when closed so invisible buttons cannot receive taps.
        ...widget.actions.asMap().entries.map((e) {
          final i = e.key;
          final action = e.value;
          final delay = i * 0.08;
          final end = (delay + 0.55).clamp(0.0, 1.0);

          final slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _ctrl,
            curve: Interval(delay, end, curve: Curves.easeOutBack),
          ));

          final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _ctrl,
              curve: Interval(delay, end, curve: Curves.easeOut),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IgnorePointer(
              ignoring: !_open,
              child: FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: _ActionButton(
                    action: action,
                    onTap: () {
                      close();
                      action.onTap();
                    },
                  ),
                ),
              ),
            ),
          );
        }).toList().reversed,

        const SizedBox(height: 10),

        // Main FAB
        _MainFab(controller: _ctrl, open: _open, onTap: _toggle),
      ],
    );
  }
}

// ── Main FAB ──────────────────────────────────────────────────────────────────

class _MainFab extends StatefulWidget {
  const _MainFab(
      {required this.controller, required this.open, required this.onTap});
  final AnimationController controller;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_MainFab> createState() => _MainFabState();
}

class _MainFabState extends State<_MainFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.92,
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
    final rotate = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (_, child) => Transform.rotate(
            angle: rotate.value,
            child: child,
          ),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.open
                    ? [
                        AppColors.negative.withValues(alpha: 0.9),
                        AppColors.negative,
                      ]
                    : [AppColors.emerald, AppColors.emeraldDim],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.open ? AppColors.negative : AppColors.emerald)
                      .withValues(alpha: 0.32),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: AppColors.textInverse, size: 26),
          ),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.action, required this.onTap});
  final FabAction action;
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
      lowerBound: 0.92,
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
    final a = widget.action;
    return GestureDetector(
      onTapDown: (_) {
        _press.reverse();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: a.color.withValues(alpha: 0.20), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                a.label,
                style: AppTypography.labelM.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Icon button
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: a.color.withValues(alpha: 0.30), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: a.color.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(a.icon, size: 18, color: a.color),
            ),
          ],
        ),
      ),
    );
  }
}

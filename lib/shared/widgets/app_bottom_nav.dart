import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vexa_colors_ext.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/home/presentation/providers/home_provider.dart';

// ── Nav item descriptor ───────────────────────────────────────────────────────

enum _NavTabType { home, wallet, coach, budget, goals }

class _NavItem {
  const _NavItem({required this.type, required this.label});
  final _NavTabType type;
  final String label;
}

// ── Main nav bar ──────────────────────────────────────────────────────────────

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  static const _items = [
    _NavItem(type: _NavTabType.home, label: 'Inicio'),
    _NavItem(type: _NavTabType.wallet, label: 'Cartera'),
    _NavItem(type: _NavTabType.coach, label: 'Vexa Coach'),
    _NavItem(type: _NavTabType.budget, label: 'Presupuesto'),
    _NavItem(type: _NavTabType.goals, label: 'Metas'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selected = ref.watch(selectedNavIndexProvider);
    final animated = ref.watch(animationsEnabledProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.bottomNavBottomPadding,
      ),
      child: Container(
        height: AppSpacing.bottomNavHeight,
        decoration: BoxDecoration(
          color: c.cardElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: c.glassBorderStrong,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            return _NavButton(
              item: _items[i],
              isActive: i == selected,
              animated: animated,
              onTap: () {
                ref.read(selectedNavIndexProvider.notifier).state = i;
              },
            );
          }),
        ),
      ),
    );
  }
}

// ── Nav button with per-tab animations ────────────────────────────────────────

class _NavButton extends ConsumerStatefulWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.animated,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final bool animated;
  final VoidCallback onTap;

  @override
  ConsumerState<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends ConsumerState<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Shared animations
  late final Animation<double> _scale;

  // Tab-specific animations
  late final Animation<double> _rotate;      // wallet + settings
  late final Animation<double> _barHeight;   // analysis bars pulse
  late final Animation<double> _arcProgress; // budget arc fill

  bool _prevActive = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    // Scale: smooth lift → settle (all tabs)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 55),
    ]).animate(_ctrl);

    // Vertical lift for wallet + goals (Y offset in logical pixels)
    _rotate = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -4.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: -4.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 60),
    ]).animate(_ctrl);

    // Bar scale for analysis: subtle grow → settle
    _barHeight = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.22)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 38),
      TweenSequenceItem(
          tween: Tween(begin: 1.22, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 62),
    ]).animate(_ctrl);

    // Arc progress for budget: 0 → 1 → 0
    _arcProgress = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_prevActive && widget.animated) {
      _ctrl
        ..reset()
        ..forward();
    }
    _prevActive = widget.isActive;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) {
                final s = widget.animated ? _scale.value : 1.0;
                return Transform.scale(
                  scale: s,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? AppColors.emeraldSurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildIcon(),
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.labelS.copyWith(
                color: widget.isActive
                    ? AppColors.emerald
                    : context.colors.textTertiary,
                fontWeight: widget.isActive
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontSize: 9,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color =
        widget.isActive ? AppColors.emerald : context.colors.textTertiary;

    return switch (widget.item.type) {
      _NavTabType.home => _HomeIcon(color: color, ctrl: _ctrl, animated: widget.animated),
      _NavTabType.wallet => _WalletIcon(color: color, rotate: _rotate, animated: widget.animated),
      _NavTabType.coach => _CoachIcon(color: color, pulse: _barHeight, animated: widget.animated),
      _NavTabType.budget => _BudgetCircleIcon(color: color, arcProgress: _arcProgress, animated: widget.animated),
      _NavTabType.goals => _GoalsIcon(color: color, lift: _rotate, animated: widget.animated),
    };
  }
}

// ── Home icon — scale pulse ───────────────────────────────────────────────────

class _HomeIcon extends StatelessWidget {
  const _HomeIcon(
      {required this.color, required this.ctrl, required this.animated});
  final Color color;
  final AnimationController ctrl;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.grid_view_rounded, size: 22, color: color);
  }
}

// ── Wallet icon — rocking open ────────────────────────────────────────────────

class _WalletIcon extends StatelessWidget {
  const _WalletIcon(
      {required this.color,
      required this.rotate,
      required this.animated});
  final Color color;
  final Animation<double> rotate;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotate,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, animated ? rotate.value : 0),
        child: child,
      ),
      child: Icon(Icons.account_balance_wallet_rounded, size: 22, color: color),
    );
  }
}

// ── Coach icon — sparkle with subtle scale pulse ──────────────────────────────

class _CoachIcon extends StatelessWidget {
  const _CoachIcon(
      {required this.color, required this.pulse, required this.animated});
  final Color color;
  final Animation<double> pulse;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) => Transform.scale(
        scale: animated ? pulse.value : 1.0,
        child: child,
      ),
      child: Icon(Icons.auto_awesome_rounded, size: 22, color: color),
    );
  }
}

// ── Budget arc icon — arc sweeps around ──────────────────────────────────────

class _BudgetCircleIcon extends StatelessWidget {
  const _BudgetCircleIcon(
      {required this.color,
      required this.arcProgress,
      required this.animated});
  final Color color;
  final Animation<double> arcProgress;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: arcProgress,
      builder: (_, child) => SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: _ArcIconPainter(
            color: color,
            progress: animated ? arcProgress.value : 0,
          ),
          child: Center(
            child: Icon(Icons.pie_chart_rounded, size: 11, color: color),
          ),
        ),
      ),
    );
  }
}

class _ArcIconPainter extends CustomPainter {
  const _ArcIconPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    // Fill arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcIconPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Goals icon — flag with vertical lift ─────────────────────────────────────

class _GoalsIcon extends StatelessWidget {
  const _GoalsIcon(
      {required this.color, required this.lift, required this.animated});
  final Color color;
  final Animation<double> lift;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lift,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, animated ? lift.value : 0),
        child: child,
      ),
      child: Icon(Icons.flag_rounded, size: 22, color: color),
    );
  }
}

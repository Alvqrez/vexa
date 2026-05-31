import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/home/presentation/providers/home_provider.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  static const _items = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Análisis'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Cartera'),
    _NavItem(icon: Icons.flag_rounded, label: 'Metas'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.glassBorderStrong,
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

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
  late final AnimationController _bounce;
  late final Animation<double> _scale;
  late final Animation<double> _iconRotate;

  bool _prevActive = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Scale: normal → squish → overshoot → settle
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.78)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.78, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_bounce);

    // Subtle rotation: ±8 degrees and back
    _iconRotate = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.14)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.14, end: 0.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.10, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_prevActive && widget.animated) {
      _bounce
        ..reset()
        ..forward();
    }
    _prevActive = widget.isActive;
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) {
                final s = widget.animated ? _scale.value : 1.0;
                final r = widget.animated ? _iconRotate.value : 0.0;
                return Transform.scale(
                  scale: s,
                  child: Transform.rotate(
                    angle: r,
                    child: child,
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppColors.emeraldSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 22,
                  color: widget.isActive
                      ? AppColors.emerald
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.labelS.copyWith(
                color:
                    widget.isActive ? AppColors.emerald : AppColors.textTertiary,
                fontWeight:
                    widget.isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

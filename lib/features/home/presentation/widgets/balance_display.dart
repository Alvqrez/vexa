import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../providers/home_provider.dart';

class BalanceDisplay extends ConsumerStatefulWidget {
  const BalanceDisplay({super.key});

  @override
  ConsumerState<BalanceDisplay> createState() => _BalanceDisplayState();
}

class _BalanceDisplayState extends ConsumerState<BalanceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: AppCurves.gentle);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.spring));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(totalBalanceProvider);
    final animated = ref.watch(animationsEnabledProvider);

    return FadeTransition(
      opacity: animated ? _fade : const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: animated
            ? _slide
            : const AlwaysStoppedAnimation(Offset.zero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eyebrow pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassLight,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.glassBorderStrong,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BALANCE TOTAL',
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Main balance with change badge
            AnimatedNumber(
              value: balance,
              style: AppTypography.displayL.copyWith(
                color: AppColors.textPrimary,
              ),
              showChangeBadge: true,
              animate: animated,
            ),
            const SizedBox(height: 14),
            _MonthlyBadge(),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.emeraldSurface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.emeraldGlow, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 11,
            color: AppColors.emerald,
          ),
          const SizedBox(width: 4),
          Text(
            '12.1% vs el mes anterior.',
            style: AppTypography.labelS.copyWith(
              color: AppColors.emerald,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

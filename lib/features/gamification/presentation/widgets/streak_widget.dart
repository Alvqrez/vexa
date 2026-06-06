import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/vexa_colors_ext.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../providers/gamification_provider.dart';

class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: Color(0xFFFF6B35),
          ),
          const SizedBox(width: 4),
          Text(
            '${streak.currentStreak} días',
            style: AppTypography.labelM.copyWith(
              color: const Color(0xFFFF6B35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Builder(builder: (ctx) {
          final c = ctx.colors;
          return Row(
          children: [
            _FlameIcon(active: streak.isActiveToday),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RACHA ACTIVA',
                    style: AppTypography.eyebrow.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${streak.currentStreak}',
                        style: AppTypography.headingM.copyWith(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        streak.currentStreak == 1 ? 'día' : 'días seguidos',
                        style: AppTypography.bodyS.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Récord',
                  style: AppTypography.labelS.copyWith(
                    color: c.textTertiary,
                  ),
                ),
                Text(
                  '${streak.longestStreak} días',
                  style: AppTypography.labelM.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );}),
      ),
    );
  }
}

class _FlameIcon extends StatefulWidget {
  const _FlameIcon({required this.active});
  final bool active;

  @override
  State<_FlameIcon> createState() => _FlameIconState();
}

class _FlameIconState extends State<_FlameIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    if (widget.active) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF6B35);
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.local_fire_department_rounded,
          size: 22,
          color: widget.active ? color : context.colors.textTertiary,
        ),
      ),
    );
  }
}

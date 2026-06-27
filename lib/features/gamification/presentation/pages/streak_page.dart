import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/gamification_provider.dart';

class StreakPage extends ConsumerStatefulWidget {
  const StreakPage({super.key});

  @override
  ConsumerState<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends ConsumerState<StreakPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    const flameColor = Color(0xFFFF6B35);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Glow background
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    flameColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Header
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Haptics.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Mi racha',
                            style: AppTypography.headingM.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Hero flame + current streak
                      Center(
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _pulse,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: flameColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: flameColor.withValues(alpha: 0.25),
                                      blurRadius: 40,
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 52,
                                  color: flameColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              '${streak.currentStreak}',
                              style: AppTypography.displayL.copyWith(
                                color: flameColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              streak.currentStreak == 1
                                  ? 'día seguido'
                                  : 'días seguidos',
                              style: AppTypography.bodyL.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: streak.isActiveToday
                                    ? flameColor.withValues(alpha: 0.14)
                                    : c.glass,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.pillRadius,
                                ),
                                border: Border.all(
                                  color: streak.isActiveToday
                                      ? flameColor.withValues(alpha: 0.30)
                                      : c.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    streak.isActiveToday
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 12,
                                    color: streak.isActiveToday
                                        ? flameColor
                                        : c.textTertiary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    streak.isActiveToday
                                        ? 'Racha activa hoy'
                                        : 'Registra hoy para continuar',
                                    style: AppTypography.labelM.copyWith(
                                      color: streak.isActiveToday
                                          ? flameColor
                                          : c.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '${streak.currentStreak}',
                              label: 'Racha actual',
                              icon: Icons.local_fire_department_rounded,
                              color: flameColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              value: '${streak.longestStreak}',
                              label: 'Mejor racha',
                              icon: Icons.emoji_events_rounded,
                              color: AppColors.catEntertainment,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Tips
                      Text(
                        'Cómo mantener tu racha',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._tips.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _TipRow(tip: t),
                        ),
                      ),

                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _tips = [
    (
      icon: Icons.add_circle_outline_rounded,
      text: 'Registra al menos una transacción al día para mantener tu racha.',
    ),
    (
      icon: Icons.notifications_outlined,
      text:
          'Activa las notificaciones para recibir un recordatorio si no has registrado nada.',
    ),
    (
      icon: Icons.calendar_today_rounded,
      text:
          'Hazlo parte de tu rutina: revisa tus gastos cada noche antes de dormir.',
    ),
  ];
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.headingM.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelS.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.tip});
  final ({IconData icon, String text}) tip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.petroleumSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(tip.icon, size: 15, color: AppColors.petroleum),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tip.text,
              style: AppTypography.bodyS.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

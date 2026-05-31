import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../domain/models/achievement.dart';
import '../providers/gamification_provider.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();
    final totalXp = ref.watch(totalXpProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // bg glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.catEntertainment.withValues(alpha: 0.10),
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
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Header
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Logros',
                            style: AppTypography.headingM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // XP summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.catEntertainment.withValues(alpha: 0.14),
                              AppColors.petroleum.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                            color: AppColors.catEntertainment
                                .withValues(alpha: 0.20),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.catEntertainment
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                size: 24,
                                color: AppColors.catEntertainment,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$totalXp XP acumulados',
                                    style: AppTypography.headingS.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${unlocked.length} de ${achievements.length} logros',
                                    style: AppTypography.bodyS.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(unlocked.length / achievements.length * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.headingS.copyWith(
                                    color: AppColors.catEntertainment,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'completado',
                                  style: AppTypography.labelS
                                      .copyWith(color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Unlocked section
                      if (unlocked.isNotEmpty) ...[
                        Text(
                          'Desbloqueados',
                          style: AppTypography.headingS
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.3,
                          children: unlocked
                              .map((a) =>
                                  _AchievementCard(achievement: a, locked: false))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Locked section
                      if (locked.isNotEmpty) ...[
                        Text(
                          'Por desbloquear',
                          style: AppTypography.headingS
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.3,
                          children: locked
                              .map((a) =>
                                  _AchievementCard(achievement: a, locked: true))
                              .toList(),
                        ),
                      ],

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
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.locked,
  });

  final Achievement achievement;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? AppColors.textTertiary
        : achievement.tier.color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: locked
              ? Colors.white.withValues(alpha: 0.04)
              : color.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: locked ? 0.06 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  locked ? Icons.lock_outline_rounded : achievement.icon,
                  size: 15,
                  color: color,
                ),
              ),
              const Spacer(),
              if (!locked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    achievement.tier.label,
                    style: AppTypography.eyebrow.copyWith(color: color),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            locked ? '???' : achievement.title,
            style: AppTypography.labelL.copyWith(
              color:
                  locked ? AppColors.textTertiary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            locked ? achievement.description : '+${achievement.xpReward} XP',
            style: AppTypography.labelS.copyWith(
              color: locked ? AppColors.textTertiary : color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

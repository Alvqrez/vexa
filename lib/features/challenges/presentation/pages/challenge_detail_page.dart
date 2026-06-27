import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../widgets/month_heatmap.dart';

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final all = ref.watch(challengesProvider);
    final ch = all.where((x) => x.id == challengeId).firstOrNull;

    if (ch == null) {
      // El reto fue eliminado — cerrar de forma segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final doneToday = ch.frequency == ChallengeFrequency.weekly
        ? ch.isWeekDone(now)
        : ch.isDoneToday;
    final canMarkToday = !ch.isFinished && ch.isScheduled(now);

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  ch.color.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // ── Top bar ──────────────────────────────────
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
                                color: c.glass,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: c.glassBorder, width: 0.5),
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  size: 18, color: c.textSecondary),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _confirmDelete(context, ref, ch),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.negative
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: AppColors.negative
                                        .withValues(alpha: 0.25),
                                    width: 0.5),
                              ),
                              child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.negative),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Identidad del reto ───────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: ch.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color:
                                        ch.color.withValues(alpha: 0.30)),
                              ),
                              child:
                                  Icon(ch.icon, size: 34, color: ch.color),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(ch.name,
                                style: AppTypography.headingM
                                    .copyWith(color: c.textPrimary),
                                textAlign: TextAlign.center),
                            if (ch.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(ch.description,
                                  style: AppTypography.bodyS.copyWith(
                                      color: c.textSecondary, height: 1.4),
                                  textAlign: TextAlign.center),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: ch.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.pillRadius),
                              ),
                              child: Text(
                                '${ch.frequency.label} · ${ch.durationDays} días',
                                style: AppTypography.labelM.copyWith(
                                    color: ch.color,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Stats ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Racha actual',
                              value: '${ch.currentStreak}',
                              icon: Icons.local_fire_department_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Mejor racha',
                              value: '${ch.longestStreak}',
                              icon: Icons.emoji_events_outlined,
                              color: ch.color,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Cumplimiento',
                              value:
                                  '${(ch.completionRate * 100).round()}%',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.positive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Heatmap mensual ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border:
                              Border.all(color: c.glassBorder, width: 0.5),
                        ),
                        child: MonthHeatmap(
                          accentColor: ch.color,
                          firstMonth: ch.startDate,
                          dayBuilder: (day) => _dayFor(ch, day),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Marcar hoy ───────────────────────────────
                      if (canMarkToday)
                        GestureDetector(
                          onTap: () {
                            Haptics.mediumImpact();
                            ref
                                .read(challengesProvider.notifier)
                                .toggleDay(ch.id, now);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: doneToday
                                  ? null
                                  : LinearGradient(colors: [
                                      ch.color,
                                      ch.color.withValues(alpha: 0.75)
                                    ]),
                              color: doneToday
                                  ? ch.color.withValues(alpha: 0.12)
                                  : null,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius),
                              border: doneToday
                                  ? Border.all(
                                      color: ch.color
                                          .withValues(alpha: 0.35))
                                  : null,
                              boxShadow: doneToday
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: ch.color
                                            .withValues(alpha: 0.28),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  doneToday
                                      ? Icons.undo_rounded
                                      : Icons.check_rounded,
                                  size: 18,
                                  color: doneToday
                                      ? ch.color
                                      : AppColors.textInverse,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  doneToday
                                      ? 'Hecho hoy — tocar para deshacer'
                                      : 'Marcar como hecho hoy',
                                  style: AppTypography.labelL.copyWith(
                                    color: doneToday
                                        ? ch.color
                                        : AppColors.textInverse,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (ch.isFinished)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSurface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.emerald
                                    .withValues(alpha: 0.25),
                                width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 20, color: AppColors.emerald),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Reto terminado con ${(ch.completionRate * 100).round()}% de cumplimiento y una mejor racha de ${ch.longestStreak}.',
                                  style: AppTypography.labelM.copyWith(
                                      color: AppColors.emerald,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 60),
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

  HeatmapDay _dayFor(Challenge ch, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);

    if (!ch.isScheduled(d)) {
      return const HeatmapDay(status: HeatmapDayStatus.unscheduled);
    }
    if (ch.isDoneOn(d)) return const HeatmapDay(status: HeatmapDayStatus.done);
    if (d.isBefore(today)) {
      // En frecuencia semanal, un día sin marca no es omitido si la semana
      // se cumplió con otro día.
      if (ch.frequency == ChallengeFrequency.weekly && ch.isWeekDone(d)) {
        return const HeatmapDay(status: HeatmapDayStatus.unscheduled);
      }
      return const HeatmapDay(status: HeatmapDayStatus.missed);
    }
    return const HeatmapDay(status: HeatmapDayStatus.pending);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Challenge ch) {
    Haptics.selectionClick();
    final c = context.colors;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: c.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text('¿Eliminar reto?',
            style: AppTypography.headingS.copyWith(color: c.textPrimary)),
        content: Text(
          'Se perderá todo el progreso de "${ch.name}". Esta acción no se puede deshacer.',
          style: AppTypography.bodyM
              .copyWith(color: c.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancelar',
                style:
                    AppTypography.labelL.copyWith(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Haptics.mediumImpact();
              Navigator.of(dialogCtx).pop();
              ref.read(challengesProvider.notifier).remove(ch.id);
            },
            child: Text('Eliminar',
                style: AppTypography.labelL.copyWith(
                    color: AppColors.negative,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: AppTypography.headingS.copyWith(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelS.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}

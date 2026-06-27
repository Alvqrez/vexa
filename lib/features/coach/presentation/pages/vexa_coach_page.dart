import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/providers/settings_provider.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../calendar/presentation/pages/financial_calendar_page.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../domain/models/vexa_score.dart';
import '../../domain/insights_engine.dart';
import '../providers/vexa_score_provider.dart';
import '../providers/coach_insights_provider.dart';
import '../widgets/coach_charts.dart';
import '../widgets/cashflow_projection_section.dart';
import 'time_machine_page.dart';

/// Centro de inteligencia financiera de Vexa.
/// Rediseñado: Score + 3 acciones rápidas + selector Insights / Tu mes.
class VexaCoachPage extends ConsumerStatefulWidget {
  const VexaCoachPage({super.key});

  @override
  ConsumerState<VexaCoachPage> createState() => _VexaCoachPageState();
}

class _VexaCoachPageState extends ConsumerState<VexaCoachPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int _tab = 0; // 0 = Insights, 1 = Tu mes

  static const _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..revealForward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final start = (i / _sectionCount * 0.50).clamp(0.0, 0.65);
    final end = (start + 0.55).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: AppCurves.gentle),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  void _showProjection() {
    Haptics.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const _ProjectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _CoachBg(),
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

                    // ── Header ────────────────────────────────────────────
                    _reveal(0, const _CoachHeader()),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Vexa Score ────────────────────────────────────────
                    _reveal(1, const _VexaScoreCard()),
                    const SizedBox(height: AppSpacing.lg),

                    // ── 3 quick-action chips ──────────────────────────────
                    _reveal(2, _QuickActionRow(
                      onProjection: _showProjection,
                    )),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Tab selector ──────────────────────────────────────
                    _reveal(3, _CoachTabSelector(
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    )),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Tab content ───────────────────────────────────────
                    _reveal(
                      4,
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _tab == 0
                            ? const _InsightsSection(
                                key: ValueKey('insights'))
                            : const _MonthAnalysis(
                                key: ValueKey('month')),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.bottomNavHeight +
                          AppSpacing.bottomNavBottomPadding +
                          AppSpacing.xxxl,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _CoachBg extends StatelessWidget {
  const _CoachBg();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 380,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CoachHeader extends ConsumerWidget {
  const _CoachHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vexa Coach',
                  style:
                      AppTypography.headingM.copyWith(color: c.textPrimary)),
              const SizedBox(height: 2),
              Text('Tu centro de inteligencia financiera',
                  style:
                      AppTypography.labelM.copyWith(color: c.textTertiary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FinancialCalendarPage()),
          ),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.calendar_month_rounded,
                size: 17, color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Vexa Score ────────────────────────────────────────────────────────────────

class _VexaScoreCard extends ConsumerStatefulWidget {
  const _VexaScoreCard();

  @override
  ConsumerState<_VexaScoreCard> createState() => _VexaScoreCardState();
}

class _VexaScoreCardState extends ConsumerState<_VexaScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arc;
  late Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arc = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _arcAnim = CurvedAnimation(parent: _arc, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _arc.forward();
    });
  }

  @override
  void dispose() {
    _arc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final score = ref.watch(vexaScoreProvider);
    final deltaAsync = ref.watch(vexaScoreDeltaProvider);
    final level = score.level;
    final color = level.color;

    if (!score.hasData) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.speed_rounded,
                  size: 24, color: AppColors.emerald),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu Vexa Score',
                      style: AppTypography.labelL.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Registra tus primeros movimientos para calcular '
                    'tu puntuación financiera.',
                    style: AppTypography.labelM
                        .copyWith(color: c.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final weakest = score.weakestFactor;
    final delta = deltaAsync.valueOrNull;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _arcAnim,
                builder: (_, child) => SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _ScoreArcPainter(
                      progress: score.score / 100 * _arcAnim.value,
                      color: color,
                      trackColor: color.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(score.score * _arcAnim.value).round()}',
                            style: AppTypography.headingM.copyWith(
                              color: color,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('de 100',
                              style: AppTypography.labelS.copyWith(
                                  color: c.textTertiary, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VEXA SCORE',
                        style: AppTypography.eyebrow
                            .copyWith(color: c.textTertiary)),
                    const SizedBox(height: 4),
                    Text(level.label,
                        style: AppTypography.headingS.copyWith(
                            color: color, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (delta != null && delta.abs() >= 0.5)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: delta >= 0
                              ? AppColors.emeraldSurface
                              : AppColors.negativeSurface,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.pillRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              delta >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 11,
                              color: delta >= 0
                                  ? AppColors.emerald
                                  : AppColors.negative,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${delta.abs().round()} pts esta semana',
                              style: AppTypography.labelS.copyWith(
                                color: delta >= 0
                                    ? AppColors.emerald
                                    : AppColors.negative,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text('Se actualiza cada semana',
                          style: AppTypography.labelS
                              .copyWith(color: c.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _FactorPill(label: 'Ahorro', value: score.savingsScore),
              const SizedBox(width: 6),
              _FactorPill(label: 'Presupuesto', value: score.budgetScore),
              const SizedBox(width: 6),
              _FactorPill(
                  label: 'Consistencia', value: score.consistencyScore),
              const SizedBox(width: 6),
              _FactorPill(label: 'Control', value: score.excessScore),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 15, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tu punto débil es ${weakest.name.toLowerCase()} '
                    '(${weakest.value.round()}/100). ${weakest.advice}',
                    style: AppTypography.labelS.copyWith(
                        color: c.textSecondary, height: 1.45),
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

class _FactorPill extends StatelessWidget {
  const _FactorPill({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = value >= 70
        ? AppColors.emerald
        : value >= 40
            ? AppColors.warning
            : AppColors.negative;
    return Expanded(
      child: Column(
        children: [
          Text('${value.round()}',
              style: AppTypography.labelL
                  .copyWith(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelS
                  .copyWith(color: c.textTertiary, fontSize: 9)),
        ],
      ),
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  const _ScoreArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle:
              startAngle + sweepAngle * progress.clamp(0.0, 1.0),
          colors: [color.withValues(alpha: 0.5), color],
        ).createShader(
            Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Quick action chips row ────────────────────────────────────────────────────

class _QuickActionRow extends ConsumerWidget {
  const _QuickActionRow({required this.onProjection});
  final VoidCallback onProjection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.timeline_rounded,
            label: 'Proyección',
            color: AppColors.petroleum,
            subtitle: '30–90 días',
            onTap: onProjection,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionChip(
            icon: Icons.history_toggle_off_rounded,
            label: 'Time Machine',
            color: const Color(0xFF7C5CFC),
            subtitle: 'Simular futuro',
            onTap: () {
              Haptics.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimeMachinePage()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
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
    final c = context.colors;
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 17, color: widget.color),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTypography.labelM.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  widget.subtitle!,
                  style: AppTypography.labelS.copyWith(
                    color: c.textTertiary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab selector ──────────────────────────────────────────────────────────────

class _CoachTabSelector extends StatelessWidget {
  const _CoachTabSelector({
    required this.selected,
    required this.onChanged,
  });
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Insights',
            icon: Icons.auto_awesome_rounded,
            active: selected == 0,
            onTap: () => onChanged(0),
          ),
          _Tab(
            label: 'Tu mes',
            icon: Icons.bar_chart_rounded,
            active: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Haptics.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: active ? c.card : Colors.transparent,
            borderRadius:
                BorderRadius.circular(AppSpacing.pillRadius),
            border: active
                ? Border.all(color: c.glassBorder, width: 0.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: active
                    ? AppColors.petroleum
                    : c.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelM.copyWith(
                  color: active ? c.textPrimary : c.textTertiary,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Insights tab ──────────────────────────────────────────────────────────────

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(coachInsightsProvider);

    if (insights.isEmpty) {
      return _EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Sin insights aún',
        body: 'Registra transacciones y Vexa Coach analizará tus patrones.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InsightCard(insight: insight),
          )).toList(),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final CoachInsight insight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bgColor = switch (insight.type) {
      InsightType.positive => AppColors.positive.withValues(alpha: 0.05),
      InsightType.warning => AppColors.warning.withValues(alpha: 0.05),
      InsightType.neutral => c.glassMedium,
    };
    final borderColor = switch (insight.type) {
      InsightType.positive => AppColors.positive.withValues(alpha: 0.15),
      InsightType.warning => AppColors.warning.withValues(alpha: 0.15),
      InsightType.neutral => c.glassBorder,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, size: 16, color: insight.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: AppTypography.labelL.copyWith(
                        color: c.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(insight.body,
                    style: AppTypography.labelM
                        .copyWith(color: c.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Tu mes" tab ──────────────────────────────────────────────────────────────

class _MonthAnalysis extends ConsumerWidget {
  const _MonthAnalysis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthSectionHeader(),
        SizedBox(height: AppSpacing.md),
        CoachOverviewRow(),
        SizedBox(height: AppSpacing.md),
        CoachInterpretCard(),
        SizedBox(height: AppSpacing.xl),
        CoachDailyHeatMap(),
        SizedBox(height: AppSpacing.xl),
        CoachCategoryMonthlyBars(),
        SizedBox(height: AppSpacing.xl),
        CoachCategoryPieChart(),
        SizedBox(height: AppSpacing.xl),
        CoachCategoryBreakdown(),
        SizedBox(height: AppSpacing.xl),
        // Incluye su propio espaciado inferior cuando hay datos.
        CoachTopSubcategoriesList(),
        CoachTopSpendsList(),
      ],
    );
  }
}

// ── Month section header (selector ← mes →) ───────────────────────────────────

class _MonthSectionHeader extends ConsumerWidget {
  const _MonthSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selected = ref.watch(selectedAnalysisMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selected.year == now.year && selected.month == now.month;
    final label = DateFormat('MMMM yyyy', 'es').format(selected);
    final capitalized = label[0].toUpperCase() + label.substring(1);

    return Row(
      children: [
        Expanded(
          child: Text('Tu mes en detalle',
              style: AppTypography.headingS.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
        ),
        GestureDetector(
          onTap: () {
            Haptics.selectionClick();
            ref.read(selectedAnalysisMonthProvider.notifier).state =
                DateTime(selected.year, selected.month - 1);
          },
          child: Icon(Icons.chevron_left_rounded,
              size: 20, color: c.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(capitalized,
            style:
                AppTypography.labelM.copyWith(color: c.textTertiary)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: isCurrentMonth
              ? null
              : () {
                  Haptics.selectionClick();
                  ref.read(selectedAnalysisMonthProvider.notifier).state =
                      DateTime(selected.year, selected.month + 1);
                },
          child: Icon(Icons.chevron_right_rounded,
              size: 20,
              color: isCurrentMonth
                  ? c.textTertiary.withValues(alpha: 0.3)
                  : c.textSecondary),
        ),
      ],
    );
  }
}

// ── Projection sheet ──────────────────────────────────────────────────────────

class _ProjectionSheet extends StatelessWidget {
  const _ProjectionSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.glassBorderStrong,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              child: const CashflowProjectionSection(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.emeraldSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: AppColors.emerald),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTypography.labelL.copyWith(
                  color: c.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.labelM
                .copyWith(color: c.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

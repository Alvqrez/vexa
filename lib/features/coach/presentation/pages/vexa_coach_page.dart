import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../calendar/presentation/pages/financial_calendar_page.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../challenges/presentation/pages/challenges_page.dart';
import '../../../challenges/presentation/providers/challenges_provider.dart';
import '../../domain/models/vexa_score.dart';
import '../../domain/insights_engine.dart';
import '../providers/vexa_score_provider.dart';
import '../providers/coach_insights_provider.dart';
import '../widgets/coach_charts.dart';
import '../widgets/cashflow_projection_section.dart';
import 'time_machine_page.dart';

/// Centro de inteligencia financiera de Vexa: score, insights, retos,
/// proyecciones, Time Machine y el análisis completo del mes.
class VexaCoachPage extends StatefulWidget {
  const VexaCoachPage({super.key});

  @override
  State<VexaCoachPage> createState() => _VexaCoachPageState();
}

class _VexaCoachPageState extends State<VexaCoachPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  static const _sectionCount = 12;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final start = i / _sectionCount * 0.55;
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
                    _reveal(0, const _CoachHeader()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(1, const _VexaScoreCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, const _InsightsSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _ChallengesEntryCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const CashflowProjectionSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(5, const _TimeMachineEntryCard()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(6, const _MonthSectionHeader()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(7, const CoachOverviewRow()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(7, const CoachInterpretCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(8, const CoachBalanceLineChart()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(9, const CoachSpendingTrendCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(10, const CoachCategoryPieChart()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(11, const CoachCategoryBreakdown()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(11, const CoachTopSpendsList()),
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

// ── Vexa Score (header principal) ─────────────────────────────────────────────

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
              // Gauge
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

          // Factores
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

          // Explicación: el factor más débil
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
          endAngle: startAngle + sweepAngle * progress.clamp(0.0, 1.0),
          colors: [color.withValues(alpha: 0.5), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Insights inteligentes ─────────────────────────────────────────────────────

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(coachInsightsProvider);
    final c = context.colors;
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald, AppColors.petroleum],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Insights de tu dinero',
                style: AppTypography.headingS.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InsightCard(insight: insight),
            )),
      ],
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

// ── Acceso a retos y hábitos ──────────────────────────────────────────────────

class _ChallengesEntryCard extends ConsumerWidget {
  const _ChallengesEntryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final active = ref.watch(activeChallengesProvider);
    final pending = ref.watch(pendingTodayProvider);

    final subtitle = active.isEmpty
        ? 'Construye hábitos que cuidan tu dinero'
        : pending > 0
            ? '$pending reto${pending == 1 ? '' : 's'} pendiente${pending == 1 ? '' : 's'} hoy'
            : '¡Todo al día! ${active.length} reto${active.length == 1 ? '' : 's'} en curso';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChallengesPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.30),
              width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  size: 20, color: AppColors.warning),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Retos y hábitos',
                      style: AppTypography.labelL.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.labelS
                          .copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (pending > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Text('$pending',
                    style: AppTypography.labelS.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800)),
              ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Acceso a Time Machine ─────────────────────────────────────────────────────

class _TimeMachineEntryCard extends StatelessWidget {
  const _TimeMachineEntryCard();

  static const _accent = Color(0xFF7C5CFC);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimeMachinePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accent.withValues(alpha: 0.14),
              _accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border:
              Border.all(color: _accent.withValues(alpha: 0.30), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_accent, Color(0xFF5A3FD4)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_toggle_off_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vexa Time Machine',
                      style: AppTypography.labelL.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Descubre cuánto valdría ese gasto en el futuro',
                      style: AppTypography.labelS
                          .copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Encabezado de la sección "Tu mes" con selector ────────────────────────────

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
            HapticFeedback.selectionClick();
            ref.read(selectedAnalysisMonthProvider.notifier).state =
                DateTime(selected.year, selected.month - 1);
          },
          child: Icon(Icons.chevron_left_rounded,
              size: 20, color: c.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(capitalized,
            style: AppTypography.labelM.copyWith(color: c.textTertiary)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: isCurrentMonth
              ? null
              : () {
                  HapticFeedback.selectionClick();
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

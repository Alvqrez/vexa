import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/financial_health.dart';
import '../providers/health_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class FinancialHealthPage extends ConsumerStatefulWidget {
  const FinancialHealthPage({super.key});

  @override
  ConsumerState<FinancialHealthPage> createState() =>
      _FinancialHealthPageState();
}

class _FinancialHealthPageState extends ConsumerState<FinancialHealthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(financialHealthProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final currency = ref.watch(currencySymbolProvider);
    // Display net (income − expenses) as the saving metric on this page
    final savings = income - expenses;
    final color = _colorFor(health.status);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.12), Colors.transparent],
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
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Salud financiera',
                            style: AppTypography.headingM.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Main score hero
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _scoreAnim,
                              builder: (context2, child2) => _BigGauge(
                                score: health.score * _scoreAnim.value,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.pillRadius,
                                ),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.30),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                health.status.label,
                                style: AppTypography.labelL.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Text(
                                health.status.description,
                                style: AppTypography.bodyS.copyWith(
                                  color: c.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Monthly summary
                      Text(
                        'Este mes',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MonthStat(
                              label: 'Ingresos',
                              value: '$currency${income.toStringAsFixed(0)}',
                              color: AppColors.positive,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _MonthStat(
                              label: 'Egresos',
                              value: '$currency${expenses.toStringAsFixed(0)}',
                              color: AppColors.negative,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _MonthStat(
                              label: 'Neto',
                              value: savings >= 0
                                  ? '+$currency${savings.toStringAsFixed(0)}'
                                  : '-$currency${savings.abs().toStringAsFixed(0)}',
                              color: savings >= 0
                                  ? AppColors.emerald
                                  : AppColors.negative,
                              icon: Icons.savings_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Score breakdown
                      Text(
                        'Desglose',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ScoreBreakdown(health: health),
                      const SizedBox(height: AppSpacing.xxl),

                      // Recommendations
                      Text(
                        'Recomendaciones',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._recommendations(
                        health,
                        income,
                        expenses,
                        savings,
                      ).map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _RecommendationCard(rec: r),
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

  List<_Rec> _recommendations(
    FinancialHealth h,
    double income,
    double expenses,
    double savings,
  ) {
    final recs = <_Rec>[];

    if (savings < 0) {
      recs.add(
        const _Rec(
          icon: Icons.warning_rounded,
          color: AppColors.negative,
          title: 'Gastos mayores que ingresos',
          body:
              'Este mes estás gastando más de lo que ganas. Revisa tus egresos y elimina gastos no esenciales.',
        ),
      );
    }

    if (income > 0 && savings / income < 0.10) {
      recs.add(
        const _Rec(
          icon: Icons.savings_rounded,
          color: AppColors.warning,
          title: 'Tasa de ahorro baja',
          body:
              'Intentá ahorrar al menos el 20% de tus ingresos. Empieza con el 10% si aún no llegas.',
        ),
      );
    }

    if (h.budgetScore >= 80) {
      recs.add(
        const _Rec(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.emerald,
          title: 'Buen control del presupuesto',
          body:
              'Estás gastando dentro de tus posibilidades. Sigue así para mejorar tu score.',
        ),
      );
    }

    if (h.savingsScore < 50) {
      recs.add(
        const _Rec(
          icon: Icons.lightbulb_outline_rounded,
          color: AppColors.petroleum,
          title: 'Regla 50/30/20',
          body:
              'Destina el 50% a necesidades, 30% a deseos y al menos 20% al ahorro.',
        ),
      );
    }

    if (recs.isEmpty) {
      recs.add(
        const _Rec(
          icon: Icons.star_rounded,
          color: AppColors.catEntertainment,
          title: '¡Excelente gestión financiera!',
          body:
              'Tu salud financiera es óptima. Considera invertir tu excedente de ahorro.',
        ),
      );
    }

    return recs;
  }

  Color _colorFor(HealthStatus s) => switch (s) {
    HealthStatus.excellent => AppColors.emerald,
    HealthStatus.regular => AppColors.warning,
    HealthStatus.risky => AppColors.negative,
  };
}

// ── Big gauge ─────────────────────────────────────────────────────────────────

class _BigGauge extends StatelessWidget {
  const _BigGauge({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _GaugePainter(score: score, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTypography.displayM.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'de 100',
                style: AppTypography.labelM.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * (score / 100),
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (score > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * (score / 100),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

// ── Score breakdown ───────────────────────────────────────────────────────────

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.health});
  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Ahorro',
            description: '% de ingresos ahorrados',
            value: health.savingsScore / 100,
            color: AppColors.emerald,
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BreakdownRow(
            label: 'Presupuesto',
            description: 'Control de gastos vs ingresos',
            value: health.budgetScore / 100,
            color: AppColors.petroleum,
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BreakdownRow(
            label: 'Ingresos',
            description: 'Estabilidad de ingresos',
            value: health.incomeScore / 100,
            color: AppColors.catTransport,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String description;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelL.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(value * 100).toStringAsFixed(0)} pts',
                    style: AppTypography.labelM.copyWith(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: AppTypography.labelS.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Month stat ────────────────────────────────────────────────────────────────

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headingS.copyWith(color: color, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelS.copyWith(color: context.colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Recommendation ────────────────────────────────────────────────────────────

class _Rec {
  const _Rec({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec});
  final _Rec rec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: rec.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: rec.color.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rec.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(rec.icon, size: 16, color: rec.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: AppTypography.labelL.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rec.body,
                  style: AppTypography.labelS.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
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

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../domain/models/financial_health.dart';
import '../pages/financial_health_page.dart';
import '../providers/health_provider.dart';

class HealthScoreWidget extends ConsumerStatefulWidget {
  const HealthScoreWidget({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends ConsumerState<HealthScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
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
    final color = _colorForStatus(health.status);

    if (widget.compact) return _CompactHealth(health: health, color: color);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinancialHealthPage()),
      ),
      child: Container(
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.favorite_rounded, size: 15, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'SALUD FINANCIERA',
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.textTertiary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    health.status.label,
                    style: AppTypography.labelS
                        .copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (context, _) => _ScoreGauge(
                    score: health.score * _scoreAnim.value,
                    color: color,
                    size: 80,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        health.status.description,
                        style: AppTypography.bodyS
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ScoreBar(
                        label: 'Ahorro',
                        value: health.savingsScore / 100,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ScoreBar(
                        label: 'Presupuesto',
                        value: health.budgetScore / 100,
                        color: AppColors.petroleum,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Color _colorForStatus(HealthStatus status) => switch (status) {
        HealthStatus.excellent => AppColors.emerald,
        HealthStatus.regular => AppColors.warning,
        HealthStatus.risky => AppColors.negative,
      };
}

// ── Score gauge ───────────────────────────────────────────────────────────────

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({
    required this.score,
    required this.color,
    required this.size,
  });

  final double score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(score: score, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTypography.headingM.copyWith(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/100',
                style: AppTypography.labelS
                    .copyWith(color: AppColors.textTertiary),
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
    final radius = size.width / 2 - 4;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (score / 100),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

// ── Score bar ─────────────────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    AppTypography.labelS.copyWith(color: AppColors.textTertiary)),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: AppTypography.labelS.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ── Compact variant ───────────────────────────────────────────────────────────

class _CompactHealth extends StatelessWidget {
  const _CompactHealth({required this.health, required this.color});
  final FinancialHealth health;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          health.status.label,
          style: AppTypography.labelS
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Text(
          '${health.score.toStringAsFixed(0)}/100',
          style: AppTypography.labelS.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

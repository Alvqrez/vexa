import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';

// Short month names in Spanish for axis labels.
const _months = [
  '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _fmtAmt(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
  return v.toStringAsFixed(0);
}

class BalanceChartCard extends ConsumerStatefulWidget {
  const BalanceChartCard({super.key});

  @override
  ConsumerState<BalanceChartCard> createState() => _BalanceChartCardState();
}

class _BalanceChartCardState extends ConsumerState<BalanceChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
        _anim.forward();
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final history = ref.watch(balanceHistoryProvider);
    final currency = ref.watch(currencySymbolProvider);

    if (history.length < 2) return const SizedBox.shrink();

    final values = history.map((p) => p.balance).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final padY = range > 0 ? range * 0.20 : 100.0;

    final spots = history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.balance))
        .toList();

    final isPositive = values.last >= values.first;
    final lineColor = isPositive ? AppColors.emerald : AppColors.negative;
    final emptySpots = spots.map((s) => FlSpot(s.x, minY)).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance',
                  style: AppTypography.headingS.copyWith(
                    color: c.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lineColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    'Últimos 30 días',
                    style: AppTypography.labelS.copyWith(
                      color: lineColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Chart ────────────────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: LineChart(
              _ready
                  ? _buildData(c, spots, lineColor, minY, maxY, padY, currency, history)
                  : _buildData(c, emptySpots, lineColor, minY, maxY, padY, currency, history),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _Footer(history: history, currency: currency, lineColor: lineColor),
          ),
        ],
      ),
    );
  }

  LineChartData _buildData(
    dynamic c,
    List<FlSpot> spots,
    Color lineColor,
    double minY,
    double maxY,
    double padY,
    String currency,
    List<BalancePoint> history,
  ) {
    final yInterval = ((maxY - minY) + 2 * padY) / 4;

    return LineChartData(
      clipData: const FlClipData.all(),
      minY: minY - padY,
      maxY: maxY + padY,

      // ── Touch tooltip ────────────────────────────────────────────────────
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => c.card,
          tooltipBorder: BorderSide(color: c.glassBorderStrong, width: 0.5),
          tooltipRoundedRadius: AppSpacing.cardRadius.toDouble(),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
            final idx = s.spotIndex.clamp(0, history.length - 1);
            final point = history[idx];
            final d = point.date;
            final label = '${d.day} ${_months[d.month]}';
            return LineTooltipItem(
              '$currency${point.balance.toStringAsFixed(0)}\n',
              AppTypography.labelM.copyWith(
                color: lineColor,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: label,
                  style: AppTypography.labelS.copyWith(color: c.textTertiary),
                ),
              ],
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
      ),

      // ── Grid ─────────────────────────────────────────────────────────────
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval > 0 ? yInterval : 100,
        getDrawingHorizontalLine: (_) => FlLine(
          color: c.glassBorder.withValues(alpha: 0.5),
          strokeWidth: 0.5,
          dashArray: [4, 6],
        ),
      ),
      borderData: FlBorderData(show: false),

      // ── Axes ─────────────────────────────────────────────────────────────
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

        // Y axis — amounts
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: yInterval > 0 ? yInterval : 100,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _fmtAmt(value),
                  textAlign: TextAlign.right,
                  style: AppTypography.labelS.copyWith(
                    color: c.textTertiary,
                    fontSize: 9.5,
                  ),
                ),
              );
            },
          ),
        ),

        // X axis — dates
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 6,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
              // Only show first, ~middle ticks, and last to avoid crowding
              if (idx != 0 && idx != spots.length - 1) {
                final isInterval = idx % 6 == 0;
                if (!isInterval) return const SizedBox.shrink();
              }
              final d = history[idx].date;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${d.day} ${_months[d.month]}',
                  style: AppTypography.labelS.copyWith(
                    color: c.textTertiary,
                    fontSize: 9,
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // ── Line ─────────────────────────────────────────────────────────────
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: lineColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) => spot.x == spots.last.x,
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: lineColor,
              strokeWidth: 2,
              strokeColor: c.card,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.18),
                lineColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.history,
    required this.currency,
    required this.lineColor,
  });

  final List<BalancePoint> history;
  final String currency;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (history.length < 2) return const SizedBox.shrink();

    final first = history.first.balance;
    final last = history.last.balance;
    final delta = last - first;
    final pct = first != 0 ? (delta / first.abs()) * 100 : 0.0;
    final isUp = delta >= 0;
    final color = isUp ? AppColors.positive : AppColors.negative;

    return Row(
      children: [
        Icon(
          isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${isUp ? '+' : ''}$currency${delta.abs().toStringAsFixed(0)} (${pct.abs().toStringAsFixed(1)}%)',
          style: AppTypography.labelS.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          'vs hace 30 días',
          style: AppTypography.labelS.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}

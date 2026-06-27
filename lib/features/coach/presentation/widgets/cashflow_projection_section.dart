import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/cashflow_projection_provider.dart';
import 'coach_charts.dart';

/// "Si continúas así, ¿cómo se verá tu dinero?"
/// Proyección de saldo a 30/60/90 días con desglose de ingresos,
/// gastos variables, suscripciones y préstamos.
class CashflowProjectionSection extends ConsumerStatefulWidget {
  const CashflowProjectionSection({super.key});

  @override
  ConsumerState<CashflowProjectionSection> createState() =>
      _CashflowProjectionSectionState();
}

class _CashflowProjectionSectionState
    extends ConsumerState<CashflowProjectionSection> {
  int _windowIdx = 0; // 0=30d, 1=60d, 2=90d

  String _fmt(double v, String sym) {
    final abs = v.abs();
    final sign = v < 0 ? '-' : '';
    final s = abs >= 1000
        ? '$sign$sym${(abs / 1000).toStringAsFixed(1)}k'
        : '$sign$sym${abs.toStringAsFixed(0)}';
    return pmask(s);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final projection = ref.watch(cashflowProjectionProvider);
    final currency = ref.watch(currencySymbolProvider);

    if (!projection.hasHistory) {
      return CoachSectionCard(
        title: 'Proyección financiera',
        badge: '30–90 días',
        badgeColor: AppColors.petroleum,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.timeline_rounded,
                  size: 22, color: c.textTertiary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Registra algunos movimientos y aquí verás cómo se '
                  'proyecta tu dinero en los próximos meses.',
                  style: AppTypography.bodyS
                      .copyWith(color: c.textTertiary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final window = projection.windows[_windowIdx];
    final days = window.days;
    final positive = window.projectedBalance >= projection.currentBalance;

    return CoachSectionCard(
      title: 'Si continúas así…',
      badge: 'proyección',
      badgeColor: AppColors.petroleum,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector 30/60/90 ─────────────────────────────────────────
          Row(
            children: List.generate(3, (i) {
              final d = [30, 60, 90][i];
              final sel = i == _windowIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    Haptics.selectionClick();
                    setState(() => _windowIdx = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: i < 2 ? AppSpacing.sm : 0),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.emeraldSurface : c.glass,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : c.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('$d días',
                        style: AppTypography.labelM.copyWith(
                          color:
                              sel ? AppColors.emerald : c.textTertiary,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Saldo proyectado ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo proyectado en $days días',
                        style: AppTypography.labelS
                            .copyWith(color: c.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(window.projectedBalance, currency),
                      style: AppTypography.headingM.copyWith(
                        color: window.projectedBalance >= 0
                            ? (positive
                                ? AppColors.emerald
                                : AppColors.warning)
                            : AppColors.negative,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: positive
                      ? AppColors.emeraldSurface
                      : AppColors.negativeSurface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: positive
                          ? AppColors.emerald
                          : AppColors.negative,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(
                          window.projectedBalance -
                              projection.currentBalance,
                          currency),
                      style: AppTypography.labelM.copyWith(
                        color: positive
                            ? AppColors.emerald
                            : AppColors.negative,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Curva diaria ──────────────────────────────────────────────
          SizedBox(
            height: 130,
            child: _ProjectionChart(
              balances: projection.dailyBalances.sublist(0, days + 1),
              currency: currency,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Desglose ──────────────────────────────────────────────────
          _BreakdownRow(
            icon: Icons.south_rounded,
            color: AppColors.positive,
            label: 'Ingresos estimados',
            value: '+${_fmt(window.expectedIncome, currency)}',
          ),
          _BreakdownRow(
            icon: Icons.north_rounded,
            color: AppColors.negative,
            label: 'Gastos variables estimados',
            value: '-${_fmt(window.variableExpenses, currency)}',
          ),
          if (window.subscriptionCount > 0)
            _BreakdownRow(
              icon: Icons.subscriptions_rounded,
              color: AppColors.warning,
              label:
                  'Suscripciones (${window.subscriptionCount} cobro${window.subscriptionCount == 1 ? '' : 's'})',
              value: '-${_fmt(window.subscriptionCosts, currency)}',
            ),
          if (window.loanInflows > 0)
            _BreakdownRow(
              icon: Icons.call_received_rounded,
              color: AppColors.emerald,
              label: 'Préstamos por cobrar',
              value: '+${_fmt(window.loanInflows, currency)}',
            ),
          if (window.loanOutflows > 0)
            _BreakdownRow(
              icon: Icons.call_made_rounded,
              color: AppColors.negative,
              label: 'Préstamos por pagar',
              value: '-${_fmt(window.loanOutflows, currency)}',
            ),
          if (projection.activeGoalsTarget > 0) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Divider(
                  height: 1, thickness: 0.5, color: c.glassBorder),
            ),
            _BreakdownRow(
              icon: Icons.flag_outlined,
              color: AppColors.petroleum,
              label: 'Metas activas (por completar)',
              value: _fmt(
                  projection.activeGoalsTarget -
                      projection.activeGoalsSaved,
                  currency),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label,
                style:
                    AppTypography.labelM.copyWith(color: c.textSecondary)),
          ),
          Text(value,
              style: AppTypography.labelL.copyWith(
                  color: c.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.balances, required this.currency});
  final List<double> balances;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spots = List.generate(
        balances.length, (i) => FlSpot(i.toDouble(), balances[i]));
    var minY = balances.reduce((a, b) => a < b ? a : b);
    var maxY = balances.reduce((a, b) => a > b ? a : b);
    if ((maxY - minY).abs() < 1) {
      minY -= 50;
      maxY += 50;
    } else {
      final pad = (maxY - minY) * 0.15;
      minY -= pad;
      maxY += pad;
    }
    final lineColor = balances.last >= balances.first
        ? AppColors.emerald
        : AppColors.negative;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (balances.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: c.glassBorder,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: ((balances.length - 1) / 3).floorToDouble().clamp(
                  1, double.infinity),
              getTitlesWidget: (value, meta) {
                final d = value.toInt();
                if (d == 0) {
                  return Text('Hoy',
                      style: AppTypography.labelS.copyWith(
                          color: AppColors.emerald, fontSize: 9));
                }
                return Text('+${d}d',
                    style: AppTypography.labelS
                        .copyWith(color: c.textTertiary, fontSize: 9));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.cardElevated,
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem(
                      'Día +${s.x.toInt()}\n$currency${s.y.toStringAsFixed(0)}',
                      AppTypography.labelM.copyWith(
                          color: lineColor, fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.15),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// Widgets de análisis financiero del Vexa Coach.
// Migrados desde la antigua pestaña Análisis y reorganizados:
// cada gráfica va acompañada de interpretación, no solo datos.

// ── Shared surface card ───────────────────────────────────────────────────────

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Shared section card ───────────────────────────────────────────────────────

class CoachSectionCard extends StatelessWidget {
  const CoachSectionCard({
    super.key,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.child,
  });
  final String title;
  final String badge;
  final Color badgeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: c.glass,
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          color: c.cardElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: AppTypography.headingS
                        .copyWith(color: context.colors.textPrimary)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(badge,
                      style:
                          AppTypography.eyebrow.copyWith(color: badgeColor)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Overview row (ingresos / gastos / ahorrado) ───────────────────────────────

class CoachOverviewRow extends ConsumerWidget {
  const CoachOverviewRow({super.key});

  String _fmt(double v, String sym) {
    if (v >= 1000) return '$sym${(v / 1000).toStringAsFixed(1)}k';
    return '$sym${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(analysisIncomeProvider);
    final expenses = ref.watch(analysisExpensesProvider);
    final savings = ref.watch(monthlySavingsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Ingresos',
            value: _fmt(income, currency),
            icon: Icons.south_rounded,
            color: AppColors.positive,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Gastos',
            value: _fmt(expenses, currency),
            icon: Icons.north_rounded,
            color: AppColors.negative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Ahorrado',
            value: _fmt(savings, currency),
            icon: Icons.savings_outlined,
            color: AppColors.petroleum,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: context.colors.glass,
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(value,
                style: AppTypography.headingS.copyWith(
                    color: context.colors.textPrimary, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.labelS
                    .copyWith(color: context.colors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ── Balance line chart (7 días) ───────────────────────────────────────────────

class CoachBalanceLineChart extends ConsumerStatefulWidget {
  const CoachBalanceLineChart({super.key});

  @override
  ConsumerState<CoachBalanceLineChart> createState() =>
      _CoachBalanceLineChartState();
}

class _CoachBalanceLineChartState
    extends ConsumerState<CoachBalanceLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<FlSpot> _buildSpots(List<Transaction> transactions) {
    final now = DateTime.now();
    final dayTotals = <int, double>{};
    for (var d = 0; d < 7; d++) {
      dayTotals[d] = 0;
    }
    for (final t in transactions) {
      final daysAgo = now.difference(t.date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final day = 6 - daysAgo;
        dayTotals[day] =
            (dayTotals[day] ?? 0) + (t.isIncome ? t.amount : -t.amount);
      }
    }
    double running = 0;
    return List.generate(7, (i) {
      running += dayTotals[i] ?? 0;
      return FlSpot(i.toDouble(), running);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final spots = _buildSpots(transactions);
    final minY = spots.map((s) => s.y).reduce(math.min) - 50;
    final maxY = spots.map((s) => s.y).reduce(math.max) + 50;

    final dayLabels = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('E', 'es').format(d);
    });

    return CoachSectionCard(
      title: 'Evolución del balance',
      badge: '7 días',
      badgeColor: AppColors.petroleum,
      child: SizedBox(
        height: 180,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final progress = _anim.value;
            final visibleSpots = spots
                .take((spots.length * progress)
                    .ceil()
                    .clamp(1, spots.length))
                .toList();

            return LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: c.glassBorder,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          dayLabels[i],
                          style: AppTypography.labelS.copyWith(
                            color: i == 6
                                ? AppColors.emerald
                                : c.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => c.cardElevated,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '$currency${s.y.toStringAsFixed(0)}',
                              AppTypography.labelM.copyWith(
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.emerald,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index != visibleSpots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeColor: Colors.transparent,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.emerald,
                          strokeWidth: 2,
                          strokeColor: c.background,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.emerald.withValues(alpha: 0.18),
                          AppColors.emerald.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Spending trend bar chart (6 meses) ────────────────────────────────────────

class CoachSpendingTrendCard extends ConsumerStatefulWidget {
  const CoachSpendingTrendCard({super.key});

  @override
  ConsumerState<CoachSpendingTrendCard> createState() =>
      _CoachSpendingTrendCardState();
}

class _CoachSpendingTrendCardState
    extends ConsumerState<CoachSpendingTrendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bar;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _barAnim = CurvedAnimation(parent: _bar, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _bar.forward();
    });
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  String _monthAbbr(int month) {
    const abbrs = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return abbrs[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(monthlySpendingTrendProvider);
    final now = DateTime.now();
    final currentLabel = _monthAbbr(now.month);

    return CoachSectionCard(
      title: 'Tendencia de gastos',
      badge: '6 meses',
      badgeColor: AppColors.negative,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _barAnim,
            builder: (context, child) {
              final c = context.colors;
              return SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _BarChartPainter(
                    data: data,
                    progress: _barAnim.value,
                    currentLabel: currentLabel,
                    barColor: c.glassMedium,
                    lineColor: c.glassBorder,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              final c = context.colors;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((d) {
                  final isCurrent = d.label == currentLabel;
                  return Text(
                    d.label,
                    style: AppTypography.labelS.copyWith(
                      color:
                          isCurrent ? AppColors.emerald : c.textTertiary,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.data,
    required this.progress,
    required this.currentLabel,
    required this.barColor,
    required this.lineColor,
  });
  final List<({String label, double value})> data;
  final double progress;
  final String currentLabel;
  final Color barColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold(0.0, (m, d) => math.max(m, d.value));
    if (maxVal == 0) return;
    final barWidth = size.width / data.length * 0.5;
    final gap = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final isCurrent = d.label == currentLabel;
      final barH = (d.value / maxVal) * size.height * progress;
      final x = gap * i + gap / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, size.height - barH, barWidth, barH),
        const Radius.circular(6),
      );
      if (isCurrent) {
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.emerald, AppColors.emeraldDim],
            ).createShader(Rect.fromLTWH(
                x - barWidth / 2, size.height - barH, barWidth, barH)),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = AppColors.emerald.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      } else {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = barColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - barWidth / 2, size.height - barH, barWidth, 2),
            const Radius.circular(6),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.12),
        );
      }
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.currentLabel != currentLabel ||
      old.barColor != barColor ||
      old.lineColor != lineColor;
}

// ── Category pie chart ────────────────────────────────────────────────────────

class CoachCategoryPieChart extends ConsumerStatefulWidget {
  const CoachCategoryPieChart({super.key});

  @override
  ConsumerState<CoachCategoryPieChart> createState() =>
      _CoachCategoryPieChartState();
}

class _CoachCategoryPieChartState
    extends ConsumerState<CoachCategoryPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 700), () {
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
    final breakdown = ref.watch(analysisCategoryBreakdownProvider);
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final walletCats = ref.watch(walletCategoriesProvider);
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final resolved = entries
        .map((e) => (
              cat: resolveCategory(e.key, walletCats),
              value: e.value,
            ))
        .toList();

    return CoachSectionCard(
      title: 'Distribución por categoría',
      badge: 'este mes',
      badgeColor: AppColors.petroleum,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) => PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = response
                                ?.touchedSection?.touchedSectionIndex ??
                            -1;
                      });
                    },
                  ),
                  sections: resolved.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value.cat;
                    final value = entry.value.value;
                    final pct = value / total;
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      value: value * _anim.value,
                      color: cat.color,
                      radius: isTouched ? 42 : 36,
                      title: pct > 0.1
                          ? '${(pct * 100).toStringAsFixed(0)}%'
                          : '',
                      titleStyle: AppTypography.labelS.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                      titlePositionPercentageOffset: 0.55,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: resolved.take(5).map((item) {
                final pct = item.value / total;
                final c = context.colors;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.cat.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(item.cat.name,
                            style: AppTypography.labelS
                                .copyWith(color: c.textSecondary)),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTypography.labelS.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown (barras de progreso) ───────────────────────────────────

class CoachCategoryBreakdown extends ConsumerWidget {
  const CoachCategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(analysisCategoryBreakdownProvider);
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currency = ref.watch(currencySymbolProvider);
    final walletCats = ref.watch(walletCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Por categoría',
            style: AppTypography.headingS.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            )),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                _CatBar(
                  category: resolveCategory(entries[i].key, walletCats),
                  spent: entries[i].value,
                  total: total,
                  currency: currency,
                ),
                if (i < entries.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: context.colors.glassBorder,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CatBar extends StatefulWidget {
  const _CatBar(
      {required this.category,
      required this.spent,
      required this.total,
      required this.currency});
  final WalletCategory category;
  final double spent;
  final double total;
  final String currency;

  @override
  State<_CatBar> createState() => _CatBarState();
}

class _CatBarState extends State<_CatBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.spring);
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
    final c = context.colors;
    final ratio = widget.total > 0 ? widget.spent / widget.total : 0.0;
    final color = widget.category.color;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.category.surface,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(widget.category.icon, size: 15, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.category.name,
                      style: AppTypography.labelM
                          .copyWith(color: c.textSecondary)),
                  Text(
                      '${widget.currency}${widget.spent.toStringAsFixed(2)}',
                      style: AppTypography.labelL
                          .copyWith(color: c.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 4,
                  color: color.withValues(alpha: 0.12),
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, child) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio * _anim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top spends list ───────────────────────────────────────────────────────────

class CoachTopSpendsList extends ConsumerWidget {
  const CoachTopSpendsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final walletCats = ref.watch(walletCategoriesProvider);
    final m = ref.watch(selectedAnalysisMonthProvider);
    final expenses = transactions
        .where((t) =>
            !t.isIncome && t.date.month == m.month && t.date.year == m.year)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top = expenses.take(4).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mayores gastos',
            style: AppTypography.headingS.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4)),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            children: [
              for (int i = 0; i < top.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Builder(builder: (_) {
                        final cat =
                            resolveCategory(top[i].category, walletCats);
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cat.surface,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child:
                              Icon(cat.icon, size: 16, color: cat.color),
                        );
                      }),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(top[i].merchant,
                                style: AppTypography.labelL
                                    .copyWith(color: c.textPrimary)),
                            Text(
                                resolveCategory(
                                        top[i].category, walletCats)
                                    .name,
                                style: AppTypography.labelS
                                    .copyWith(color: c.textTertiary)),
                          ],
                        ),
                      ),
                      Text('-$currency${top[i].amount.toStringAsFixed(2)}',
                          style: AppTypography.labelL
                              .copyWith(color: AppColors.negative)),
                    ],
                  ),
                ),
                if (i < top.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: c.glassBorder,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Interpret card + sheet ────────────────────────────────────────────────────

class CoachInterpretCard extends ConsumerWidget {
  const CoachInterpretCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final income = ref.watch(analysisIncomeProvider);
    final expenses = ref.watch(analysisExpensesProvider);
    final savings = ref.watch(monthlySavingsProvider);
    final currency = ref.watch(currencySymbolProvider);

    final net = income - expenses;
    final isPositive = net >= 0;
    final preview = isPositive
        ? 'Estás ahorrando $currency${savings.toStringAsFixed(0)} este mes.'
        : 'Tus gastos superan tus ingresos por $currency${(-net).toStringAsFixed(0)}.';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _InterpretSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
              color: AppColors.petroleum.withValues(alpha: 0.30),
              width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.petroleumSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.petroleumLight),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interpretar mi mes',
                      style: AppTypography.labelL.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(preview,
                      style: AppTypography.labelS
                          .copyWith(color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _InterpretSheet extends ConsumerWidget {
  const _InterpretSheet();

  String _fmt(double v, String sym) =>
      '$sym${v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(analysisIncomeProvider);
    final expenses = ref.watch(analysisExpensesProvider);
    final txns = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final walletCats = ref.watch(walletCategoriesProvider);

    final sel = ref.watch(selectedAnalysisMonthProvider);
    final prevMonth = sel.month == 1 ? 12 : sel.month - 1;
    final prevYear = sel.month == 1 ? sel.year - 1 : sel.year;

    final prevTxns = txns.where(
        (t) => t.date.month == prevMonth && t.date.year == prevYear);
    final prevExpenses =
        prevTxns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final prevIncome =
        prevTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

    final curTxns = txns.where(
        (t) => t.date.month == sel.month && t.date.year == sel.year);
    final catTotals = <String, double>{};
    for (final t in curTxns.where((t) => !t.isIncome)) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
    }
    final topCatEntry = catTotals.isEmpty
        ? null
        : catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topCat = topCatEntry == null
        ? null
        : (
            cat: resolveCategory(topCatEntry.key, walletCats),
            value: topCatEntry.value
          );

    final net = income - expenses;
    final savingsRate = income > 0 ? ((net / income) * 100).round() : 0;
    final expenseDelta = prevExpenses > 0
        ? (((expenses - prevExpenses) / prevExpenses) * 100).round()
        : null;
    final incomeDelta = prevIncome > 0
        ? (((income - prevIncome) / prevIncome) * 100).round()
        : null;

    final isPositive = net >= 0;

    final insights = <_InterpretInsight>[
      _InterpretInsight(
        icon: isPositive
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: isPositive ? AppColors.positive : AppColors.negative,
        title: isPositive ? 'Balance positivo' : 'Balance negativo',
        body: isPositive
            ? 'Este mes llevas ${_fmt(income, currency)} en ingresos y ${_fmt(expenses, currency)} en gastos. Neto disponible: ${_fmt(net, currency)}.'
            : 'Este mes llevas ${_fmt(income, currency)} en ingresos pero ${_fmt(expenses, currency)} en gastos. Estás gastando ${_fmt(-net, currency)} más de lo que ingresas.',
      ),
      if (expenseDelta != null)
        _InterpretInsight(
          icon:
              expenseDelta > 0 ? Icons.north_rounded : Icons.south_rounded,
          color:
              expenseDelta > 0 ? AppColors.negative : AppColors.positive,
          title:
              expenseDelta > 0 ? 'Gastos en aumento' : 'Gastos a la baja',
          body: expenseDelta == 0
              ? 'Tus gastos son similares al mes anterior.'
              : 'Tus gastos ${expenseDelta > 0 ? 'subieron' : 'bajaron'} un ${expenseDelta.abs()}% respecto al mes pasado (${_fmt(prevExpenses, currency)} → ${_fmt(expenses, currency)}).',
        ),
      if (incomeDelta != null)
        _InterpretInsight(
          icon: Icons.payments_outlined,
          color: AppColors.petroleum,
          title: 'Evolución de ingresos',
          body: incomeDelta == 0
              ? 'Tus ingresos se mantienen estables respecto al mes anterior.'
              : 'Tus ingresos ${incomeDelta > 0 ? 'subieron' : 'bajaron'} un ${incomeDelta.abs()}% vs el mes pasado (${_fmt(prevIncome, currency)} → ${_fmt(income, currency)}).',
        ),
      if (topCat != null)
        _InterpretInsight(
          icon: Icons.category_outlined,
          color: AppColors.catEntertainment,
          title: 'Mayor gasto: ${topCat.cat.name}',
          body:
              '${topCat.cat.name} representa ${_fmt(topCat.value, currency)} — el ${expenses > 0 ? ((topCat.value / expenses) * 100).round() : 0}% de tus gastos totales este mes.',
        ),
      _InterpretInsight(
        icon: Icons.savings_outlined,
        color: AppColors.emerald,
        title: 'Tasa de ahorro: $savingsRate%',
        body: savingsRate >= 20
            ? 'Excelente. Estás superando el objetivo recomendado del 20% de ahorro.'
            : savingsRate > 0
                ? 'Vas bien, aunque hay margen de mejora. El objetivo es ahorrar al menos el 20% de tus ingresos.'
                : income == 0
                    ? 'Sin ingresos registrados este mes.'
                    : 'Tus gastos superan tus ingresos. Revisa qué categorías puedes reducir.',
      ),
      _InterpretInsight(
        icon: Icons.lightbulb_outline_rounded,
        color: AppColors.warning,
        title: 'Recomendación',
        body: topCat != null && expenses > 0
            ? 'Pon atención a ${topCat.cat.name}, que consume el ${((topCat.value / expenses) * 100).round()}% de tus gastos. Pequeñas reducciones ahí tendrán el mayor impacto.'
            : 'Registra tus transacciones regularmente para obtener recomendaciones personalizadas.',
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.colors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                  AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.petroleumSurface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 17, color: AppColors.petroleumLight),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('Interpretación del mes',
                      style: AppTypography.headingS
                          .copyWith(color: context.colors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxxl),
                itemCount: insights.length,
                separatorBuilder: (context2, i2) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final ins = insights[i];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: ins.color.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                          color: ins.color.withValues(alpha: 0.15),
                          width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: ins.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(ins.icon, size: 16, color: ins.color),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ins.title,
                                  style: AppTypography.labelL.copyWith(
                                      color: context.colors.textPrimary,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(ins.body,
                                  style: AppTypography.bodyS.copyWith(
                                      color: context.colors.textSecondary,
                                      height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterpretInsight {
  const _InterpretInsight({
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

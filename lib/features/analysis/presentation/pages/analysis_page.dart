import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../calendar/presentation/pages/financial_calendar_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  static const _sectionCount = 9;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        position: Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
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
        const _AnalysisBg(),
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
                    _reveal(0, const _AnalysisHeader()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _OverviewRow()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(2, const _InterpretCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _BalanceLineChartCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, _SpendingTrendCard(stagger: _stagger)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(5, const _CategoryPieChartCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(6, const _FinancialIntelligenceSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(7, const _CategoryBreakdown()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(8, const _TopSpendsList()),
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

class _AnalysisBg extends StatelessWidget {
  const _AnalysisBg();

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

class _AnalysisHeader extends ConsumerWidget {
  const _AnalysisHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAnalysisMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selected.year == now.year && selected.month == now.month;
    final label = DateFormat('MMMM yyyy', 'es').format(selected);
    final capitalized = label[0].toUpperCase() + label.substring(1);

    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Análisis',
                  style: AppTypography.headingM
                      .copyWith(color: c.textPrimary)),
              const SizedBox(height: 6),
              // Month selector
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final prev = DateTime(selected.year,
                          selected.month - 1);
                      ref
                          .read(selectedAnalysisMonthProvider.notifier)
                          .state = prev;
                    },
                    child: Icon(Icons.chevron_left_rounded,
                        size: 20, color: c.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Text(capitalized,
                      style: AppTypography.labelM
                          .copyWith(color: c.textTertiary)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: isCurrentMonth
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            final next = DateTime(selected.year,
                                selected.month + 1);
                            ref
                                .read(selectedAnalysisMonthProvider
                                    .notifier)
                                .state = next;
                          },
                    child: Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: isCurrentMonth
                            ? c.textTertiary.withValues(alpha: 0.3)
                            : c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const FinancialCalendarPage()),
          ),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.calendar_month_rounded,
                size: 17, color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Overview row ──────────────────────────────────────────────────────────────

class _OverviewRow extends ConsumerWidget {
  const _OverviewRow();

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
        borderRadius:
            BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: context.colors.glass,
        border: Border.all(
            color: context.colors.glassBorder, width: 0.5),
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

// ── Balance line chart (fl_chart) ─────────────────────────────────────────────

class _BalanceLineChartCard extends ConsumerStatefulWidget {
  const _BalanceLineChartCard();

  @override
  ConsumerState<_BalanceLineChartCard> createState() =>
      _BalanceLineChartCardState();
}

class _BalanceLineChartCardState
    extends ConsumerState<_BalanceLineChartCard>
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
        dayTotals[day] = (dayTotals[day] ?? 0) +
            (t.isIncome ? t.amount : -t.amount);
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

    return _SectionCard(
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
                .take((spots.length * progress).ceil().clamp(1, spots.length))
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

// ── Spending trend bar chart (real data) ─────────────────────────────────────

class _SpendingTrendCard extends ConsumerStatefulWidget {
  const _SpendingTrendCard({required this.stagger});
  final AnimationController stagger;

  @override
  ConsumerState<_SpendingTrendCard> createState() =>
      _SpendingTrendCardState();
}

class _SpendingTrendCardState extends ConsumerState<_SpendingTrendCard>
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

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(monthlySpendingTrendProvider);
    final now = DateTime.now();
    final currentLabel = _monthAbbr(now.month);

    return _SectionCard(
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
                      color: isCurrent ? AppColors.emerald : c.textTertiary,
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

  String _monthAbbr(int month) {
    const abbrs = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return abbrs[(month - 1).clamp(0, 11)];
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
      old.progress != progress || old.currentLabel != currentLabel ||
      old.barColor != barColor || old.lineColor != lineColor;
}

// ── Category pie chart (fl_chart) ─────────────────────────────────────────────

class _CategoryPieChartCard extends ConsumerStatefulWidget {
  const _CategoryPieChartCard();

  @override
  ConsumerState<_CategoryPieChartCard> createState() =>
      _CategoryPieChartCardState();
}

class _CategoryPieChartCardState extends ConsumerState<_CategoryPieChartCard>
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
    final resolved = entries.map((e) => (
          cat: resolveCategory(e.key, walletCats),
          value: e.value,
        )).toList();

    return _SectionCard(
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
                        _touchedIndex =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
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
                            style: AppTypography.labelS.copyWith(
                                color: c.textSecondary)),
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

// ── Financial intelligence ────────────────────────────────────────────────────

class _FinancialIntelligenceSection extends ConsumerWidget {
  const _FinancialIntelligenceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final breakdown = ref.watch(analysisCategoryBreakdownProvider);
    final income = ref.watch(analysisIncomeProvider);
    final expenses = ref.watch(analysisExpensesProvider);
    final savedToAccount = ref.watch(monthlySavingsProvider);
    final topCat = ref.watch(analysisTopCategoryProvider);
    final currency = ref.watch(currencySymbolProvider);

    final insights = _buildInsights(
      prediction: prediction,
      breakdown: breakdown,
      income: income,
      expenses: expenses,
      savedToAccount: savedToAccount,
      topCategory: topCat,
      currency: currency,
    );

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
            Text('Inteligencia financiera',
                style: AppTypography.headingS.copyWith(
                    color: context.colors.textPrimary,
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

  List<_Insight> _buildInsights({
    required MonthlyPrediction prediction,
    required Map<String, double> breakdown,
    required double income,
    required double expenses,
    required double savedToAccount,
    required WalletCategory? topCategory,
    required String currency,
  }) {
    final insights = <_Insight>[];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;
    final daysLeft = daysInMonth - daysElapsed;

    // ── 1. Proyección concreta con días restantes ─────────────────────────────
    if (income > 0 || expenses > 0) {
      final dailyExpense = daysElapsed > 0 ? expenses / daysElapsed : 0.0;
      final projectedTotal = expenses + dailyExpense * daysLeft;
      final balance = income - projectedTotal;
      if (income > 0 && balance > 0) {
        insights.add(_Insight(
          icon: Icons.calendar_today_rounded,
          color: AppColors.positive,
          title: 'Proyección al día $daysInMonth',
          body: 'Con tus ingresos de $currency${income.toStringAsFixed(0)} y '
              '$currency${dailyExpense.toStringAsFixed(0)}/día de gasto, '
              'terminarás el mes con aprox. $currency${balance.toStringAsFixed(0)} disponibles.',
          type: _InsightType.positive,
        ));
      } else if (income > 0) {
        final overrun = (projectedTotal - income).toStringAsFixed(0);
        insights.add(_Insight(
          icon: Icons.running_with_errors_rounded,
          color: AppColors.negative,
          title: 'Alerta: gastos proyectados altos',
          body: 'A $currency${dailyExpense.toStringAsFixed(0)}/día de gasto '
              'gastarás $currency$overrun más de lo que ganas este mes. '
              'Recorta $currency${(dailyExpense * 0.15).toStringAsFixed(0)}/día para salir en cero.',
          type: _InsightType.warning,
        ));
      }
    }

    // ── 2. Regla 50/30/20 adaptada al ingreso real ────────────────────────────
    if (income > 0) {
      final target50 = income * 0.50;
      final target30 = income * 0.30;
      final target20 = income * 0.20;

      // Classify spending: needs = food+transport+health, wants = rest
      const needsCats = {'wc1', 'wc2', 'wc5'}; // Comida, Transporte, Salud
      final actualNeeds = breakdown.entries
          .where((e) => needsCats.contains(e.key))
          .fold(0.0, (s, e) => s + e.value);
      final actualWants = breakdown.entries
          .where((e) => !needsCats.contains(e.key))
          .fold(0.0, (s, e) => s + e.value);

      final needsPct = (actualNeeds / income * 100).toStringAsFixed(0);
      final wantsPct = (actualWants / income * 100).toStringAsFixed(0);
      final savedPct = income > 0
          ? (savedToAccount / income * 100).toStringAsFixed(0)
          : '0';

      String body;
      _InsightType type;
      if (actualNeeds <= target50 && actualWants <= target30) {
        body = 'Regla 50/30/20 para $currency${income.toStringAsFixed(0)}: '
            'necesidades $currency${target50.toStringAsFixed(0)} (llevas $currency${actualNeeds.toStringAsFixed(0)}, $needsPct%), '
            'gustos $currency${target30.toStringAsFixed(0)} (llevas $currency${actualWants.toStringAsFixed(0)}, $wantsPct%), '
            'ahorro $currency${target20.toStringAsFixed(0)} (llevas $currency${savedToAccount.toStringAsFixed(0)}, $savedPct%). ¡Vas bien!';
        type = _InsightType.positive;
      } else if (actualNeeds > target50) {
        final excess = (actualNeeds - target50).toStringAsFixed(0);
        body = 'Regla 50/30/20: llevas $currency${actualNeeds.toStringAsFixed(0)} '
            'en necesidades — $currency$excess por encima del límite de $currency${target50.toStringAsFixed(0)} (50%). '
            'Revisa transporte y comida para recuperar ese margen.';
        type = _InsightType.warning;
      } else {
        final excess = (actualWants - target30).toStringAsFixed(0);
        body = 'Llevas $currency${actualWants.toStringAsFixed(0)} en gustos — '
            '$currency$excess por encima del límite de $currency${target30.toStringAsFixed(0)} (30%). '
            'Recorta entretenimiento o compras para quedar dentro del objetivo.';
        type = _InsightType.warning;
      }
      insights.add(_Insight(
        icon: Icons.pie_chart_outline_rounded,
        color: type == _InsightType.positive ? AppColors.emerald : AppColors.warning,
        title: 'Regla 50/30/20',
        body: body,
        type: type,
      ));
    }

    // ── 3. Acción de ahorro concreta ──────────────────────────────────────────
    if (income > 0) {
      final target20 = income * 0.20;
      if (savedToAccount == 0) {
        insights.add(_Insight(
          icon: Icons.savings_rounded,
          color: AppColors.warning,
          title: 'Acción: transfiere a Ahorro hoy',
          body: 'No has ahorrado nada este mes. '
              'Transfiere $currency${target20.toStringAsFixed(0)} (20% de tus ingresos) '
              'a tu cuenta Ahorro ahora mismo — el mejor momento es siempre el día de cobro.',
          type: _InsightType.warning,
        ));
      } else if (savedToAccount < target20) {
        final missing = (target20 - savedToAccount).toStringAsFixed(0);
        insights.add(_Insight(
          icon: Icons.savings_rounded,
          color: AppColors.petroleum,
          title: 'Ahorro: te faltan $currency$missing',
          body: 'Llevas $currency${savedToAccount.toStringAsFixed(0)} ahorrados. '
              'Para llegar al 20% ($currency${target20.toStringAsFixed(0)}) '
              'transfieres $currency$missing más a tu cuenta Ahorro antes del día $daysInMonth.',
          type: _InsightType.neutral,
        ));
      } else {
        insights.add(_Insight(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.positive,
          title: 'Objetivo de ahorro cumplido',
          body: 'Ahorraste $currency${savedToAccount.toStringAsFixed(0)} '
              '(${(savedToAccount / income * 100).toStringAsFixed(0)}% de tus ingresos). '
              'Superaste el objetivo del 20%. Considera invertir el excedente.',
          type: _InsightType.positive,
        ));
      }
    }

    // ── 4. Acción sobre la categoría más cara ─────────────────────────────────
    if (topCategory != null && breakdown.isNotEmpty && income > 0) {
      final topAmount = breakdown[topCategory.id] ?? 0;
      final reduction10 = topAmount * 0.10;
      final pctOfIncome = (topAmount / income * 100).toStringAsFixed(0);
      insights.add(_Insight(
        icon: topCategory.icon,
        color: topCategory.color,
        title: '${topCategory.name}: $pctOfIncome% de tus ingresos',
        body: 'Gastaste $currency${topAmount.toStringAsFixed(0)} en ${topCategory.name.toLowerCase()} este mes. '
            'Reducir solo un 10% ($currency${reduction10.toStringAsFixed(0)}) '
            'te daría $currency${(reduction10 * 12).toStringAsFixed(0)} extra al año.',
        type: _InsightType.neutral,
      ));
    }

    // ── 5. Velocidad de gasto vs avance del mes ───────────────────────────────
    if (income > 0 && expenses > 0) {
      final monthProgress = daysElapsed / daysInMonth;
      final spendingProgress = expenses / income;
      if (spendingProgress > monthProgress + 0.15) {
        final daysAhead = ((spendingProgress - monthProgress) * daysInMonth).round();
        insights.add(_Insight(
          icon: Icons.speed_rounded,
          color: AppColors.negative,
          title: 'Gastas más rápido de lo que ingresa',
          body: 'Llevas el ${(spendingProgress * 100).toStringAsFixed(0)}% '
              'del ingreso gastado con solo el ${(monthProgress * 100).toStringAsFixed(0)}% del mes. '
              'Vas $daysAhead días adelantado en gasto — congela compras no esenciales hasta el día ${daysElapsed + daysAhead}.',
          type: _InsightType.warning,
        ));
      }
    }

    return insights.take(5).toList();
  }
}

enum _InsightType { positive, warning, neutral }

class _Insight {
  const _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.type,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final _InsightType type;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bgColor = switch (insight.type) {
      _InsightType.positive => AppColors.positive.withValues(alpha: 0.05),
      _InsightType.warning => AppColors.warning.withValues(alpha: 0.05),
      _InsightType.neutral => c.glassMedium,
    };
    final borderColor = switch (insight.type) {
      _InsightType.positive => AppColors.positive.withValues(alpha: 0.15),
      _InsightType.warning => AppColors.warning.withValues(alpha: 0.15),
      _InsightType.neutral => c.glassBorder,
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
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(insight.body,
                    style: AppTypography.labelM.copyWith(
                        color: c.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown (progress bars) ────────────────────────────────────────

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

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
                  Text('${widget.currency}${widget.spent.toStringAsFixed(2)}',
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

class _TopSpendsList extends ConsumerWidget {
  const _TopSpendsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final walletCats = ref.watch(walletCategoriesProvider);
    final m = ref.watch(selectedAnalysisMonthProvider);
    final expenses = transactions
        .where((t) => !t.isIncome && t.date.month == m.month && t.date.year == m.year)
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
                        final cat = resolveCategory(top[i].category, walletCats);
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cat.surface,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(cat.icon, size: 16, color: cat.color),
                        );
                      }),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(top[i].merchant,
                                style: AppTypography.labelL.copyWith(
                                    color: c.textPrimary)),
                            Text(resolveCategory(top[i].category, walletCats).name,
                                style: AppTypography.labelS.copyWith(
                                    color: c.textTertiary)),
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

// ── Shared section card ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
        borderRadius:
            BorderRadius.circular(AppSpacing.cardRadiusL + 3),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(badge,
                      style: AppTypography.eyebrow
                          .copyWith(color: badgeColor)),
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

// ── Interpret card ────────────────────────────────────────────────────────────

class _InterpretCard extends ConsumerWidget {
  const _InterpretCard();

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
                  Text('Interpretar análisis',
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

// ── Interpret sheet ───────────────────────────────────────────────────────────

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
        : (cat: resolveCategory(topCatEntry.key, walletCats), value: topCatEntry.value);

    // net = income − expenses (real available cash); savings = transfers to savings accounts
    final net = income - expenses;
    final savingsRate =
        income > 0 ? ((net / income) * 100).round() : 0;
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
          icon: expenseDelta > 0
              ? Icons.north_rounded
              : Icons.south_rounded,
          color: expenseDelta > 0 ? AppColors.negative : AppColors.positive,
          title: expenseDelta > 0 ? 'Gastos en aumento' : 'Gastos a la baja',
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
          body: '${topCat.cat.name} representa ${_fmt(topCat.value, currency)} — el ${expenses > 0 ? ((topCat.value / expenses) * 100).round() : 0}% de tus gastos totales este mes.',
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg),
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
                          child: Icon(ins.icon, size: 16, color: ins.color),
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

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../calendar/presentation/pages/financial_calendar_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int _period = 1; // 0=Sem, 1=Mes, 2=Año

  static const _sectionCount = 8;

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
                    _reveal(
                      0,
                      _AnalysisHeader(
                        period: _period,
                        onPeriodChanged: (p) => setState(() => _period = p),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _OverviewRow()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, const _BalanceLineChartCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, _SpendingTrendCard(stagger: _stagger)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const _CategoryPieChartCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(5, const _FinancialIntelligenceSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(6, const _CategoryBreakdown()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(7, const _TopSpendsList()),
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
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
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

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader(
      {required this.period, required this.onPeriodChanged});
  final int period;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = DateFormat('MMMM yyyy', 'es').format(now);
    final capitalized = label[0].toUpperCase() + label.substring(1);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Análisis',
                  style: AppTypography.headingM
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(capitalized,
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        // Calendar shortcut
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const FinancialCalendarPage()),
          ),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 17, color: AppColors.textSecondary),
          ),
        ),
        _PeriodPills(selected: period, onChanged: onPeriodChanged),
      ],
    );
  }
}

class _PeriodPills extends StatelessWidget {
  const _PeriodPills({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Sem', 'Mes', 'Año'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_labels.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.emerald : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _labels[i],
                style: AppTypography.labelS.copyWith(
                  color: active
                      ? AppColors.textInverse
                      : AppColors.textTertiary,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
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
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
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
            label: 'Neto',
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
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
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
                    color: AppColors.textPrimary, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.labelS
                    .copyWith(color: AppColors.textTertiary)),
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
    final transactions = ref.watch(transactionsProvider);
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
                    color: AppColors.glassBorder,
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
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.cardElevated,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '\$${s.y.toStringAsFixed(0)}',
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
                          strokeColor: AppColors.background,
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
            builder: (context, child) => SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _BarChartPainter(
                    data: data, progress: _barAnim.value),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data.map((d) {
              final isCurrent = d.label == currentLabel;
              return Text(
                d.label,
                style: AppTypography.labelS.copyWith(
                  color: isCurrent
                      ? AppColors.emerald
                      : AppColors.textTertiary,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
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
  const _BarChartPainter({required this.data, required this.progress});
  final List<({String label, double value})> data;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold(0.0, (m, d) => math.max(m, d.value));
    final barWidth = size.width / data.length * 0.5;
    final gap = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final isCurrent = d.label == 'May';
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
            ..color = AppColors.glassMedium
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
      ..color = AppColors.glassBorder
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.progress != progress;
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
    final breakdown = ref.watch(categoryBreakdownProvider);
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                  sections: entries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value.key;
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
              children: entries.take(5).map((entry) {
                final pct = entry.value / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(entry.key.label,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTypography.labelS.copyWith(
                            color: AppColors.textPrimary,
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
    final breakdown = ref.watch(categoryBreakdownProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final topCat = ref.watch(topCategoryProvider);

    final insights = _buildInsights(
      prediction: prediction,
      breakdown: breakdown,
      income: income,
      expenses: expenses,
      topCategory: topCat,
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
                    color: AppColors.textPrimary,
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
    required Map<TransactionCategory, double> breakdown,
    required double income,
    required double expenses,
    required TransactionCategory? topCategory,
  }) {
    final insights = <_Insight>[];
    final savingsRate = income > 0 ? (income - expenses) / income : 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Insight 1: balance prediction
    if (prediction.predictedBalance > 0) {
      insights.add(_Insight(
        icon: Icons.trending_up_rounded,
        color: AppColors.positive,
        title: 'Proyección de saldo',
        body:
            'Si mantienes este ritmo, tendrás \$${prediction.predictedBalance.toStringAsFixed(0)} disponibles al final del mes.',
        type: _InsightType.positive,
      ));
    } else {
      insights.add(_Insight(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Riesgo de presupuesto',
        body:
            'A este ritmo de gasto podrías superar tus ingresos. Considera reducir gastos en los próximos ${prediction.daysLeft} días.',
        type: _InsightType.warning,
      ));
    }

    // Insight 2: savings rate
    if (savingsRate > 0) {
      final savingsFmt =
          (income * savingsRate).toStringAsFixed(0);
      insights.add(_Insight(
        icon: Icons.savings_rounded,
        color: AppColors.emerald,
        title: 'Potencial de ahorro',
        body:
            'Podrías ahorrar aproximadamente \$$savingsFmt este mes (${(savingsRate * 100).toStringAsFixed(0)}% de ingresos).',
        type: _InsightType.positive,
      ));
    }

    // Insight 3: daily average
    if (prediction.dailyAvgExpense > 0) {
      insights.add(_Insight(
        icon: Icons.today_rounded,
        color: AppColors.petroleum,
        title: 'Gasto diario promedio',
        body:
            'Gastas en promedio \$${prediction.dailyAvgExpense.toStringAsFixed(2)} por día este mes.',
        type: _InsightType.neutral,
      ));
    }

    // Insight 4: top category
    if (topCategory != null && breakdown.isNotEmpty) {
      final topAmount = breakdown[topCategory] ?? 0;
      insights.add(_Insight(
        icon: topCategory.icon,
        color: topCategory.color,
        title: 'Mayor categoría',
        body:
            'Tu mayor gasto es ${topCategory.label} con \$${topAmount.toStringAsFixed(2)} este mes.',
        type: _InsightType.neutral,
      ));
    }

    // Insight 5: month progress vs spending
    final monthProgress = now.day / daysInMonth;
    final spendingProgress =
        income > 0 ? expenses / income : 0.0;
    if (spendingProgress > monthProgress + 0.15) {
      insights.add(_Insight(
        icon: Icons.speed_rounded,
        color: AppColors.negative,
        title: 'Gasto acelerado',
        body:
            'Llevas ${(spendingProgress * 100).toStringAsFixed(0)}% del ingreso gastado con solo el ${(monthProgress * 100).toStringAsFixed(0)}% del mes transcurrido.',
        type: _InsightType.warning,
      ));
    }

    return insights.take(4).toList();
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
    final bgColor = switch (insight.type) {
      _InsightType.positive => AppColors.positive.withValues(alpha: 0.05),
      _InsightType.warning => AppColors.warning.withValues(alpha: 0.05),
      _InsightType.neutral => AppColors.glassMedium,
    };
    final borderColor = switch (insight.type) {
      _InsightType.positive => AppColors.positive.withValues(alpha: 0.15),
      _InsightType.warning => AppColors.warning.withValues(alpha: 0.15),
      _InsightType.neutral => AppColors.glassBorder,
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
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(insight.body,
                    style: AppTypography.labelM.copyWith(
                        color: AppColors.textSecondary, height: 1.5)),
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
    final breakdown = ref.watch(categoryBreakdownProvider);
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final currency = ref.watch(currencySymbolProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Por categoría',
            style: AppTypography.headingS.copyWith(
              color: AppColors.textPrimary,
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
                  category: entries[i].key,
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
                      color: AppColors.glassBorder,
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
  final TransactionCategory category;
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
                  Text(widget.category.label,
                      style: AppTypography.labelM
                          .copyWith(color: AppColors.textSecondary)),
                  Text('${widget.currency}${widget.spent.toStringAsFixed(2)}',
                      style: AppTypography.labelL
                          .copyWith(color: AppColors.textPrimary)),
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
    final transactions = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final expenses = transactions.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top = expenses.take(4).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mayores gastos',
            style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: top[i].category.surface,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(top[i].category.icon,
                            size: 16, color: top[i].category.color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(top[i].merchant,
                                style: AppTypography.labelL.copyWith(
                                    color: AppColors.textPrimary)),
                            Text(top[i].category.label,
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.textTertiary)),
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
                      color: AppColors.glassBorder,
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFF1C1C32),
              Color(0xFF141428),
              Color(0xFF0F0F1E)
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: AppTypography.headingS
                        .copyWith(color: AppColors.textPrimary)),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
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

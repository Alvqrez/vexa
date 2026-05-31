import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int _period = 1;

  static const _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _stagger,
                curve: Interval(start, end, curve: AppCurves.spring),
              ),
            ),
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
                  horizontal: AppSpacing.screenPadding,
                ),
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
                    _reveal(2, _SpendingTrendCard(stagger: _stagger)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _CategoryBreakdown()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const _TopSpendsList()),
                    const SizedBox(
                      height:
                          AppSpacing.bottomNavHeight +
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
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
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
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
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
  const _AnalysisHeader({required this.period, required this.onPeriodChanged});
  final int period;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análisis',
                style: AppTypography.headingM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mayo 2026',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
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
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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

  String _fmt(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final savings = ref.watch(monthlySavingsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Ingresos',
            value: _fmt(income),
            icon: Icons.south_rounded,
            color: AppColors.positive,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Gastos',
            value: _fmt(expenses),
            icon: Icons.north_rounded,
            color: AppColors.negative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Neto',
            value: _fmt(savings),
            icon: Icons.savings_outlined,
            color: AppColors.petroleum,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
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
            Text(
              value,
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spending trend bar chart ───────────────────────────────────────────────────

class _SpendingTrendCard extends StatefulWidget {
  const _SpendingTrendCard({required this.stagger});
  final AnimationController stagger;

  @override
  State<_SpendingTrendCard> createState() => _SpendingTrendCardState();
}

class _SpendingTrendCardState extends State<_SpendingTrendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bar;
  late Animation<double> _barAnim;

  static const _data = [
    (label: 'Dic', value: 1820.0),
    (label: 'Ene', value: 1560.0),
    (label: 'Feb', value: 2100.0),
    (label: 'Mar', value: 1750.0),
    (label: 'Abr', value: 1930.0),
    (label: 'May', value: 1200.0),
  ];

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFF1C1C32), Color(0xFF141428), Color(0xFF0F0F1E)],
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
                Text(
                  'Tendencia de gastos',
                  style: AppTypography.headingS.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.negativeSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    '6 meses',
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.negative,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            AnimatedBuilder(
              animation: _barAnim,
              builder: (context, _) => SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _BarChartPainter(
                    data: _data,
                    progress: _barAnim.value,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _data.map((d) {
                final isCurrent = d.label == 'May';
                return Text(
                  d.label,
                  style: AppTypography.labelS.copyWith(
                    color: isCurrent
                        ? AppColors.emerald
                        : AppColors.textTertiary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
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
            ..shader =
                LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.emerald, AppColors.emeraldDim],
                ).createShader(
                  Rect.fromLTWH(
                    x - barWidth / 2,
                    size.height - barH,
                    barWidth,
                    barH,
                  ),
                ),
        );
        // Glow
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
        // subtle top highlight
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - barWidth / 2, size.height - barH, barWidth, 2),
            const Radius.circular(6),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.12),
        );
      }
    }

    // Horizontal guide line
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

// ── Category breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown();

  static const _cats = [
    (cat: TransactionCategory.food, spent: 92.20, total: 1800.0),
    (cat: TransactionCategory.shopping, spent: 89.95, total: 1800.0),
    (cat: TransactionCategory.health, spent: 45.00, total: 1800.0),
    (cat: TransactionCategory.entertainment, spent: 9.99, total: 1800.0),
    (cat: TransactionCategory.transport, spent: 12.50, total: 1800.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por categoría',
          style: AppTypography.headingS.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (int i = 0; i < _cats.length; i++) ...[
                _CatBar(
                  category: _cats[i].cat,
                  spent: _cats[i].spent,
                  total: _cats[i].total,
                ),
                if (i < _cats.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
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
  const _CatBar({
    required this.category,
    required this.spent,
    required this.total,
  });
  final TransactionCategory category;
  final double spent;
  final double total;

  @override
  State<_CatBar> createState() => _CatBarState();
}

class _CatBarState extends State<_CatBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
    final ratio = widget.spent / widget.total;
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
                  Text(
                    widget.category.label,
                    style: AppTypography.labelM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${widget.spent.toStringAsFixed(2)}',
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                    builder: (_, _) => FractionallySizedBox(
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
    final expenses = transactions.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top = expenses.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mayores gastos',
          style: AppTypography.headingS.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            children: [
              for (int i = 0; i < top.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: top[i].category.surface,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          top[i].category.icon,
                          size: 16,
                          color: top[i].category.color,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              top[i].merchant,
                              style: AppTypography.labelL.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              top[i].category.label,
                              style: AppTypography.labelS.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-\$${top[i].amount.toStringAsFixed(2)}',
                        style: AppTypography.labelL.copyWith(
                          color: AppColors.negative,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < top.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
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

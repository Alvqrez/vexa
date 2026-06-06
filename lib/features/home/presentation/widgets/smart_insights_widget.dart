import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';
import '../../domain/models/transaction.dart';

// ── Public widget ─────────────────────────────────────────────────────────────

class SmartInsightsWidget extends ConsumerWidget {
  const SmartInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    if (!ref.watch(notifPrefsProvider).prediction) return const SizedBox.shrink();
    final insights = _buildInsights(ref);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald, AppColors.petroleum],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 13, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Insights',
              style: AppTypography.headingS.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Horizontal scroll of insight cards
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (context, idx) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) =>
                _InsightCard(insight: insights[i], index: i),
          ),
        ),
      ],
    );
  }

  List<_InsightData> _buildInsights(WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final savedToAccount = ref.watch(monthlySavingsProvider); // transfers to savings account
    final prediction = ref.watch(predictionProvider);
    final topCat = ref.watch(topCategoryProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);
    final currency = ref.watch(currencySymbolProvider);

    final now = DateTime.now();
    final insights = <_InsightData>[];

    // 1. Savings insight — only counts money transferred to the savings account
    if (income > 0 && savedToAccount > 0) {
      final savingsRate = savedToAccount / income;
      if (savingsRate >= 0.2) {
        insights.add(_InsightData(
          icon: Icons.savings_rounded,
          color: AppColors.positive,
          title: 'Buen ahorro',
          body: 'Ahorras el ${(savingsRate * 100).toStringAsFixed(0)}% de tus ingresos este mes.',
        ));
      } else {
        insights.add(_InsightData(
          icon: Icons.savings_rounded,
          color: AppColors.petroleum,
          title: 'Ahorro iniciado',
          body: 'Llevas $currency${savedToAccount.toStringAsFixed(0)} ahorrados. ¡Sigue así!',
        ));
      }
    } else if (income > 0 && expenses > income) {
      insights.add(_InsightData(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Gastos altos',
        body: 'Tus gastos superan tus ingresos este mes.',
      ));
    }

    // 2. Top category
    if (topCat != null && breakdown.isNotEmpty) {
      final topAmount = breakdown[topCat] ?? 0;
      insights.add(_InsightData(
        icon: topCat.icon,
        color: topCat.color,
        title: topCat.label,
        body: 'Mayor gasto: $currency${topAmount.toStringAsFixed(0)} en ${topCat.label.toLowerCase()}.',
      ));
    }

    // 3. Daily average
    if (prediction.dailyAvgExpense > 0) {
      insights.add(_InsightData(
        icon: Icons.today_rounded,
        color: AppColors.petroleum,
        title: 'Por día',
        body: 'Gastas en promedio $currency${prediction.dailyAvgExpense.toStringAsFixed(0)}/día.',
      ));
    }

    // 4. Week comparison
    final weekExpenses = transactions
        .where((t) =>
            !t.isIncome &&
            now.difference(t.date).inDays < 7 &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
    final prevWeekExpenses = transactions
        .where((t) =>
            !t.isIncome &&
            now.difference(t.date).inDays >= 7 &&
            now.difference(t.date).inDays < 14)
        .fold(0.0, (s, t) => s + t.amount);

    if (prevWeekExpenses > 0 && weekExpenses > 0) {
      final delta = (weekExpenses - prevWeekExpenses) / prevWeekExpenses;
      final pct = (delta * 100).abs().toStringAsFixed(0);
      if (delta < -0.05) {
        insights.add(_InsightData(
          icon: Icons.trending_down_rounded,
          color: AppColors.positive,
          title: 'Menos gastos',
          body: 'Gastaste $pct% menos que la semana pasada.',
        ));
      } else if (delta > 0.10) {
        insights.add(_InsightData(
          icon: Icons.trending_up_rounded,
          color: AppColors.negative,
          title: 'Más gastos',
          body: 'Gastos $pct% más altos que la semana pasada.',
        ));
      }
    }

    // 5. Month-end prediction
    if (prediction.isOnTrack && prediction.predictedBalance > 0) {
      insights.add(_InsightData(
        icon: Icons.flag_rounded,
        color: AppColors.emerald,
        title: 'Proyección',
        body: 'Finalizarás el mes con $currency${prediction.predictedBalance.toStringAsFixed(0)} disponibles.',
      ));
    }

    // 6. Income registered
    if (income > 0) {
      insights.add(_InsightData(
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.petroleum,
        title: 'Ingresos',
        body: '$currency${income.toStringAsFixed(0)} ingresados este mes.',
      ));
    }

    return insights.take(5).toList();
  }
}

// ── Insight card ──────────────────────────────────────────────────────────────

class _InsightCard extends StatefulWidget {
  const _InsightCard({required this.insight, required this.index});
  final _InsightData insight;
  final int index;

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: AppCurves.gentle);
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppCurves.spring));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
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
    final d = widget.insight;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: d.color.withValues(alpha: 0.15),
              width: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                d.color.withValues(alpha: 0.06),
                c.card,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: d.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(d.icon, size: 14, color: d.color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    d.title,
                    style: AppTypography.labelM.copyWith(
                      color: d.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Text(
                  d.body,
                  style: AppTypography.labelS.copyWith(
                    color: c.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightData {
  const _InsightData({
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';

class FinancialCalendarPage extends ConsumerStatefulWidget {
  const FinancialCalendarPage({super.key});

  @override
  ConsumerState<FinancialCalendarPage> createState() =>
      _FinancialCalendarPageState();
}

class _FinancialCalendarPageState extends ConsumerState<FinancialCalendarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _selectedDay = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _stagger.reset();
      _stagger.forward();
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _stagger.reset();
      _stagger.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final subscriptions = ref.watch(activeSubscriptionsProvider);

    // Build day → transactions map for current month
    final dayMap = <int, List<Transaction>>{};
    for (final t in transactions) {
      if (t.date.year == _currentMonth.year &&
          t.date.month == _currentMonth.month) {
        dayMap.putIfAbsent(t.date.day, () => []).add(t);
      }
    }

    // Build day → subscription list for current month
    final subMap = <int, int>{};
    for (final s in subscriptions) {
      if (s.nextBillingDate.month == _currentMonth.month &&
          s.nextBillingDate.year == _currentMonth.year) {
        subMap[s.nextBillingDate.day] = (subMap[s.nextBillingDate.day] ?? 0) + 1;
      }
    }

    final selectedTxns = _selectedDay == null
        ? <Transaction>[]
        : (dayMap[_selectedDay!.day] ?? [])
          ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _CalendarBg(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding, AppSpacing.lg,
                      AppSpacing.screenPadding, 0),
                  child: _CalHeader(
                    month: _currentMonth,
                    onBack: () => Navigator.of(context).pop(),
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // ── Month summary pills ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: _MonthSummary(dayMap: dayMap),
                ),
                const SizedBox(height: AppSpacing.lg),
                // ── Weekday headers ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: _WeekdayRow(),
                ),
                const SizedBox(height: AppSpacing.sm),
                // ── Calendar grid ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: _CalendarGrid(
                    month: _currentMonth,
                    dayMap: dayMap,
                    subMap: subMap,
                    selectedDay: _selectedDay,
                    stagger: _stagger,
                    onDayTap: (day) => setState(() => _selectedDay = day),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.glassBorder,
                    indent: AppSpacing.screenPadding,
                    endIndent: AppSpacing.screenPadding),
                const SizedBox(height: AppSpacing.md),
                // ── Selected day transactions ────────────────────────────
                Expanded(
                  child: _DayDetailPanel(
                    selectedDay: _selectedDay,
                    transactions: selectedTxns,
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

// ── Background ────────────────────────────────────────────────────────────────

class _CalendarBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.08),
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

class _CalHeader extends StatelessWidget {
  const _CalHeader({
    required this.month,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final raw = DateFormat('MMMM yyyy', 'es').format(month);
    final label = raw[0].toUpperCase() + raw.substring(1);

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendario',
                  style: AppTypography.headingM
                      .copyWith(color: AppColors.textPrimary)),
              Text('Financiero',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        // Month navigation
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.glassLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Text(label,
              style: AppTypography.labelM.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Month summary ─────────────────────────────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.dayMap});
  final Map<int, List<Transaction>> dayMap;

  @override
  Widget build(BuildContext context) {
    final allTxns = dayMap.values.expand((l) => l).toList();
    final income =
        allTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expenses = allTxns
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);

    return Row(
      children: [
        Expanded(
            child: _SummaryPill(
                label: 'Ingresos',
                value: '\$${income.toStringAsFixed(0)}',
                color: AppColors.positive)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _SummaryPill(
                label: 'Gastos',
                value: '\$${expenses.toStringAsFixed(0)}',
                color: AppColors.negative)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _SummaryPill(
                label: 'Balance',
                value: '\$${(income - expenses).toStringAsFixed(0)}',
                color: income >= expenses
                    ? AppColors.positive
                    : AppColors.negative)),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.eyebrow
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTypography.labelL
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Weekday headers ───────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _days.map((d) {
        return Expanded(
          child: Center(
            child: Text(d,
                style: AppTypography.eyebrow.copyWith(
                    color: AppColors.textTertiary, letterSpacing: 1)),
          ),
        );
      }).toList(),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.dayMap,
    required this.subMap,
    required this.selectedDay,
    required this.stagger,
    required this.onDayTap,
  });
  final DateTime month;
  final Map<int, List<Transaction>> dayMap;
  final Map<int, int> subMap;
  final DateTime? selectedDay;
  final AnimationController stagger;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    // Monday = 0 offset; Monday weekday=1 → offset 0, Sunday weekday=7 → offset 6
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final cell = row * 7 + col;
              final day = cell - startOffset + 1;
              if (cell < startOffset || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final date = DateTime(month.year, month.month, day);
              final txns = dayMap[day] ?? [];
              final subs = subMap[day] ?? 0;
              final isSelected = selectedDay?.day == day &&
                  selectedDay?.month == month.month &&
                  selectedDay?.year == month.year;
              final isToday = DateTime.now().day == day &&
                  DateTime.now().month == month.month &&
                  DateTime.now().year == month.year;

              final animIndex = (row * 7 + col).clamp(0, 20);
              final start = animIndex / 28;
              final end = (start + 0.5).clamp(0.0, 1.0);

              return Expanded(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: stagger,
                    curve: Interval(start, end, curve: AppCurves.gentle),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDayTap(date);
                    },
                    child: _DayCell(
                      day: day,
                      txns: txns,
                      subsCount: subs,
                      isSelected: isSelected,
                      isToday: isToday,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.txns,
    required this.subsCount,
    required this.isSelected,
    required this.isToday,
  });
  final int day;
  final List<Transaction> txns;
  final int subsCount;
  final bool isSelected;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final hasExpense = txns.any((t) => !t.isIncome);
    final hasIncome = txns.any((t) => t.isIncome);
    final hasSub = subsCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.emerald.withValues(alpha: 0.18)
            : isToday
                ? AppColors.glassMedium
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: AppColors.emerald.withValues(alpha: 0.5), width: 1)
            : isToday
                ? Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3), width: 0.5)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: AppTypography.labelM.copyWith(
              color: isSelected
                  ? AppColors.emerald
                  : isToday
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
              fontWeight: isSelected || isToday
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          // Indicator dots
          if (hasExpense || hasIncome || hasSub)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasIncome)
                  _Dot(color: AppColors.positive),
                if (hasExpense)
                  _Dot(color: AppColors.negative),
                if (hasSub)
                  _Dot(color: AppColors.warning),
              ],
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Day detail panel ──────────────────────────────────────────────────────────

class _DayDetailPanel extends StatelessWidget {
  const _DayDetailPanel({
    required this.selectedDay,
    required this.transactions,
  });
  final DateTime? selectedDay;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return const Center(
          child: Text('Selecciona un día',
              style: TextStyle(color: AppColors.textTertiary)));
    }

    final raw = DateFormat('EEEE d \'de\' MMMM', 'es').format(selectedDay!);
    final dayLabel = raw[0].toUpperCase() + raw.substring(1);

    final income = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(dayLabel,
                    style: AppTypography.labelL.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              if (transactions.isNotEmpty) ...[
                _DayBadge(
                    value: '+\$${income.toStringAsFixed(0)}',
                    color: AppColors.positive),
                const SizedBox(width: AppSpacing.xs),
                _DayBadge(
                    value: '-\$${expenses.toStringAsFixed(0)}',
                    color: AppColors.negative),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 32, color: AppColors.textTertiary),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Sin movimientos este día',
                          style: AppTypography.labelM
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding, 0,
                      AppSpacing.screenPadding, 120),
                  itemCount: transactions.length,
                  separatorBuilder: (_, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.glassBorder,
                    indent: AppSpacing.screenPadding,
                    endIndent: AppSpacing.screenPadding,
                  ),
                  itemBuilder: (context, i) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: _CalTxnRow(transaction: transactions[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.value, required this.color});
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(value,
          style: AppTypography.labelS.copyWith(
              color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _CalTxnRow extends StatelessWidget {
  const _CalTxnRow({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.category.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(t.category.icon, size: 16, color: t.category.color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.merchant,
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.textPrimary)),
              Text(t.category.label,
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        Text(
          t.isIncome
              ? '+\$${t.amount.toStringAsFixed(2)}'
              : '-\$${t.amount.toStringAsFixed(2)}',
          style: AppTypography.labelL.copyWith(
            color: t.isIncome ? AppColors.positive : AppColors.negative,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

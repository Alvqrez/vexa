import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/domain/models/transaction.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  static const _sectionCount = 4;

  final List<_BudgetItem> _items = [
    const _BudgetItem(category: TransactionCategory.food, spent: 92.20, limit: 300),
    const _BudgetItem(category: TransactionCategory.shopping, spent: 89.95, limit: 200),
    const _BudgetItem(category: TransactionCategory.health, spent: 45.00, limit: 100),
    const _BudgetItem(category: TransactionCategory.entertainment, spent: 9.99, limit: 50),
    const _BudgetItem(category: TransactionCategory.transport, spent: 12.50, limit: 150),
  ];

  void _showAddSheet() {
    final usedCategories = _items.map((e) => e.category).toSet();
    final available = TransactionCategory.values
        .where((c) => c != TransactionCategory.salary && !usedCategories.contains(c))
        .toList();
    if (available.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(
        available: available,
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

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
        const _BudgetBg(),
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
                    _reveal(0, const _BudgetHeader()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _BudgetOverviewCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, _BudgetCategoryList(items: _items)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, _AddBudgetButton(onTap: _showAddSheet)),
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

class _BudgetBg extends StatelessWidget {
  const _BudgetBg();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 420,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.07),
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

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuesto',
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.glassLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ],
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _BudgetOverviewCard extends StatefulWidget {
  const _BudgetOverviewCard();

  @override
  State<_BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<_BudgetOverviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arc;
  late Animation<double> _arcAnim;

  static const double _spent = 249.64;
  static const double _limit = 2000.0;

  @override
  void initState() {
    super.initState();
    _arc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _arcAnim = CurvedAnimation(parent: _arc, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _arc.forward();
    });
  }

  @override
  void dispose() {
    _arc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _spent / _limit;
    final remaining = _limit - _spent;
    final daysLeft = DateTime(
      2026,
      6,
      1,
    ).difference(DateTime.now()).inDays.clamp(0, 31);

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
              color: AppColors.emerald.withValues(alpha: 0.06),
              blurRadius: 60,
              spreadRadius: -8,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _arcAnim,
              builder: (_, _) => SizedBox(
                width: 116,
                height: 116,
                child: CustomPaint(
                  painter: _BudgetArcPainter(progress: ratio * _arcAnim.value),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: AppTypography.headingS.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'usado',
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.pillRadius,
                      ),
                    ),
                    child: Text(
                      'MAYO 2026',
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.emeraldDim,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$${_spent.toStringAsFixed(0)}',
                          style: AppTypography.headingL.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' / \$${_limit.toStringAsFixed(0)}',
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(
                    icon: Icons.savings_outlined,
                    label: 'Disponible',
                    value: '\$${remaining.toStringAsFixed(0)}',
                    color: AppColors.positive,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Días restantes',
                    value: '$daysLeft',
                    color: AppColors.petroleum,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 11, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelM.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(value, style: AppTypography.labelL.copyWith(color: color)),
      ],
    );
  }
}

class _BudgetArcPainter extends CustomPainter {
  const _BudgetArcPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 7.0;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.card
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = AppColors.emeraldGlow
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress,
          colors: [AppColors.emerald.withValues(alpha: 0.6), AppColors.emerald],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BudgetArcPainter old) => old.progress != progress;
}

// ── Category budget list ──────────────────────────────────────────────────────

class _BudgetCategoryList extends StatelessWidget {
  const _BudgetCategoryList({required this.items});

  final List<_BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Por categoría',
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${items.length} activos',
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _BudgetCategoryCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _BudgetItem {
  const _BudgetItem({
    required this.category,
    required this.spent,
    required this.limit,
  });
  final TransactionCategory category;
  final double spent;
  final double limit;
}

class _BudgetCategoryCard extends StatefulWidget {
  const _BudgetCategoryCard({required this.item});
  final _BudgetItem item;

  @override
  State<_BudgetCategoryCard> createState() => _BudgetCategoryCardState();
}

class _BudgetCategoryCardState extends State<_BudgetCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 400), () {
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
    final ratio = (widget.item.spent / widget.item.limit).clamp(0.0, 1.0);
    final remaining = widget.item.limit - widget.item.spent;
    final color = widget.item.category.color;
    final isWarning = ratio >= 0.80;

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.item.category.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    widget.item.category.icon,
                    size: 17,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.category.label,
                        style: AppTypography.labelL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${remaining.toStringAsFixed(0)} disponible',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.item.spent.toStringAsFixed(0)}',
                      style: AppTypography.labelL.copyWith(
                        color: isWarning
                            ? AppColors.warning
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'de \$${widget.item.limit.toStringAsFixed(0)}',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: color.withValues(alpha: 0.12),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio * _anim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWarning
                              ? [AppColors.warning, AppColors.warning]
                              : [color.withValues(alpha: 0.7), color],
                        ),
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
    );
  }
}

// ── Add budget button ─────────────────────────────────────────────────────────

class _AddBudgetButton extends StatelessWidget {
  const _AddBudgetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.glassBorderStrong, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.emerald,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Añadir categoría',
              style: AppTypography.labelL.copyWith(color: AppColors.emerald),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add budget sheet ──────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({required this.available, required this.onAdd});

  final List<TransactionCategory> available;
  final void Function(_BudgetItem) onAdd;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  late TransactionCategory _selected;
  final _limitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.available.first;
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '.'));
    if (limit == null || limit <= 0) return;
    widget.onAdd(_BudgetItem(category: _selected, spent: 0, limit: limit));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Nueva categoría',
              style:
                  AppTypography.headingS.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xl),

          // Category picker
          Text('Categoría',
              style:
                  AppTypography.labelM.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.available.length,
              separatorBuilder: (context2, i2) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final cat = widget.available[i];
                final isSelected = cat == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 14,
                            color: isSelected
                                ? cat.color
                                : AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected
                                ? cat.color
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Limit field
          Text('Límite mensual',
              style:
                  AppTypography.labelM.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), width: 0.5),
            ),
            child: TextField(
              controller: _limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ej. 200',
                hintStyle: AppTypography.bodyM
                    .copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.attach_money_rounded,
                    size: 18, color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Submit
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldDim],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Agregar',
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

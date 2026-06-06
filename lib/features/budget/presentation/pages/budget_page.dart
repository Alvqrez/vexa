import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/id_gen.dart';
import '../providers/budget_provider.dart';

// ── Icon + Color options ──────────────────────────────────────────────────────

const _kIconOptions = [
  Icons.fork_right_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.favorite_rounded,
  Icons.home_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.sports_esports_rounded,
  Icons.fitness_center_rounded,
  Icons.local_cafe_rounded,
  Icons.pets_rounded,
  Icons.music_note_rounded,
  Icons.health_and_safety_rounded,
  Icons.savings_rounded,
  Icons.category_rounded,
];

const _kColorOptions = [
  AppColors.catFood,
  AppColors.catTransport,
  AppColors.catShopping,
  AppColors.catEntertainment,
  AppColors.catHealth,
  AppColors.emerald,
  AppColors.petroleum,
  AppColors.negative,
  AppColors.warning,
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  AppColors.catOther,
];

// ── Page ──────────────────────────────────────────────────────────────────────

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  static const _sectionCount = 4;

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
            .animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetFormSheet(
        onSave: (item) {
          ref.read(budgetProvider.notifier).add(item);
        },
      ),
    );
  }

  void _showEditLimitSheet(BudgetItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditLimitSheet(
        item: item,
        onSave: (limit) {
          ref.read(budgetProvider.notifier).updateLimit(item.id, limit);
        },
        onDelete: () {
          ref.read(budgetProvider.notifier).delete(item.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(budgetWithSpentProvider);
    final currency = ref.watch(currencySymbolProvider);

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
                    _reveal(1, _BudgetOverviewCard(currency: currency)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, _BudgetCategoryList(
                      items: items,
                      currency: currency,
                      onTap: (item) => _showEditLimitSheet(item),
                    )),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, _AddBudgetButton(onTap: _showAddSheet)),
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

class _BudgetBg extends StatelessWidget {
  const _BudgetBg();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
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
    final c = context.colors;
    final now = DateTime.now();
    final monthLabel = () {
      final l = DateFormat('MMMM yyyy', 'es').format(now);
      return l[0].toUpperCase() + l.substring(1);
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presupuesto',
          style: AppTypography.headingM.copyWith(
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          monthLabel,
          style: AppTypography.labelM.copyWith(
            color: c.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _BudgetOverviewCard extends ConsumerStatefulWidget {
  const _BudgetOverviewCard({required this.currency});
  final String currency;

  @override
  ConsumerState<_BudgetOverviewCard> createState() =>
      _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends ConsumerState<_BudgetOverviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arc;
  late Animation<double> _arcAnim;

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
    final c = context.colors;
    final spent = ref.watch(totalBudgetSpentProvider);
    final limit = ref.watch(totalBudgetLimitProvider);
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = limit - spent;
    final now = DateTime.now();
    final firstNextMonth = DateTime(now.year, now.month + 1, 1);
    final daysLeft = firstNextMonth.difference(now).inDays.clamp(0, 31);
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(now).toUpperCase();

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
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.06),
              blurRadius: 60,
              spreadRadius: -8,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _arcAnim,
              builder: (_, child) => SizedBox(
                width: 116,
                height: 116,
                child: CustomPaint(
                  painter: _BudgetArcPainter(
                      progress: ratio * _arcAnim.value, ratio: ratio, trackColor: c.card),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'usado',
                          style: AppTypography.eyebrow.copyWith(
                            color: c.textTertiary,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                    child: Text(
                      monthLabel,
                      style: AppTypography.eyebrow
                          .copyWith(color: AppColors.emeraldDim),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${widget.currency}${spent.toStringAsFixed(0)}',
                          style: AppTypography.headingL
                              .copyWith(color: c.textPrimary),
                        ),
                        TextSpan(
                          text:
                              ' / ${widget.currency}${limit.toStringAsFixed(0)}',
                          style: AppTypography.bodyM
                              .copyWith(color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(
                    icon: Icons.savings_outlined,
                    label: 'Disponible',
                    value:
                        '${widget.currency}${remaining.toStringAsFixed(0)}',
                    color: remaining >= 0
                        ? AppColors.positive
                        : AppColors.negative,
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
    final c = context.colors;
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
            style: AppTypography.labelM.copyWith(color: c.textSecondary),
          ),
        ),
        Text(value,
            style: AppTypography.labelL.copyWith(color: color)),
      ],
    );
  }
}

class _BudgetArcPainter extends CustomPainter {
  const _BudgetArcPainter({required this.progress, required this.ratio, required this.trackColor});
  final double progress;
  final double ratio;
  final Color trackColor;

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
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final arcColor = ratio >= 1.0
        ? AppColors.negative
        : ratio >= 0.8
            ? AppColors.warning
            : AppColors.emerald;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = arcColor.withValues(alpha: 0.25)
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
          colors: [
            arcColor.withValues(alpha: 0.6),
            arcColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BudgetArcPainter old) =>
      old.progress != progress || old.ratio != ratio || old.trackColor != trackColor;
}

// ── Category list ─────────────────────────────────────────────────────────────

class _BudgetCategoryList extends StatelessWidget {
  const _BudgetCategoryList({
    required this.items,
    required this.currency,
    required this.onTap,
  });

  final List<BudgetItemWithSpent> items;
  final String currency;
  final ValueChanged<BudgetItem> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Center(
          child: Text(
            'Sin categorías de presupuesto.\nToca + para agregar.',
            style: AppTypography.labelM.copyWith(color: c.textTertiary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Por categoría',
              style: AppTypography.headingS.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${items.length} activos',
              style: AppTypography.labelS.copyWith(
                color: c.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _BudgetCategoryCard(
              item: item,
              currency: currency,
              onTap: () => onTap(item.item),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryCard extends StatefulWidget {
  const _BudgetCategoryCard({
    required this.item,
    required this.currency,
    required this.onTap,
  });
  final BudgetItemWithSpent item;
  final String currency;
  final VoidCallback onTap;

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
    final c = context.colors;
    final item = widget.item;
    final color = item.isOver
        ? AppColors.negative
        : item.isWarning
            ? AppColors.warning
            : item.item.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          color: c.glass,
          border: Border.all(
            color: item.isWarning
                ? AppColors.warning.withValues(alpha: 0.15)
                : c.glassBorder,
            width: 0.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.card,
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
                      color: item.item.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.item.icon, size: 17, color: item.item.color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item.name,
                          style: AppTypography.labelL.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        if (item.item.limit > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${widget.currency}${item.remaining.toStringAsFixed(0)} disponible',
                            style: AppTypography.labelS.copyWith(
                              color: item.isOver
                                  ? AppColors.negative
                                  : c.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.currency}${item.spent.toStringAsFixed(0)}',
                        style: AppTypography.labelL.copyWith(color: color),
                      ),
                      if (item.item.limit > 0)
                        Text(
                          'de ${widget.currency}${item.item.limit.toStringAsFixed(0)}',
                          style: AppTypography.labelS.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (item.item.limit > 0) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 5,
                    color: item.item.color.withValues(alpha: 0.12),
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, child) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: item.ratio * _anim.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.7), color],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (item.isOver) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: AppColors.negative),
                      const SizedBox(width: 4),
                      Text(
                        'Presupuesto superado',
                        style: AppTypography.labelS
                            .copyWith(color: AppColors.negative),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit limit sheet ─────────────────────────────────────────────────────────

class _EditLimitSheet extends StatefulWidget {
  const _EditLimitSheet({
    required this.item,
    required this.onSave,
    required this.onDelete,
  });
  final BudgetItem item;
  final ValueChanged<double> onSave;
  final VoidCallback onDelete;

  @override
  State<_EditLimitSheet> createState() => _EditLimitSheetState();
}

class _EditLimitSheetState extends State<_EditLimitSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _limitCtrl;
  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(
      text: widget.item.limit > 0
          ? widget.item.limit.toStringAsFixed(0)
          : '',
    );
    _expanded = widget.item.limit > 0;
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _focusNode.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = _expanded
        ? (double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0.0)
        : 0.0;
    widget.onSave(limit);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final item = widget.item;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
        color: c.surface,
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 8, AppSpacing.screenPadding, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category icon + name on left
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, size: 14, color: item.color),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                    // Close button on right
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.glassMedium,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                // Centered title
                Text(
                  'Presupuesto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 12,
                AppSpacing.screenPadding, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Limit toggle
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _expanded
                      ? Container(
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: c.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(Icons.attach_money_rounded,
                                    size: 15, color: c.textTertiary),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _limitCtrl,
                                  focusNode: _focusNode,
                                  autofocus: widget.item.limit == 0,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: c.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'ej. 200',
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: c.textTertiary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = false),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(Icons.close_rounded,
                                      size: 15,
                                      color: c.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() => _expanded = true);
                            Future.microtask(() => _focusNode.requestFocus());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 13, color: c.textTertiary),
                                const SizedBox(width: 3),
                                Text(
                                  '+ Presupuesto mensual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                // Save button
                ScaleTransition(
                  scale: _scaleCtrl,
                  child: GestureDetector(
                    onTapDown: (_) => _scaleCtrl.reverse(),
                    onTapUp: (_) {
                      _scaleCtrl.forward();
                      _submit();
                    },
                    onTapCancel: () => _scaleCtrl.forward(),
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emerald, AppColors.emeraldDim],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Delete link
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    widget.onDelete();
                    Navigator.of(context).pop();
                  },
                  child: Center(
                    child: Text(
                      'Eliminar del presupuesto',
                      style: AppTypography.labelS.copyWith(
                        color: c.textTertiary,
                        decoration: TextDecoration.underline,
                        decorationColor: c.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

// ── Add budget button ─────────────────────────────────────────────────────────

class _AddBudgetButton extends StatelessWidget {
  const _AddBudgetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorderStrong, width: 0.5),
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
              child: const Icon(Icons.add_rounded,
                  color: AppColors.emerald, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Añadir presupuesto por categoría',
                style: AppTypography.labelL.copyWith(color: AppColors.emerald)),
          ],
        ),
      ),
    );
  }
}

// ── Budget form sheet (add + edit) ────────────────────────────────────────────

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({required this.onSave});
  final void Function(BudgetItem) onSave;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _limitCtrl;
  final FocusNode _limitFocusNode = FocusNode();
  late IconData _icon;
  late Color _color;
  bool _iconGridExpanded = false;
  bool _budgetExpanded = false;
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _limitCtrl = TextEditingController();
    final idx = math.Random().nextInt(_kIconOptions.length);
    _icon = _kIconOptions[idx];
    _color = _kColorOptions[idx % _kColorOptions.length];
    _nameCtrl.addListener(() => setState(() {}));
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    _limitFocusNode.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    final limit = _budgetExpanded
        ? (double.tryParse(_limitCtrl.text.replaceAll(',', '.')) ?? 0.0)
        : 0.0;
    widget.onSave(BudgetItem(
      id: generateId(),
      name: name,
      icon: _icon,
      color: _color,
      limit: limit,
    ));
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final previewName = _nameCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
        color: c.surface,
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 8, AppSpacing.screenPadding, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.glassMedium,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Nueva categoría',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // ── Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12,
                AppSpacing.screenPadding, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // a) Vista previa
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: _color.withValues(alpha: 0.20), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_icon, size: 16, color: _color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          previewName.isEmpty
                              ? 'Nombre de categoría'
                              : previewName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: previewName.isEmpty
                                ? c.textTertiary
                                : _color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // b) Name + Icon field
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: c.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          style: TextStyle(
                              fontSize: 14, color: c.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'ej. Gimnasio, Transporte…',
                            hintStyle: TextStyle(
                                fontSize: 14, color: c.textTertiary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _iconGridExpanded = !_iconGridExpanded);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.pillRadius),
                            border: Border.all(
                                color: _color.withValues(alpha: 0.30),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icon, size: 14, color: _color),
                              const SizedBox(width: 3),
                              Icon(Icons.expand_more_rounded,
                                  size: 12,
                                  color: _color.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // c) Icon grid (animated)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _iconGridExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _kIconOptions.map((ic) {
                              final isSel = ic == _icon;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  final newIdx = _kIconOptions.indexOf(ic);
                                  setState(() {
                                    _icon = ic;
                                    _color = _kColorOptions[
                                        newIdx % _kColorOptions.length];
                                    _iconGridExpanded = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? _color.withValues(alpha: 0.18)
                                        : c.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel
                                          ? _color.withValues(alpha: 0.5)
                                          : c.glassBorder,
                                      width: isSel ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Icon(ic,
                                      size: 18,
                                      color: isSel
                                          ? _color
                                          : c.textTertiary),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.sm),
                // d) Colors (compact horizontal row — always visible)
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kColorOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final col = _kColorOptions[i];
                      final isSel = col.toARGB32() == _color.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _color = col);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                        color: col.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: -2)
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Icon(Icons.check_rounded,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // e) Budget toggle (animated)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _budgetExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: c.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(Icons.attach_money_rounded,
                                    size: 15,
                                    color: c.textTertiary),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _limitCtrl,
                                  focusNode: _limitFocusNode,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: c.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'ej. 200',
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: c.textTertiary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _budgetExpanded = false),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(Icons.close_rounded,
                                      size: 15,
                                      color: c.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              setState(() => _budgetExpanded = true),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 13, color: c.textTertiary),
                                const SizedBox(width: 3),
                                Text(
                                  '+ Presupuesto mensual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                // f) Save button
                const SizedBox(height: 8),
                ScaleTransition(
                  scale: _scaleCtrl,
                  child: GestureDetector(
                    onTapDown: (_) => _scaleCtrl.reverse(),
                    onTapUp: (_) {
                      _scaleCtrl.forward();
                      _submit();
                    },
                    onTapCancel: () => _scaleCtrl.forward(),
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emerald, AppColors.emeraldDim],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Guardar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}


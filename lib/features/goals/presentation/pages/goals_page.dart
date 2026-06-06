import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../domain/models/financial_goal.dart';
import '../providers/goals_provider.dart';
import '../../../../core/utils/id_gen.dart';
import 'goal_detail_page.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (active, completed, totalSaved) =
        ref.watch(goalsProgressSummaryProvider);
    final goals = ref.watch(goalsProvider);

    final c = context.colors;
    return Stack(
      children: [
        _GoalsBg(),
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

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mis metas',
                          style: AppTypography.headingM
                              .copyWith(color: c.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showAddGoalSheet(context, ref);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.emerald,
                                  AppColors.emeraldDim
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.pillRadius),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.emerald.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 14,
                                    color: AppColors.textInverse),
                                const SizedBox(width: 4),
                                Text(
                                  'Nueva meta',
                                  style: AppTypography.labelM.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Summary row
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Activas',
                            value: '$active',
                            icon: Icons.flag_outlined,
                            color: AppColors.petroleum,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatTile(
                            label: 'Completadas',
                            value: '$completed',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.positive,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatTile(
                            label: 'Total ahorrado',
                            value: _fmt(totalSaved),
                            icon: Icons.savings_outlined,
                            color: AppColors.catEntertainment,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (goals.isEmpty)
                      _EmptyGoals(
                          onAdd: () => _showAddGoalSheet(context, ref))
                    else ...[
                      // Active goals
                      if (goals.any((g) => !g.isCompleted)) ...[
                        Text(
                          'En progreso',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final goal
                            in goals.where((g) => !g.isCompleted)) ...[
                          _GoalCard(goal: goal),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],

                      // Completed goals
                      if (goals.any((g) => g.isCompleted)) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Completadas',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final goal
                            in goals.where((g) => g.isCompleted)) ...[
                          _GoalCard(goal: goal),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],

                      // Tip banners
                      const _TipBanner(),
                      const SizedBox(height: AppSpacing.md),
                      const _TipBanner(
                        text: '¿Cómo administrar tus metas? Preferiblemente, utiliza bolsos, carteras, cajas o algún otro recipiente donde puedas poner dinero y déjalos en un lugar donde sepas que ese dinero no lo puedes tomar — es un ahorro destinado a una meta.',
                      ),
                    ],

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

  String _fmt(double v) =>
      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toStringAsFixed(0)}';

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(
        onAdd: (goal) {
          ref.read(goalsProvider.notifier).add(goal);
        },
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends ConsumerStatefulWidget {
  const _GoalCard({required this.goal});
  final FinancialGoal goal;

  @override
  ConsumerState<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<_GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bar;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _barAnim = Tween<double>(begin: 0, end: widget.goal.progress).animate(
      CurvedAnimation(parent: _bar, curve: AppCurves.spring),
    );
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _bar.forward(); });
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.goal;
    final isComplete = g.isCompleted;
    final color = isComplete ? AppColors.emerald : g.color;
    final c = context.colors;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoalDetailPage(goalId: g.id),
          ),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isComplete ? Icons.check_rounded : g.icon,
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
                        g.title,
                        style: AppTypography.labelL.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isComplete
                            ? '¡Meta completada!'
                            : 'Plazo: ${g.deadlineLabel}',
                        style: AppTypography.labelS.copyWith(
                            color: isComplete
                                ? AppColors.emerald
                                : c.textTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  g.progressLabel,
                  style: AppTypography.headingS.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _EditGoalSheet(
                        goal: g,
                        onSave: (updated) {
                          ref.read(goalsProvider.notifier).update(updated);
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.edit_rounded,
                        size: 13, color: c.textTertiary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                width: double.infinity,
                color: color.withValues(alpha: 0.12),
                child: AnimatedBuilder(
                  animation: _barAnim,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _barAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_fmt(g.current)} ahorrados',
                  style: AppTypography.labelS
                      .copyWith(color: c.textSecondary),
                ),
                Text(
                  'Meta: ${_fmt(g.target)}',
                  style: AppTypography.labelS
                      .copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Add goal sheet ────────────────────────────────────────────────────────────

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet({required this.onAdd});
  final void Function(FinancialGoal) onAdd;

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  int _selectedIcon = 0;
  int _selectedColor = 0;

  static const _icons = [
    Icons.savings_outlined,
    Icons.flight_outlined,
    Icons.laptop_outlined,
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.school_outlined,
    Icons.favorite_outline,
    Icons.emoji_events_outlined,
  ];

  static const _colors = [
    AppColors.petroleum,
    AppColors.catShopping,
    AppColors.catTransport,
    AppColors.emerald,
    AppColors.catFood,
    AppColors.catEntertainment,
    AppColors.catHealth,
    AppColors.negative,
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final targetText = _targetCtrl.text.trim();
    if (title.isEmpty || targetText.isEmpty) return;

    final target = double.tryParse(targetText);
    if (target == null || target <= 0) return;

    final goal = FinancialGoal(
      id: generateId(),
      title: title,
      icon: _icons[_selectedIcon],
      color: _colors[_selectedColor],
      current: 0,
      target: target,
      deadline: DateTime.now().add(const Duration(days: 180)),
    );

    HapticFeedback.mediumImpact();
    widget.onAdd(goal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Nueva meta',
              style: AppTypography.headingS
                  .copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xl),

          // Title field
          _Field(
            controller: _titleCtrl,
            hint: 'Nombre de la meta',
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: AppSpacing.md),

          // Target field
          _Field(
            controller: _targetCtrl,
            hint: 'Monto objetivo (ej. 5000)',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Icon selector
          Text('Icono',
              style:
                  AppTypography.labelM.copyWith(color: c.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _icons.length,
              separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final selected = i == _selectedIcon;
                final color = _colors[_selectedColor];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _icons[i],
                      size: 20,
                      color: selected ? color : c.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Color selector
          Text('Color',
              style:
                  AppTypography.labelM.copyWith(color: c.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, i) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final selected = i == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                  'Crear meta',
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
      )),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.bodyM.copyWith(color: context.colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodyM.copyWith(color: context.colors.textTertiary),
          prefixIcon: Icon(icon, size: 18, color: context.colors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.emeraldSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.flag_outlined,
              size: 30, color: AppColors.emerald),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sin metas aún',
          style: AppTypography.headingS
              .copyWith(color: context.colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Crea tu primera meta de ahorro\ny empieza a trabajar hacia ella.',
          style: AppTypography.bodyS
              .copyWith(color: context.colors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.emeraldDim],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
            child: Text(
              'Crear primera meta',
              style: AppTypography.labelM.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────

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
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.headingS
                  .copyWith(color: context.colors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS
                  .copyWith(color: context.colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tip banner ────────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  const _TipBanner({this.text = 'Destina el 20% de tus ingresos a tus metas de ahorro cada mes.'});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.petroleumSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: AppColors.petroleum.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.petroleum.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.lightbulb_outlined,
                size: 17, color: AppColors.petroleum),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo',
                  style: AppTypography.labelL.copyWith(
                      color: AppColors.petroleumLight,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.petroleum),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit goal sheet ───────────────────────────────────────────────────────────

class _EditGoalSheet extends StatefulWidget {
  const _EditGoalSheet({required this.goal, required this.onSave});
  final FinancialGoal goal;
  final void Function(FinancialGoal) onSave;

  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late DateTime _deadline;
  late int _iconIdx;
  late int _colorIdx;

  static const _icons = [
    Icons.savings_outlined, Icons.flight_outlined, Icons.laptop_outlined,
    Icons.home_outlined, Icons.directions_car_outlined, Icons.school_outlined,
    Icons.favorite_outline, Icons.emoji_events_outlined,
  ];
  static const _colors = [
    AppColors.petroleum, AppColors.catShopping, AppColors.catTransport,
    AppColors.emerald, AppColors.catFood, AppColors.catEntertainment,
    AppColors.catHealth, AppColors.negative,
  ];

  static const _monthNames = [
    'ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleCtrl = TextEditingController(text: g.title);
    _targetCtrl = TextEditingController(text: g.target.toStringAsFixed(0));
    _currentCtrl = TextEditingController(text: g.current.toStringAsFixed(0));
    _deadline = g.deadline;
    _iconIdx = _icons.indexOf(g.icon).clamp(0, _icons.length - 1);
    _colorIdx = _colors.indexWhere((c) => c.toARGB32() == g.color.toARGB32())
        .clamp(0, _colors.length - 1);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isAfter(DateTime.now()) ? _deadline : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.emerald,
            onPrimary: Colors.white,
            surface: ctx.colors.card,
            onSurface: ctx.colors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.trim());
    final current = double.tryParse(_currentCtrl.text.trim());
    if (title.isEmpty || target == null || target <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    final safeCurrent = (current ?? widget.goal.current).clamp(0.0, target);
    final updated = widget.goal.copyWith(
      title: title,
      icon: _icons[_iconIdx],
      color: _colors[_colorIdx],
      target: target,
      current: safeCurrent,
      deadline: _deadline,
      completed: safeCurrent >= target,
    );
    HapticFeedback.mediumImpact();
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  String get _deadlineLabel {
    final d = _deadline;
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Editar meta',
                style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            // Title
            _GoalTextField(_titleCtrl, 'Nombre de la meta', Icons.label_outline_rounded),
            const SizedBox(height: AppSpacing.md),
            // Target & Current in a row
            Row(
              children: [
                Expanded(child: _GoalTextField(_targetCtrl, 'Monto objetivo', Icons.flag_outlined, numeric: true)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _GoalTextField(_currentCtrl, 'Ahorrado hasta hoy', Icons.savings_outlined, numeric: true)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Deadline picker
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: c.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Fecha límite: $_deadlineLabel',
                        style: AppTypography.bodyM
                            .copyWith(color: c.textSecondary)),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: c.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Icon selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, i2) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final sel = i == _iconIdx;
                  final col = _colors[_colorIdx];
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _iconIdx = i); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sel ? col.withValues(alpha: 0.18) : c.glass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? col.withValues(alpha: 0.5) : c.glassBorder,
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Icon(_icons[i], size: 20,
                          color: sel ? col : c.textTertiary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Color selector
            Wrap(
              spacing: AppSpacing.sm,
              children: List.generate(_colors.length, (i) {
                final sel = i == _colorIdx;
                return GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _colorIdx = i); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? Colors.white : Colors.transparent, width: 2.5),
                    ),
                    child: sel ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim]),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Text('Guardar cambios',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelL.copyWith(
                        color: AppColors.textInverse, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTextField extends StatelessWidget {
  const _GoalTextField(this.ctrl, this.hint, this.icon, {this.numeric = false});
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        style: AppTypography.bodyM.copyWith(color: context.colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(color: context.colors.textTertiary),
          prefixIcon: Icon(icon, size: 16, color: context.colors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _GoalsBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: context.colors.background),
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.10),
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

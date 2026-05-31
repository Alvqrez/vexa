import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../domain/models/financial_goal.dart';
import '../providers/goals_provider.dart';
import 'goal_detail_page.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (active, completed, totalSaved) =
        ref.watch(goalsProgressSummaryProvider);
    final goals = ref.watch(goalsProvider);

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
                              .copyWith(color: AppColors.textPrimary),
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
                            value: '\$${_fmt(totalSaved)}',
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
                                color: AppColors.textPrimary,
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
                                color: AppColors.textPrimary,
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

                      // Tip banner
                      _TipBanner(),
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
        onAdd: (goal) => ref.read(goalsProvider.notifier).add(goal),
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatefulWidget {
  const _GoalCard({required this.goal});
  final FinancialGoal goal;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard>
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
          color: AppColors.card,
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
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isComplete
                            ? '¡Meta completada!'
                            : 'Plazo: ${g.deadlineLabel}',
                        style: AppTypography.labelS.copyWith(
                            color: isComplete
                                ? AppColors.emerald
                                : AppColors.textTertiary),
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
                  '\$${_fmt(g.current)} ahorrados',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  'Meta: \$${_fmt(g.target)}',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary),
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
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
          Text('Nueva meta',
              style: AppTypography.headingS
                  .copyWith(color: AppColors.textPrimary)),
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
                  AppTypography.labelM.copyWith(color: AppColors.textTertiary)),
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
                      color: selected ? color : AppColors.textTertiary,
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
                  AppTypography.labelM.copyWith(color: AppColors.textTertiary)),
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
      ),
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
        style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
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
              .copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Crea tu primera meta de ahorro\ny empieza a trabajar hacia ella.',
          style: AppTypography.bodyS
              .copyWith(color: AppColors.textTertiary),
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
          color: AppColors.card,
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
                  .copyWith(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tip banner ────────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
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
                  'Destina el 20% de tus ingresos a tus metas de ahorro cada mes.',
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

// ── Background ────────────────────────────────────────────────────────────────

class _GoalsBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
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

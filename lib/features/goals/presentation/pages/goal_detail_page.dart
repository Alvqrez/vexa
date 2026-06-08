import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/confetti_overlay.dart';
import '../../domain/models/financial_goal.dart';
import '../providers/goals_provider.dart';

class GoalDetailPage extends ConsumerStatefulWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _arcAnim = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _arcCtrl.forward();
    });
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    super.dispose();
  }

  void _showAddProgress(FinancialGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProgressSheet(
        goal: goal,
        onAdd: (amount) async {
          await ref.read(goalsProvider.notifier).addProgress(goal.id, amount);
          final newProgress = (goal.current + amount) / goal.target;
          if (newProgress >= 1.0 && !goal.completed) {
            HapticFeedback.heavyImpact();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ConfettiOverlay.show(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Meta cumplida! 🎉',
                    style: AppTypography.labelM
                        .copyWith(color: context.colors.textPrimary),
                  ),
                  backgroundColor: context.colors.card,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              );
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    if (goals.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) Navigator.of(context).pop(); });
      return const SizedBox.shrink();
    }
    final goal = goals.firstWhere(
      (g) => g.id == widget.goalId,
      orElse: () => goals.first,
    );
    final color = goal.isCompleted ? AppColors.emerald : goal.color;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
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
                    color.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Back button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 18, color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Icon + title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                goal.isCompleted
                                    ? Icons.check_rounded
                                    : goal.icon,
                                size: 34,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              goal.title,
                              style: AppTypography.headingM
                                  .copyWith(color: c.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (goal.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.pillRadius),
                                ),
                                child: Text(
                                  '¡Meta completada!',
                                  style: AppTypography.labelM.copyWith(
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'Plazo: ${goal.deadlineLabel}',
                                style: AppTypography.labelM
                                    .copyWith(color: c.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Arc gauge
                      Center(
                        child: AnimatedBuilder(
                          animation: _arcAnim,
                          builder: (_, child) => SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: _GoalArcPainter(
                                progress: goal.progress * _arcAnim.value,
                                color: color,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(goal.progress * 100 * _arcAnim.value).toStringAsFixed(0)}%',
                                      style: AppTypography.headingM.copyWith(
                                        color: color,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'completado',
                                      style: AppTypography.labelS.copyWith(
                                          color: c.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Ahorrado',
                              value: '\$${_fmt(goal.current)}',
                              color: color,
                              icon: Icons.savings_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Objetivo',
                              value: '\$${_fmt(goal.target)}',
                              color: c.textSecondary,
                              icon: Icons.flag_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: goal.daysLeft >= 0 ? 'Días restantes' : 'Días pasados',
                              value: '${goal.daysLeft.abs()}',
                              color: goal.daysLeft < 30
                                  ? AppColors.warning
                                  : AppColors.petroleum,
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Remaining amount
                      if (!goal.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: c.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Falta por ahorrar',
                                style: AppTypography.bodyM
                                    .copyWith(color: c.textSecondary),
                              ),
                              Text(
                                '\$${_fmt(goal.target - goal.current)}',
                                style: AppTypography.headingS.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Note
                      if (goal.note != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.petroleumSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.petroleum
                                    .withValues(alpha: 0.20),
                                width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded,
                                  size: 16, color: AppColors.petroleum),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  goal.note!,
                                  style: AppTypography.bodyS
                                      .copyWith(color: AppColors.petroleum),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Add progress button
                      if (!goal.isCompleted)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showAddProgress(goal);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.75)],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.28),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 18, color: AppColors.textInverse),
                                const SizedBox(width: 6),
                                Text(
                                  'Añadir progreso',
                                  style: AppTypography.labelL.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 60),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Arc painter ───────────────────────────────────────────────────────────────

class _GoalArcPainter extends CustomPainter {
  const _GoalArcPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress.clamp(0.0, 1.0),
          colors: [color.withValues(alpha: 0.6), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GoalArcPainter old) => old.progress != progress;
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headingS.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  AppTypography.labelS.copyWith(color: context.colors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Add progress sheet ────────────────────────────────────────────────────────

class _AddProgressSheet extends StatefulWidget {
  const _AddProgressSheet({required this.goal, required this.onAdd});

  final FinancialGoal goal;
  final Future<void> Function(double) onAdd;

  @override
  State<_AddProgressSheet> createState() => _AddProgressSheetState();
}

class _AddProgressSheetState extends State<_AddProgressSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    HapticFeedback.mediumImpact();
    await widget.onAdd(amount);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.goal.color;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
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
          Text('Añadir progreso',
              style: AppTypography.headingS
                  .copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(
            '${widget.goal.title} · \$${(widget.goal.target - widget.goal.current).toStringAsFixed(0)} restantes',
            style: AppTypography.labelM.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), width: 0.5),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.bodyM.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Monto a agregar',
                hintStyle: AppTypography.bodyM
                    .copyWith(color: c.textTertiary),
                prefixIcon: Icon(Icons.attach_money_rounded,
                    size: 18, color: c.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Guardar',
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

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/numeric_keypad.dart';
import '../../../../shared/widgets/drag_handle.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../domain/models/loan.dart';
import '../providers/loans_provider.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  static const _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..revealForward();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final seen = await LocalPrefsService.getBool('loans_onboarding_seen');
    if (!seen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.7),
          builder: (_) => const _LoansOnboardingDialog(),
        );
        LocalPrefsService.setBool('loans_onboarding_seen', true);
      });
    }
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

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LoanFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          const _LoansBg(),
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
                      _reveal(0, _LoansHeader(onAdd: _showAddSheet)),
                      const SizedBox(height: AppSpacing.xxl),
                      _reveal(1, const _LoansSummaryCard()),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(2, const _LoansSection(type: LoanType.lentByMe)),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(
                          3, const _LoansSection(type: LoanType.borrowedByMe)),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(4, const _SettledLoansSection()),
                      const SizedBox(height: AppSpacing.xxxl),
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
}

// ── Background ────────────────────────────────────────────────────────────────

class _LoansBg extends StatelessWidget {
  const _LoansBg();

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
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 360,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.warning.withValues(alpha: 0.06),
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

class _LoansHeader extends StatelessWidget {
  const _LoansHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 18, color: c.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préstamos',
                  style: AppTypography.headingM
                      .copyWith(color: c.textPrimary)),
              Text('Yo presté / Pedí prestado',
                  style: AppTypography.labelM
                      .copyWith(color: c.textTertiary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Haptics.selectionClick();
            onAdd();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  width: 0.5),
            ),
            child: const Icon(Icons.add_rounded,
                size: 18, color: Color(0xFF6366F1)),
          ),
        ),
      ],
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _LoansSummaryCard extends ConsumerStatefulWidget {
  const _LoansSummaryCard();

  @override
  ConsumerState<_LoansSummaryCard> createState() => _LoansSummaryCardState();
}

class _LoansSummaryCardState extends ConsumerState<_LoansSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arc;
  late Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _arc = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _arcAnim = CurvedAnimation(parent: _arc, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 300), () {
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
    final totalLent = ref.watch(totalLentProvider);
    final totalBorrowed = ref.watch(totalBorrowedProvider);
    final lentCount = ref.watch(lentByMeProvider).length;
    final borrowedCount = ref.watch(borrowedByMeProvider).length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: context.colors.glass,
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          color: context.colors.cardElevated,
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _arcAnim,
              builder: (context, _) => SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _LoansArcPainter(
                    lent: totalLent,
                    borrowed: totalBorrowed,
                    progress: _arcAnim.value,
                    trackColor: context.colors.glassMedium,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${(totalLent - totalBorrowed).abs().toStringAsFixed(0)}',
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          totalLent >= totalBorrowed ? 'a cobrar' : 'a pagar',
                          style: AppTypography.eyebrow
                              .copyWith(color: c.textTertiary),
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
                  _LoanInfoRow(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Yo presté',
                    value: pmask('\$${totalLent.toStringAsFixed(2)}'),
                    color: AppColors.positive,
                    count: lentCount,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LoanInfoRow(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Pedí prestado',
                    value: pmask('\$${totalBorrowed.toStringAsFixed(2)}'),
                    color: AppColors.negative,
                    count: borrowedCount,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LoanInfoRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Balance neto',
                    value:
                        pmask('${totalLent >= totalBorrowed ? '+' : '-'}\$${(totalLent - totalBorrowed).abs().toStringAsFixed(2)}'),
                    color: totalLent >= totalBorrowed
                        ? AppColors.positive
                        : AppColors.negative,
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

class _LoanInfoRow extends StatelessWidget {
  const _LoanInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.count,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int? count;

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
          child: Text(label,
              style:
                  AppTypography.labelM.copyWith(color: c.textSecondary)),
        ),
        if (count != null) ...[
          Text('$count',
              style: AppTypography.labelS
                  .copyWith(color: c.textTertiary)),
          const SizedBox(width: 6),
        ],
        Text(value,
            style: AppTypography.labelL
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LoansArcPainter extends CustomPainter {
  const _LoansArcPainter({
    required this.lent,
    required this.borrowed,
    required this.progress,
    required this.trackColor,
  });
  final double lent;
  final double borrowed;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2;
    const sweepAngle = math.pi * 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    final total = lent + borrowed;
    if (total <= 0) return;

    final lentFraction = lent / total;

    // green arc for lent
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * lentFraction * progress,
      false,
      Paint()
        ..color = AppColors.positive
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // red arc for borrowed
    if (borrowed > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepAngle * lentFraction,
        sweepAngle * (1 - lentFraction) * progress,
        false,
        Paint()
          ..color = AppColors.negative
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LoansArcPainter old) =>
      old.progress != progress || old.lent != lent || old.borrowed != borrowed ||
      old.trackColor != trackColor;
}

// ── Loans section ─────────────────────────────────────────────────────────────

class _LoansSection extends ConsumerWidget {
  const _LoansSection({required this.type});
  final LoanType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final loans = type == LoanType.lentByMe
        ? ref.watch(lentByMeProvider)
        : ref.watch(borrowedByMeProvider);

    final accentColor =
        type == LoanType.lentByMe ? AppColors.positive : AppColors.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: AppTypography.headingS.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${loans.length}',
              style: AppTypography.labelS.copyWith(color: c.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (loans.isEmpty)
          _EmptyState(
            message: type == LoanType.lentByMe
                ? 'Ningún préstamo activo que hayas hecho'
                : 'No tienes deudas activas',
          )
        else
          ...loans.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _LoanCard(loan: l),
              )),
      ],
    );
  }
}

// ── Settled section ───────────────────────────────────────────────────────────

class _SettledLoansSection extends ConsumerWidget {
  const _SettledLoansSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settled = ref.watch(settledLoansProvider);
    if (settled.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saldados',
                style: AppTypography.headingS.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                )),
            Text('${settled.length} total',
                style: AppTypography.labelS
                    .copyWith(color: c.textTertiary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...settled.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LoanCard(loan: l, settled: true),
            )),
      ],
    );
  }
}

// ── Loan card ─────────────────────────────────────────────────────────────────

class _LoanCard extends ConsumerWidget {
  const _LoanCard({required this.loan, this.settled = false});
  final Loan loan;
  final bool settled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = loan;
    final isLent = l.type == LoanType.lentByMe;
    final accentColor = settled
        ? c.textTertiary
        : isLent
            ? AppColors.positive
            : AppColors.negative;

    String? dateLabel;
    if (l.dueDate != null) {
      if (l.isOverdue && !settled) {
        final days = DateTime.now().difference(l.dueDate!).inDays;
        dateLabel = 'Vencido hace $days día${days == 1 ? '' : 's'}';
      } else if (l.isDueSoon && !settled) {
        final days = l.dueDate!.difference(DateTime.now()).inDays;
        dateLabel = days == 0 ? 'Vence hoy' : 'Vence en ${days}d';
      } else {
        dateLabel = DateFormat('d MMM yyyy', 'es').format(l.dueDate!);
      }
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: l.isOverdue && !settled
            ? AppColors.negative.withValues(alpha: 0.04)
            : l.isDueSoon && !settled
                ? AppColors.warning.withValues(alpha: 0.04)
                : c.glass,
        border: Border.all(
          color: l.isOverdue && !settled
              ? AppColors.negative.withValues(alpha: 0.18)
              : l.isDueSoon && !settled
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: l.color.withValues(alpha: settled ? 0.08 : 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(l.icon,
                      size: 20,
                      color: settled
                          ? l.color.withValues(alpha: 0.5)
                          : l.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name,
                          style: AppTypography.labelL
                              .copyWith(color: c.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              settled ? 'Saldado' : l.type.label,
                              style: AppTypography.eyebrow
                                  .copyWith(color: accentColor),
                            ),
                          ),
                          if (dateLabel != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: c.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: AppTypography.labelS.copyWith(
                                color: l.isOverdue && !settled
                                    ? AppColors.negative
                                    : l.isDueSoon && !settled
                                        ? AppColors.warning
                                        : c.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pmask('\$${l.remainingAmount.toStringAsFixed(2)}'),
                      style: AppTypography.labelL.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      pmask('de \$${l.amount.toStringAsFixed(2)}'),
                      style: AppTypography.labelS
                          .copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                _LoanMenu(loan: l),
              ],
            ),
            if (!settled && l.paidAmount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              _ProgressBar(
                  progress: l.progressFraction, color: accentColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ── Loan menu (3-dot) ─────────────────────────────────────────────────────────

class _LoanMenu extends ConsumerWidget {
  const _LoanMenu({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _LoanActionSheet(
            loan: loan,
            onEdit: () {
              Navigator.pop(context);
              if (!context.mounted) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _LoanFormSheet(existing: loan),
              );
            },
            onPay: () {
              Navigator.pop(context);
              if (!context.mounted) return;
              if (!loan.isSettled) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _PaymentSheet(loan: loan),
                );
              }
            },
            onDelete: () async {
              final messenger = ScaffoldMessenger.of(context);
              final c = context.colors;
              await ref.read(loansProvider.notifier).delete(loan.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '"${loan.name}" eliminado',
                    style: AppTypography.labelM.copyWith(color: c.textPrimary),
                  ),
                  backgroundColor: c.card,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              );
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
        child: Icon(Icons.more_vert_rounded,
            size: 14, color: c.textSecondary),
      ),
    );
  }
}

// ── Loan action sheet ─────────────────────────────────────────────────────────

class _LoanActionSheet extends StatelessWidget {
  const _LoanActionSheet({
    required this.loan,
    required this.onEdit,
    required this.onPay,
    required this.onDelete,
  });
  final Loan loan;
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: loan.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(loan.icon, size: 22, color: loan.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loan.name,
                      style: AppTypography.headingS
                          .copyWith(color: c.textPrimary)),
                  Text(
                      '${loan.type.label} · \$${loan.remainingAmount.toStringAsFixed(2)} pendiente',
                      style: AppTypography.labelM
                          .copyWith(color: c.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _ActionTile(
            icon: Icons.edit_rounded,
            label: 'Editar préstamo',
            color: const Color(0xFF6366F1),
            onTap: onEdit,
          ),
          if (!loan.isSettled) ...[
            const SizedBox(height: AppSpacing.sm),
            _ActionTile(
              icon: Icons.payments_rounded,
              label: loan.type.actionLabel,
              color: AppColors.emerald,
              onTap: onPay,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar préstamo',
            color: AppColors.negative,
            onTap: () {
              onDelete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border:
              Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.labelL.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Payment sheet ─────────────────────────────────────────────────────────────

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.loan});
  final Loan loan;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _amountCtrl = TextEditingController();
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.loan.accountId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      Haptics.heavyImpact();
      return;
    }
    final clamped = amount.clamp(0.0, widget.loan.remainingAmount);
    await ref
        .read(loansProvider.notifier)
        .addPayment(widget.loan.id, clamped, accountId: _accountId);
    Haptics.mediumImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final l = widget.loan;
    final isLent = l.type == LoanType.lentByMe;
    final accentColor = isLent ? AppColors.positive : AppColors.negative;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(l.type.actionLabel,
              style:
                  AppTypography.headingS.copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(
            '${l.name} · pendiente \$${l.remainingAmount.toStringAsFixed(2)}',
            style: AppTypography.labelM.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Monto abonado',
              style: AppTypography.labelM.copyWith(color: c.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style:
                  AppTypography.bodyM.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'ej. ${l.remainingAmount.toStringAsFixed(2)}',
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
          const SizedBox(height: AppSpacing.lg),
          _AccountPicker(
            selectedId: _accountId,
            onChanged: (id) => setState(() => _accountId = id),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              Haptics.selectionClick();
              _amountCtrl.text =
                  l.remainingAmount.toStringAsFixed(2);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Text(
                'Saldar completo (\$${l.remainingAmount.toStringAsFixed(2)})',
                style: AppTypography.labelS.copyWith(color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Confirmar abono',
                  style: AppTypography.labelL.copyWith(
                    color: Colors.white,
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

// ── Loan form sheet (add/edit) ────────────────────────────────────────────────

class _LoanFormSheet extends ConsumerStatefulWidget {
  const _LoanFormSheet({this.existing});
  final Loan? existing;

  @override
  ConsumerState<_LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<_LoanFormSheet> {
  late final TextEditingController _nameCtrl;
  late final ValueNotifier<String> _amountNotifier;
  late LoanType _type;
  late IconData _icon;
  late Color _color;
  DateTime? _dueDate;
  String? _accountId;

  static const _iconOptions = [
    Icons.person_rounded,
    Icons.people_rounded,
    Icons.handshake_rounded,
    Icons.family_restroom_rounded,
    Icons.work_rounded,
    Icons.school_rounded,
    Icons.favorite_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.attach_money_rounded,
    Icons.currency_exchange_rounded,
  ];

  static const _colorOptions = [
    Color(0xFF6366F1),
    AppColors.emerald,
    AppColors.petroleum,
    AppColors.positive,
    AppColors.negative,
    AppColors.warning,
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    AppColors.catFood,
    AppColors.catShopping,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountNotifier =
        ValueNotifier<String>(e != null ? e.amount.toStringAsFixed(2) : '');
    _type = e?.type ?? LoanType.lentByMe;
    _icon = e?.icon ?? _iconOptions.first;
    _color = e?.color ?? _colorOptions.first;
    _dueDate = e?.dueDate;
    _accountId = e?.accountId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountNotifier.dispose();
    super.dispose();
  }

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountNotifier.value);
    if (name.isEmpty || amount == null || amount <= 0) {
      Haptics.heavyImpact();
      return;
    }

    if (widget.existing != null) {
      await ref.read(loansProvider.notifier).update(
            widget.existing!.copyWith(
              name: name,
              amount: amount,
              type: _type,
              icon: _icon,
              color: _color,
              accountId: _accountId,
              dueDate: _dueDate,
              clearDueDate: _dueDate == null,
            ),
          );
    } else {
      await ref.read(loansProvider.notifier).add(Loan(
            id: generateId(),
            name: name,
            amount: amount,
            paidAmount: 0,
            type: _type,
            date: DateTime.now(),
            icon: _icon,
            color: _color,
            accountId: _accountId,
            dueDate: _dueDate,
          ));
    }

    Haptics.mediumImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showIconSheet() {
    Haptics.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 12),
              child: Text('Ícono',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (_, i) {
                  final ic = _iconOptions[i];
                  final sel = ic == _icon;
                  return GestureDetector(
                    onTap: () {
                      Haptics.selectionClick();
                      setState(() => _icon = ic);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: sel ? _color.withValues(alpha: 0.18) : c.glass,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? _color.withValues(alpha: 0.5)
                              : c.glassBorder,
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Icon(ic,
                          size: 22, color: sel ? _color : c.textTertiary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showColorSheet() {
    Haptics.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 12),
              child: Text('Color',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((col) {
                  final sel = col.toARGB32() == _color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      Haptics.selectionClick();
                      setState(() => _color = col);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              sel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: col.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: -2)
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;
    final typeColor =
        _type == LoanType.lentByMe ? AppColors.positive : AppColors.negative;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Text(isEdit ? 'Editar préstamo' : 'Nuevo préstamo',
                style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: 12),

            // Tipo (Yo presté / Pedí prestado)
            Row(
              children: LoanType.values.map((t) {
                final active = t == _type;
                final tColor = t == LoanType.lentByMe
                    ? AppColors.positive
                    : AppColors.negative;
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: t == LoanType.lentByMe ? 6 : 0),
                    child: GestureDetector(
                      onTap: () {
                        Haptics.selectionClick();
                        setState(() => _type = t);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? tColor.withValues(alpha: 0.12)
                              : c.glass,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                            color: active
                                ? tColor.withValues(alpha: 0.4)
                                : c.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t == LoanType.lentByMe
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: active ? tColor : c.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(t.label,
                                style: AppTypography.labelM.copyWith(
                                  color: active ? tColor : c.textTertiary,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Nombre con ícono (izq, toca → selector) + color (der, toca → selector)
            Container(
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: c.glassBorder, width: 0.5),
              ),
              child: TextField(
                controller: _nameCtrl,
                autofocus: !isEdit,
                style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ej. Juan, María…',
                  hintStyle:
                      AppTypography.bodyM.copyWith(color: c.textTertiary),
                  prefixIcon: GestureDetector(
                    onTap: _showIconSheet,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_icon, size: 16, color: _color),
                      ),
                    ),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  suffixIcon: GestureDetector(
                    onTap: _showColorSheet,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: _color.withValues(alpha: 0.4),
                                blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips izquierda + Monto derecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LoanChip(
                      icon: Icons.calendar_today_rounded,
                      label: _dueDate != null
                          ? _formatDate(_dueDate!)
                          : 'Sin fecha límite',
                      color: _dueDate != null ? c.textPrimary : c.textTertiary,
                      surface: c.glass,
                      onTap: () async {
                        Haptics.selectionClick();
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _dueDate ?? now.add(const Duration(days: 30)),
                          firstDate: now,
                          lastDate: DateTime(now.year + 10),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: const Color(0xFF6366F1),
                                onPrimary: Colors.white,
                                surface: ctx.colors.card,
                                onSurface: ctx.colors.textPrimary,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      trailing: _dueDate != null
                          ? GestureDetector(
                              onTap: () => setState(() => _dueDate = null),
                              child: Icon(Icons.close_rounded,
                                  size: 12, color: c.textTertiary),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _LoanChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: account?.name ?? 'Sin cuenta',
                      color: account?.color ?? c.textTertiary,
                      surface: (account?.color ?? c.textTertiary)
                          .withValues(alpha: 0.10),
                      onTap: () => _openAccountSheet(accounts),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _amountNotifier,
                    builder: (_, amountStr, _) {
                      final split = splitAmount(amountStr);
                      return Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(currency,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: typeColor.withValues(alpha: 0.65),
                                      height: 1,
                                    )),
                              ),
                              const SizedBox(width: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(split.integer,
                                      style: TextStyle(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w800,
                                        color: typeColor,
                                        letterSpacing: -1.5,
                                        height: 1,
                                      )),
                                  Text(split.decimal,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            typeColor.withValues(alpha: 0.45),
                                        letterSpacing: -0.5,
                                        height: 1,
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Teclado numérico
            ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, amountStr, _) => NumericKeypad(
                value: amountStr,
                onValueChanged: (v) => _amountNotifier.value = v,
                onConfirm: _submit,
                confirmColor: const Color(0xFF6366F1),
                currencySymbol: currency,
                keyHeight: 44,
                confirmHeight: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAccountSheet(List<dynamic> accounts) {
    Haptics.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            top: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Text('Cuenta',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                setState(() => _accountId = null);
                Navigator.pop(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding, vertical: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: _accountId == null
                      ? c.textTertiary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 18, color: c.textTertiary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Sin cuenta',
                            style: AppTypography.labelL
                                .copyWith(color: c.textPrimary))),
                    if (_accountId == null)
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: c.textTertiary),
                  ],
                ),
              ),
            ),
            ...accounts.map((a) {
              final sel = a.id == _accountId;
              return GestureDetector(
                onTap: () {
                  setState(() => _accountId = a.id);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: sel
                        ? (a.color as Color).withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: sel
                          ? (a.color as Color).withValues(alpha: 0.30)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          size: 18, color: a.color as Color),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(a.name as String,
                              style: AppTypography.labelL
                                  .copyWith(color: c.textPrimary))),
                      if (sel)
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: a.color as Color),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Compact chip para la fila de metadatos ────────────────────────────────────

class _LoanChip extends StatelessWidget {
  const _LoanChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ] else ...[
              const SizedBox(width: 3),
              Icon(Icons.expand_more_rounded,
                  size: 13, color: color.withValues(alpha: 0.70)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Onboarding dialog ─────────────────────────────────────────────────────────

class _LoansOnboardingDialog extends StatelessWidget {
  const _LoansOnboardingDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          border: Border.all(color: c.glassBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    width: 1),
              ),
              child: const Icon(Icons.handshake_rounded,
                  size: 28, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Cómo funcionan los préstamos',
                style: AppTypography.headingS
                    .copyWith(color: c.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            _OnboardingRow(
              icon: Icons.arrow_upward_rounded,
              color: AppColors.positive,
              title: 'Yo presté',
              description:
                  'Al registrarlo se descuenta de tu cuenta. Al abonar o saldar, el dinero regresa.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _OnboardingRow(
              icon: Icons.arrow_downward_rounded,
              color: AppColors.negative,
              title: 'Pedí prestado',
              description:
                  'Al registrarlo el dinero entra a tu cuenta. Al abonar o saldar, se descuenta.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _OnboardingRow(
              icon: Icons.payments_rounded,
              color: AppColors.petroleum,
              title: 'Abonos parciales',
              description:
                  'Puedes registrar pagos parciales; la barra de progreso muestra cuánto falta.',
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Haptics.mediumImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8183F4)],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text('Entendido',
                      style: AppTypography.labelL.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingRow extends StatelessWidget {
  const _OnboardingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.labelL.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(description,
                  style: AppTypography.labelM
                      .copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Account picker widget ─────────────────────────────────────────────────────

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({
    required this.selectedId,
    required this.onChanged,
  });
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider);
    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuenta',
            style:
                AppTypography.labelM.copyWith(color: c.textTertiary)),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AccountChip(
                label: 'Sin cuenta',
                color: c.textTertiary,
                isSelected: selectedId == null,
                onTap: () => onChanged(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...accounts.map((a) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _AccountChip(
                      label: a.name,
                      color: a.color,
                      isSelected: selectedId == a.id,
                      onTap: () => onChanged(a.id),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : c.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelM.copyWith(
                  color: isSelected ? color : c.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Center(
        child: Text(message,
            style:
                AppTypography.labelM.copyWith(color: c.textTertiary),
            textAlign: TextAlign.center),
      ),
    );
  }
}

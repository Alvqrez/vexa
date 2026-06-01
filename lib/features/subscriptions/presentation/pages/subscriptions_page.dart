import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../domain/models/subscription.dart';
import '../providers/subscriptions_provider.dart';
import '../../../home/domain/models/transaction.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage>
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
        position: Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSubscriptionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _SubsBg(),
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
                      _reveal(0, _SubsHeader(onAdd: () => _showAddSheet(context))),
                      const SizedBox(height: AppSpacing.xxl),
                      _reveal(1, const _MonthlyTotalCard()),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(2, const _UpcomingSection()),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(3, const _AllSubscriptionsSection()),
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

class _SubsBg extends StatelessWidget {
  const _SubsBg();

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
              width: 280,
              height: 280,
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
          Positioned(
            top: 360,
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

class _SubsHeader extends StatelessWidget {
  const _SubsHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
              Text('Suscripciones',
                  style: AppTypography.headingM
                      .copyWith(color: AppColors.textPrimary)),
              Text('Pagos recurrentes',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onAdd();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.emeraldSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3), width: 0.5),
            ),
            child: const Icon(Icons.add_rounded,
                size: 18, color: AppColors.emerald),
          ),
        ),
      ],
    );
  }
}

// ── Monthly total card ────────────────────────────────────────────────────────

class _MonthlyTotalCard extends ConsumerStatefulWidget {
  const _MonthlyTotalCard();

  @override
  ConsumerState<_MonthlyTotalCard> createState() => _MonthlyTotalCardState();
}

class _MonthlyTotalCardState extends ConsumerState<_MonthlyTotalCard>
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
    final total = ref.watch(monthlySubscriptionsTotalProvider);
    final all = ref.watch(activeSubscriptionsProvider);
    final dueSoon = ref.watch(subscriptionsDueSoonProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: Colors.white.withValues(alpha: 0.03),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
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
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _arcAnim,
              builder: (context, child) => SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _SubsArcPainter(progress: _arcAnim.value),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${total.toStringAsFixed(0)}',
                          style: AppTypography.headingS.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '/mes',
                          style: AppTypography.eyebrow
                              .copyWith(color: AppColors.textTertiary),
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
                  _SubsInfoRow(
                    icon: Icons.subscriptions_rounded,
                    label: 'Activas',
                    value: '${all.length}',
                    color: AppColors.petroleum,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SubsInfoRow(
                    icon: Icons.notifications_active_rounded,
                    label: 'Próximos 7 días',
                    value: '${dueSoon.length}',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SubsInfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Costo anual',
                    value: '\$${(total * 12).toStringAsFixed(0)}',
                    color: AppColors.negative,
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

class _SubsInfoRow extends StatelessWidget {
  const _SubsInfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
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
          child: Text(label,
              style:
                  AppTypography.labelM.copyWith(color: AppColors.textSecondary)),
        ),
        Text(value,
            style: AppTypography.labelL.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SubsArcPainter extends CustomPainter {
  const _SubsArcPainter({required this.progress});
  final double progress;

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
        ..color = AppColors.glassMedium
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            AppColors.petroleum.withValues(alpha: 0.7),
            AppColors.emerald,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SubsArcPainter old) => old.progress != progress;
}

// ── Upcoming section ──────────────────────────────────────────────────────────

class _UpcomingSection extends ConsumerWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSubscriptionsProvider).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximos pagos',
            style: AppTypography.headingS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            )),
        const SizedBox(height: AppSpacing.md),
        if (upcoming.isEmpty)
          _EmptyState(
              message: 'No hay pagos próximos en los siguientes 30 días')
        else
          ...upcoming.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SubscriptionCard(subscription: s),
              )),
      ],
    );
  }
}

// ── All subscriptions ─────────────────────────────────────────────────────────

class _AllSubscriptionsSection extends ConsumerWidget {
  const _AllSubscriptionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(subscriptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Todas las suscripciones',
                style: AppTypography.headingS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                )),
            Text('${all.length} total',
                style: AppTypography.labelS
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (all.isEmpty)
          _EmptyState(message: 'Sin suscripciones aún. Agrega la primera.')
        else
          ...all.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SubscriptionCard(subscription: s, showControls: true),
              )),
      ],
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({required this.subscription, this.showControls = false});
  final Subscription subscription;
  final bool showControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final daysLeft = s.daysUntilBilling;
    final dateStr = DateFormat('d MMM', 'es').format(s.nextBillingDate);

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: s.isDueSoon
            ? AppColors.warning.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: s.isDueSoon
              ? AppColors.warning.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(s.icon, size: 20, color: s.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: AppTypography.labelL
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(s.frequency.label,
                          style: AppTypography.labelS
                              .copyWith(color: AppColors.textTertiary)),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        daysLeft == 0
                            ? 'Hoy'
                            : daysLeft == 1
                                ? 'Mañana'
                                : '$dateStr ($daysLeft días)',
                        style: AppTypography.labelS.copyWith(
                          color: s.isDueSoon
                              ? AppColors.warning
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${s.amount.toStringAsFixed(2)}',
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.negative,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(s.frequency.shortLabel,
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
            if (showControls) ...[
              const SizedBox(width: AppSpacing.sm),
              _SubscriptionMenu(subscription: s),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionMenu extends ConsumerWidget {
  const _SubscriptionMenu({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SubsActionSheet(
            subscription: subscription,
            onEdit: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _EditSubscriptionSheet(
                  subscription: subscription,
                  onSave: (updated) =>
                      ref.read(subscriptionsProvider.notifier).update(updated),
                ),
              );
            },
            onToggle: () =>
                ref.read(subscriptionsProvider.notifier).toggleActive(subscription.id),
            onDelete: () =>
                ref.read(subscriptionsProvider.notifier).delete(subscription.id),
            onCharge: () => ref
                .read(subscriptionsProvider.notifier)
                .chargeSubscription(subscription),
          ),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.more_vert_rounded,
            size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Subscription action sheet ─────────────────────────────────────────────────

class _SubsActionSheet extends StatelessWidget {
  const _SubsActionSheet({
    required this.subscription,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onCharge,
  });
  final Subscription subscription;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onCharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
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
                color: AppColors.textTertiary.withValues(alpha: 0.4),
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
                  color: subscription.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(subscription.icon,
                    size: 22, color: subscription.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.name,
                      style: AppTypography.headingS
                          .copyWith(color: AppColors.textPrimary)),
                  Text(
                      '\$${subscription.amount.toStringAsFixed(2)}${subscription.frequency.shortLabel}',
                      style: AppTypography.labelM
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _ActionTile(
            icon: Icons.edit_rounded,
            label: 'Editar suscripción',
            color: AppColors.petroleum,
            onTap: onEdit,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.payment_rounded,
            label: 'Registrar pago ahora',
            color: AppColors.emerald,
            onTap: () {
              onCharge();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: subscription.isActive
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            label: subscription.isActive ? 'Pausar suscripción' : 'Activar suscripción',
            color: AppColors.warning,
            onTap: () {
              onToggle();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar suscripción',
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
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
              color: color.withValues(alpha: 0.15), width: 0.5),
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
            Text(label,
                style: AppTypography.labelL.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Add subscription sheet ─────────────────────────────────────────────────────

class _AddSubscriptionSheet extends ConsumerStatefulWidget {
  const _AddSubscriptionSheet();

  @override
  ConsumerState<_AddSubscriptionSheet> createState() =>
      _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<_AddSubscriptionSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  SubscriptionFrequency _freq = SubscriptionFrequency.monthly;
  final TransactionCategory _cat = TransactionCategory.entertainment;
  Color _color = const Color(0xFF6366F1);
  IconData _icon = Icons.subscriptions_rounded;
  final DateTime _billingDate = DateTime.now().add(const Duration(days: 30));

  static const _iconOptions = [
    Icons.play_circle_rounded,
    Icons.music_note_rounded,
    Icons.smart_toy_rounded,
    Icons.ondemand_video_rounded,
    Icons.local_shipping_rounded,
    Icons.cloud_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.games_rounded,
    Icons.subscriptions_rounded,
  ];

  static const _colorOptions = [
    Color(0xFFE50914),
    Color(0xFF1DB954),
    Color(0xFF10A37F),
    Color(0xFFFF0000),
    Color(0xFFFF9900),
    Color(0xFF6366F1),
    AppColors.emerald,
    AppColors.petroleum,
    AppColors.catFood,
    AppColors.catShopping,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    ref.read(subscriptionsProvider.notifier).add(Subscription(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          amount: amount,
          nextBillingDate: _billingDate,
          category: _cat,
          icon: _icon,
          color: _color,
          frequency: _freq,
        ));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
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
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Nueva suscripción',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxl),
            _SheetLabel('Nombre'),
            const SizedBox(height: AppSpacing.sm),
            _SheetTextField(
                controller: _nameCtrl,
                hint: 'ej. Netflix, Spotify…',
                icon: Icons.label_outline_rounded,
                autofocus: true),
            const SizedBox(height: AppSpacing.xl),
            _SheetLabel('Monto'),
            const SizedBox(height: AppSpacing.sm),
            _SheetTextField(
                controller: _amountCtrl,
                hint: 'ej. 9.99',
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: AppSpacing.xl),
            _SheetLabel('Frecuencia'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: SubscriptionFrequency.values.map((f) {
                final active = f == _freq;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _freq = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.emeraldSurface
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: active
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(f.label,
                        style: AppTypography.labelM.copyWith(
                          color: active
                              ? AppColors.emerald
                              : AppColors.textTertiary,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SheetLabel('Icono'),
            const SizedBox(height: AppSpacing.sm),
            _IconPicker(
                icons: _iconOptions,
                selected: _icon,
                color: _color,
                onChanged: (ic) => setState(() => _icon = ic)),
            const SizedBox(height: AppSpacing.xl),
            _SheetLabel('Color'),
            const SizedBox(height: AppSpacing.sm),
            _ColorPicker(
                colors: _colorOptions,
                selected: _color,
                onChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDim]),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text('Agregar suscripción',
                      style: AppTypography.labelL.copyWith(
                        color: AppColors.textInverse,
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

// ── Sheet shared widgets ──────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.labelM.copyWith(color: AppColors.textTertiary));
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool autofocus;

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
        autofocus: autofocus,
        style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
          prefixIcon:
              Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker(
      {required this.icons,
      required this.selected,
      required this.color,
      required this.onChanged});
  final List<IconData> icons;
  final IconData selected;
  final Color color;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: icons.map((ic) {
        final isSel = ic == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(ic);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSel
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSel
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Icon(ic,
                size: 20, color: isSel ? color : AppColors.textTertiary),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker(
      {required this.colors,
      required this.selected,
      required this.onChanged});
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: colors.map((c) {
        final isSel = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSel ? Colors.white : Colors.transparent, width: 2.5),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                          color: c.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: -2)
                    ]
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.glassLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Center(
        child: Text(message,
            style: AppTypography.labelM.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center),
      ),
    );
  }
}

// ── Edit subscription sheet ───────────────────────────────────────────────────

class _EditSubscriptionSheet extends ConsumerStatefulWidget {
  const _EditSubscriptionSheet({
    required this.subscription,
    required this.onSave,
  });
  final Subscription subscription;
  final ValueChanged<Subscription> onSave;

  @override
  ConsumerState<_EditSubscriptionSheet> createState() =>
      _EditSubscriptionSheetState();
}

class _EditSubscriptionSheetState
    extends ConsumerState<_EditSubscriptionSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late SubscriptionFrequency _freq;
  late TransactionCategory _cat;
  late Color _color;
  late IconData _icon;
  late DateTime _billingDate;

  static const _iconOptions = [
    Icons.play_circle_rounded,
    Icons.music_note_rounded,
    Icons.smart_toy_rounded,
    Icons.ondemand_video_rounded,
    Icons.local_shipping_rounded,
    Icons.cloud_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.games_rounded,
    Icons.subscriptions_rounded,
  ];

  static const _colorOptions = [
    Color(0xFFE50914),
    Color(0xFF1DB954),
    Color(0xFF10A37F),
    Color(0xFFFF0000),
    Color(0xFFFF9900),
    Color(0xFF6366F1),
    AppColors.emerald,
    AppColors.petroleum,
    AppColors.catFood,
    AppColors.catShopping,
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    _nameCtrl = TextEditingController(text: s.name);
    _amountCtrl = TextEditingController(text: s.amount.toStringAsFixed(2));
    _freq = s.frequency;
    _cat = s.category;
    _color = s.color;
    _icon = s.icon;
    _billingDate = s.nextBillingDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.emerald,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _billingDate = picked);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    widget.onSave(widget.subscription.copyWith(
      name: name,
      amount: amount,
      frequency: _freq,
      category: _cat,
      color: _color,
      icon: _icon,
      nextBillingDate: _billingDate,
    ));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
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
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Editar suscripción',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxl),

            _SheetLabel('Nombre'),
            const SizedBox(height: AppSpacing.sm),
            _SheetTextField(
                controller: _nameCtrl,
                hint: 'ej. Netflix, Spotify…',
                icon: Icons.label_outline_rounded,
                autofocus: true),
            const SizedBox(height: AppSpacing.xl),

            _SheetLabel('Monto'),
            const SizedBox(height: AppSpacing.sm),
            _SheetTextField(
                controller: _amountCtrl,
                hint: 'ej. 9.99',
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: AppSpacing.xl),

            _SheetLabel('Próximo cobro'),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickDate,
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
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      DateFormat('d MMM yyyy', 'es').format(_billingDate),
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SheetLabel('Frecuencia'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: SubscriptionFrequency.values.map((f) {
                final active = f == _freq;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _freq = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.emeraldSurface
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: active
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(f.label,
                        style: AppTypography.labelM.copyWith(
                          color: active
                              ? AppColors.emerald
                              : AppColors.textTertiary,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            _SheetLabel('Icono'),
            const SizedBox(height: AppSpacing.sm),
            _IconPicker(
                icons: _iconOptions,
                selected: _icon,
                color: _color,
                onChanged: (ic) => setState(() => _icon = ic)),
            const SizedBox(height: AppSpacing.xl),

            _SheetLabel('Color'),
            const SizedBox(height: AppSpacing.sm),
            _ColorPicker(
                colors: _colorOptions,
                selected: _color,
                onChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDim]),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text('Guardar cambios',
                      style: AppTypography.labelL.copyWith(
                        color: AppColors.textInverse,
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

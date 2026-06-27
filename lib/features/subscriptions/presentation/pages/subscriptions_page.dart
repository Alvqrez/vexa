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
import '../../domain/models/subscription.dart';
import '../providers/subscriptions_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/numeric_keypad.dart';
import '../../../../shared/widgets/drag_handle.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

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
    )..revealForward();
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

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSubscriptionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          const _SubsBg(),
          SafeArea(
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
                        _SubsHeader(onAdd: () => _showAddSheet(context)),
                      ),
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
          Container(color: context.colors.background),
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
              color: context.colors.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.colors.glassBorder, width: 0.5),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suscripciones',
                style: AppTypography.headingM.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                'Pagos recurrentes',
                style: AppTypography.labelM.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
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
              color: AppColors.emeraldSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 18,
              color: AppColors.emerald,
            ),
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
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
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
              builder: (context, child) => SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _SubsArcPainter(
                    progress: _arcAnim.value,
                    trackColor: context.colors.glassMedium,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pmask('\$${total.toStringAsFixed(0)}'),
                          style: AppTypography.headingS.copyWith(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '/mes',
                          style: AppTypography.eyebrow.copyWith(
                            color: context.colors.textTertiary,
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
                    value: pmask('\$${(total * 12).toStringAsFixed(0)}'),
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
  const _SubsInfoRow({
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
              color: context.colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelL.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SubsArcPainter extends CustomPainter {
  const _SubsArcPainter({required this.progress, required this.trackColor});
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
  bool shouldRepaint(_SubsArcPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
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
        Text(
          'Próximos pagos',
          style: AppTypography.headingS.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (upcoming.isEmpty)
          _EmptyState(
            message: 'No hay pagos próximos en los siguientes 30 días',
          )
        else
          ...upcoming.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SubscriptionCard(subscription: s),
            ),
          ),
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
            Text(
              'Todas las suscripciones',
              style: AppTypography.headingS.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${all.length} total',
              style: AppTypography.labelS.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (all.isEmpty)
          _EmptyState(message: 'Sin suscripciones aún. Agrega la primera.')
        else
          ...all.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SubscriptionCard(subscription: s, showControls: true),
            ),
          ),
      ],
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({
    required this.subscription,
    this.showControls = false,
  });
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
          color: context.colors.card,
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
                  Text(
                    s.name,
                    style: AppTypography.labelL.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        s.frequency.label,
                        style: AppTypography.labelS.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.colors.textTertiary,
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
                              : context.colors.textTertiary,
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
                  pmask('\$${s.amount.toStringAsFixed(2)}'),
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.negative,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  s.frequency.shortLabel,
                  style: AppTypography.labelS.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
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
        Haptics.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SubsActionSheet(
            subscription: subscription,
            onEdit: () {
              Navigator.pop(context);
              if (!context.mounted) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _EditSubscriptionSheet(
                  subscription: subscription,
                  onSave: (updated) async =>
                      await ref.read(subscriptionsProvider.notifier).update(updated),
                ),
              );
            },
            onToggle: () async => await ref
                .read(subscriptionsProvider.notifier)
                .toggleActive(subscription.id),
            onDelete: () async => await ref
                .read(subscriptionsProvider.notifier)
                .delete(subscription.id),
            onCharge: () async => await ref
                .read(subscriptionsProvider.notifier)
                .chargeSubscription(subscription),
          ),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.colors.glass,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 14,
          color: context.colors.textSecondary,
        ),
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
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
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
                color: context.colors.textTertiary.withValues(alpha: 0.4),
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
                child: Icon(
                  subscription.icon,
                  size: 22,
                  color: subscription.color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: AppTypography.headingS.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    pmask('\$${subscription.amount.toStringAsFixed(2)}${subscription.frequency.shortLabel}'),
                    style: AppTypography.labelM.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
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
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Registrar pago'),
                  content: Text(
                    '¿Confirmar pago de ${subscription.name} por \$${subscription.amount.toStringAsFixed(2)}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              onCharge();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: subscription.isActive
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            label: subscription.isActive
                ? 'Pausar suscripción'
                : 'Activar suscripción',
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
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
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

// ── Add subscription sheet ─────────────────────────────────────────────────────

class AddSubscriptionSheet extends ConsumerStatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  ConsumerState<AddSubscriptionSheet> createState() =>
      _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<AddSubscriptionSheet> {
  final _nameCtrl = TextEditingController();
  late final ValueNotifier<String> _amountNotifier;
  SubscriptionFrequency _freq = SubscriptionFrequency.monthly;
  late WalletCategory _cat;
  Color _color = const Color(0xFF6366F1);
  IconData _icon = Icons.subscriptions_rounded;
  late DateTime _billingDate;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _amountNotifier = ValueNotifier<String>('');
    _billingDate = DateTime.now().add(const Duration(days: 30));
    final cats = ref.read(expenseCategoriesProvider);
    _cat = cats.firstWhere((c) => c.id == 'wc4', orElse: () => cats.first);
  }

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
    _amountNotifier.dispose();
    super.dispose();
  }

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Avanza `date` al próximo ciclo futuro según `freq` si está en el pasado.
  DateTime _ensureFuture(DateTime date, SubscriptionFrequency freq) {
    final today = DateTime.now();
    var d = date;
    while (!d.isAfter(today)) {
      switch (freq) {
        case SubscriptionFrequency.weekly:
          d = d.add(const Duration(days: 7));
        case SubscriptionFrequency.monthly:
          d = DateTime(d.year, d.month + 1, d.day);
        case SubscriptionFrequency.quarterly:
          d = DateTime(d.year, d.month + 3, d.day);
        case SubscriptionFrequency.annual:
          d = DateTime(d.year + 1, d.month, d.day);
      }
    }
    return d;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountNotifier.value);
    if (name.isEmpty || amount == null || amount <= 0) {
      Haptics.heavyImpact();
      return;
    }
    final billingDate = _ensureFuture(_billingDate, _freq);
    await ref.read(subscriptionsProvider.notifier).add(
          Subscription(
            id: generateId(),
            name: name,
            amount: amount,
            nextBillingDate: billingDate,
            category: _cat.id,
            icon: _icon,
            color: _color,
            frequency: _freq,
            accountId: _accountId,
          ),
        );
    Haptics.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    Haptics.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate.isAfter(now)
          ? _billingDate
          : now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
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
    if (picked != null) setState(() => _billingDate = picked);
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
                  style:
                      AppTypography.headingS.copyWith(color: c.textPrimary)),
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
                        color: sel
                            ? _color.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? _color.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                          width: sel ? 1.5 : 1,
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
                  style:
                      AppTypography.headingS.copyWith(color: c.textPrimary)),
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
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

  void _showFrequencySheet() {
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
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 8),
              child: Text('Frecuencia',
                  style:
                      AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            ...SubscriptionFrequency.values.map((f) {
              final sel = f == _freq;
              return GestureDetector(
                onTap: () {
                  Haptics.selectionClick();
                  setState(() => _freq = f);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.emeraldSurface : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 18,
                          color: sel ? AppColors.emerald : c.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(f.label,
                              style: AppTypography.labelL
                                  .copyWith(color: c.textPrimary))),
                      if (sel)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.emerald),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(List<dynamic> accounts) {
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: _accountId == null
                      ? c.textTertiary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_rounded,
                        size: 18, color: c.textTertiary),
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;

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
            Text('Nueva suscripción',
                style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: 12),

            // Nombre con icono (izq) y color (der)
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: AppTypography.labelL.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'ej. Netflix, Spotify…',
                hintStyle: AppTypography.labelL.copyWith(color: c.textTertiary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
                suffixIcon: GestureDetector(
                  onTap: _showColorSheet,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: _color.withValues(alpha: 0.5), width: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips (izq) | Monto (der)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: freq + date + account chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubChip(
                        icon: Icons.repeat_rounded,
                        label: _freq.label,
                        color: _color,
                        surface: c.card,
                        onTap: _showFrequencySheet,
                      ),
                      const SizedBox(height: 6),
                      _SubChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(_billingDate),
                        color: _color,
                        surface: c.card,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 6),
                      _SubChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: account != null ? account.name : 'Sin cuenta',
                        color: account != null ? account.color : c.textTertiary,
                        surface: c.card,
                        onTap: () => _showAccountSheet(accounts),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: big amount
                ValueListenableBuilder<String>(
                  valueListenable: _amountNotifier,
                  builder: (_, raw, _) {
                    final split = splitAmount(raw.isEmpty ? '0' : raw);
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
                                      color: _color.withValues(alpha: 0.65),
                                      height: 1)),
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
                                        color: _color,
                                        letterSpacing: -1.5,
                                        height: 1)),
                                Text(split.decimal,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: _color.withValues(alpha: 0.45),
                                        letterSpacing: -0.5,
                                        height: 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, raw, _) => NumericKeypad(
                value: raw,
                onValueChanged: (v) => _amountNotifier.value = v,
                confirmColor: _color,
                onConfirm: _submit,
                keyHeight: 44,
                confirmHeight: 48,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Sub chip ──────────────────────────────────────────────────────────────────

class _SubChip extends StatelessWidget {
  const _SubChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: color)),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 13, color: color.withValues(alpha: 0.7)),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.labelM.copyWith(color: context.colors.textTertiary),
          textAlign: TextAlign.center,
        ),
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
  late final ValueNotifier<String> _amountNotifier;
  late SubscriptionFrequency _freq;
  late WalletCategory _cat;
  late Color _color;
  late IconData _icon;
  late DateTime _billingDate;
  String? _accountId;

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
    _amountNotifier = ValueNotifier<String>(s.amount.toStringAsFixed(2));
    _freq = s.frequency;
    final cats = ref.read(walletCategoriesProvider);
    _cat = resolveCategory(s.category, cats);
    _color = s.color;
    _icon = s.icon;
    _billingDate = s.nextBillingDate;
    _accountId = s.accountId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountNotifier.dispose();
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
          colorScheme: ColorScheme.dark(
            primary: AppColors.emerald,
            surface: ctx.colors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _billingDate = picked);
  }

  String _formatDate(DateTime d) =>
      DateFormat('d MMM yyyy', 'es').format(d);

  void _showIconSheet() {
    Haptics.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadiusL)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        setSt(() {});
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel
                              ? _color.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? _color.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.06),
                            width: sel ? 1.5 : 1,
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadiusL)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        setSt(() {});
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
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
      ),
    );
  }

  void _showFrequencySheet() {
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
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 8),
              child: Text('Frecuencia',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            ...SubscriptionFrequency.values.map((f) {
              final sel = f == _freq;
              return GestureDetector(
                onTap: () {
                  Haptics.selectionClick();
                  setState(() => _freq = f);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.emeraldSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 18,
                          color: sel ? AppColors.emerald : c.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(f.label,
                              style: AppTypography.labelL
                                  .copyWith(color: c.textPrimary))),
                      if (sel)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.emerald),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet(List<dynamic> accounts) {
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountNotifier.value.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) {
      Haptics.heavyImpact();
      return;
    }
    widget.onSave(
      widget.subscription.copyWith(
        name: name,
        amount: amount,
        frequency: _freq,
        category: _cat.id,
        color: _color,
        icon: _icon,
        nextBillingDate: _billingDate,
        accountId: _accountId,
        clearAccountId: _accountId == null,
      ),
    );
    Haptics.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;

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
            Text('Editar suscripción',
                style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: 12),

            // Nombre con icono (izq) y color (der)
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: AppTypography.labelL.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'ej. Netflix, Spotify…',
                hintStyle: AppTypography.labelL.copyWith(color: c.textTertiary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
                suffixIcon: GestureDetector(
                  onTap: _showColorSheet,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(color: _color.withValues(alpha: 0.5), width: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips (izq) | Monto (der)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubChip(
                        icon: Icons.repeat_rounded,
                        label: _freq.label,
                        color: _color,
                        surface: c.card,
                        onTap: _showFrequencySheet,
                      ),
                      const SizedBox(height: 6),
                      _SubChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(_billingDate),
                        color: _color,
                        surface: c.card,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 6),
                      _SubChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: account != null ? account.name : 'Sin cuenta',
                        color: account != null ? account.color : c.textTertiary,
                        surface: c.card,
                        onTap: () => _showAccountSheet(accounts),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<String>(
                  valueListenable: _amountNotifier,
                  builder: (_, raw, _) {
                    final split = splitAmount(raw.isEmpty ? '0' : raw);
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
                                      color: _color.withValues(alpha: 0.65),
                                      height: 1)),
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
                                        color: _color,
                                        letterSpacing: -1.5,
                                        height: 1)),
                                Text(split.decimal,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: _color.withValues(alpha: 0.45),
                                        letterSpacing: -0.5,
                                        height: 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, raw, _) => NumericKeypad(
                value: raw,
                onValueChanged: (v) => _amountNotifier.value = v,
                confirmColor: _color,
                onConfirm: _submit,
                keyHeight: 44,
                confirmHeight: 48,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../subscriptions/domain/models/subscription.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../providers/wallet_provider.dart';
import '../../domain/models/wallet_category.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/domain/models/recurring_transaction.dart';
import '../../../home/presentation/pages/recurring_transactions_page.dart';
import '../../../loans/domain/models/loan.dart';
import '../../../loans/presentation/pages/loans_page.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import 'wallet_categories_page.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  static const _sectionCount = 6;

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
          curve: Interval(start, end, curve: AppCurves.gentle)),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _WalletBg(),
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
                    _reveal(0, const _WalletHeader()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _AccountsOverviewCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, const _SubscriptionsPreviewSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _LoansPreviewSection()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const _RecurringTransactionsCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(5, const _CategoriesPreviewSection()),
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

class _WalletBg extends StatelessWidget {
  const _WalletBg();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 380,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.07),
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

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mi Cartera',
            style: AppTypography.headingM
                .copyWith(color: c.textPrimary)),
        const SizedBox(height: 2),
        Text('Cuentas, suscripciones y categorías',
            style: AppTypography.labelM
                .copyWith(color: c.textTertiary)),
      ],
    );
  }
}

// ── Accounts overview card ────────────────────────────────────────────────────

class _AccountsOverviewCard extends ConsumerWidget {
  const _AccountsOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final total = ref.watch(totalBalanceProvider);
    final accounts = ref.watch(accountsProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final currency = ref.watch(currencySymbolProvider);

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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance total',
                        style: AppTypography.labelM
                            .copyWith(color: c.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      pmask('$currency${total.toStringAsFixed(2)}'),
                      style: AppTypography.headingL
                          .copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text('${accounts.length} cuentas',
                      style: AppTypography.eyebrow
                          .copyWith(color: AppColors.emeraldDim)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _MiniKpi(
                    label: 'Ingresos',
                    value: pmask('$currency${income.toStringAsFixed(0)}'),
                    color: AppColors.positive,
                    icon: Icons.south_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniKpi(
                    label: 'Gastos',
                    value: pmask('$currency${expenses.toStringAsFixed(0)}'),
                    color: AppColors.negative,
                    icon: Icons.north_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Account chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: accounts.map((a) {
                  return Container(
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                          color: a.color.withValues(alpha: 0.25), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: a.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(a.name,
                            style: AppTypography.labelS.copyWith(color: a.color)),
                        if (a.isSavings) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.savings_outlined,
                              size: 10, color: a.color),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelS
                        .copyWith(color: c.textTertiary)),
                Text(value,
                    style: AppTypography.labelL.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subscriptions preview ─────────────────────────────────────────────────────

class _SubscriptionsPreviewSection extends ConsumerWidget {
  const _SubscriptionsPreviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSubscriptionsProvider).take(3).toList();
    final total = ref.watch(monthlySubscriptionsTotalProvider);
    final currency = ref.watch(currencySymbolProvider);

    return _WalletSection(
      title: 'Suscripciones',
      subtitle: pmask('$currency${total.toStringAsFixed(2)}/mes'),
      icon: Icons.subscriptions_rounded,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SubscriptionsPage())),
      child: upcoming.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text('Sin suscripciones',
                    style: AppTypography.labelM
                        .copyWith(color: context.colors.textTertiary)),
              ),
            )
          : Column(
              children: upcoming.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _SubsPreviewTile(subscription: s),
                );
              }).toList(),
            ),
    );
  }
}

class _SubsPreviewTile extends ConsumerWidget {
  const _SubsPreviewTile({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final currency = ref.watch(currencySymbolProvider);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: subscription.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(subscription.icon, size: 17, color: subscription.color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(subscription.name,
              style:
                  AppTypography.labelL.copyWith(color: c.textPrimary)),
        ),
        Text(pmask('-$currency${subscription.amount.toStringAsFixed(2)}'),
            style: AppTypography.labelM.copyWith(
                color: AppColors.negative, fontWeight: FontWeight.w600)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          subscription.daysUntilBilling == 0
              ? 'Hoy'
              : 'en ${subscription.daysUntilBilling}d',
          style: AppTypography.labelS.copyWith(
            color: subscription.isDueSoon
                ? AppColors.warning
                : c.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ── Loans preview ─────────────────────────────────────────────────────────────

class _LoansPreviewSection extends ConsumerWidget {
  const _LoansPreviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeLoansProvider).take(3).toList();
    final totalLent = ref.watch(totalLentProvider);
    final totalBorrowed = ref.watch(totalBorrowedProvider);
    final currency = ref.watch(currencySymbolProvider);

    final subtitle = active.isEmpty
        ? 'Sin préstamos activos'
        : '$currency${totalLent.toStringAsFixed(0)} prestado · $currency${totalBorrowed.toStringAsFixed(0)} debido';

    return _WalletSection(
      title: 'Préstamos',
      subtitle: subtitle,
      icon: Icons.handshake_rounded,
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoansPage())),
      child: active.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text('Sin préstamos activos',
                    style: AppTypography.labelM
                        .copyWith(color: context.colors.textTertiary)),
              ),
            )
          : Column(
              children: active.map((l) {
                final isLent = l.type == LoanType.lentByMe;
                final accentColor =
                    isLent ? AppColors.positive : AppColors.negative;
                final cc = context.colors;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: l.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(l.icon, size: 17, color: l.color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name,
                                style: AppTypography.labelL
                                    .copyWith(color: cc.textPrimary)),
                            Text(l.type.label,
                                style: AppTypography.labelS
                                    .copyWith(color: cc.textTertiary)),
                          ],
                        ),
                      ),
                      Text(
                        pmask('${isLent ? '+' : '-'}$currency${l.remainingAmount.toStringAsFixed(2)}'),
                        style: AppTypography.labelM.copyWith(
                            color: accentColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── Categories preview ────────────────────────────────────────────────────────

class _CategoriesPreviewSection extends ConsumerWidget {
  const _CategoriesPreviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(walletCategoriesProvider).take(6).toList();

    return _WalletSection(
      title: 'Categorías',
      subtitle: '${ref.watch(walletCategoriesProvider).length} en total',
      icon: Icons.category_rounded,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WalletCategoriesPage())),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: cats.map((cat) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppSpacing.pillRadius),
              border: Border.all(
                  color: cat.color.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 13, color: cat.color),
                const SizedBox(width: 5),
                Text(cat.name,
                    style: AppTypography.labelS.copyWith(color: cat.color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Wallet section container ──────────────────────────────────────────────────

class _WalletSection extends StatelessWidget {
  const _WalletSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.02),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.petroleumSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.petroleum),
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
                      Text(subtitle,
                          style: AppTypography.labelS
                              .copyWith(color: c.textTertiary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                          color: c.glassBorder, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver todo',
                            style: AppTypography.labelS.copyWith(
                                color: c.textSecondary)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: c.textTertiary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, thickness: 0.5, color: c.glassBorder),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Recurring Transactions Card ───────────────────────────────────────────────

class _RecurringTransactionsCard extends ConsumerWidget {
  const _RecurringTransactionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringListProvider);
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    final preview = items.take(3).toList();

    return _WalletSection(
      title: 'Recurrentes',
      subtitle: '${items.length} configuradas',
      icon: Icons.repeat_rounded,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecurringTransactionsPage()),
      ),
      child: preview.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Sin transacciones recurrentes. Toca "Ver todo" para agregar.',
                style: AppTypography.labelM
                    .copyWith(color: context.colors.textTertiary),
              ),
            )
          : Column(
              children: preview.map((r) {
                final cc = context.colors;
                final walletCats = ref.watch(walletCategoriesProvider);
                final cat = resolveCategory(r.category, walletCats);
                final account =
                    accounts.where((a) => a.id == r.accountId).firstOrNull;
                final isIncome = r.type == TransactionType.income.name;
                final freqShort = _freqShort(r);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: cat.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon, size: 15, color: cat.color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.merchant,
                                style: AppTypography.labelL
                                    .copyWith(color: cc.textPrimary)),
                            Text(
                              '$freqShort${account != null ? ' · ${account.name}' : ''}',
                              style: AppTypography.labelS
                                  .copyWith(color: cc.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        pmask('${isIncome ? '+' : '-'}$currency${r.amount.toStringAsFixed(2)}'),
                        style: AppTypography.labelL.copyWith(
                          color: isIncome
                              ? AppColors.positive
                              : cc.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _freqShort(RecurringTransaction r) {
    final base = r.frequency.label.toLowerCase();
    final t = r.timesPerOccurrence > 1 ? ' × ${r.timesPerOccurrence}' : '';
    final d = r.weekDays;
    if (d != null) {
      const n = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
      final days = d.map((i) => n[i]).join('');
      return '$base$t ($days)';
    }
    return '$base$t';
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/domain/models/account.dart';
import '../../../home/presentation/widgets/transaction_item.dart';
import '../../../home/presentation/pages/add_transaction_page.dart';

class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(accountStatsProvider(accountId));
    final color = stats.account.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Colored glow behind header
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                      color: AppColors.glassBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Nueva transacción',
                      icon: Icons.add_rounded,
                      color: AppColors.emerald,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddTransactionSheet(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ActionButton(
                      label: 'Corrección',
                      icon: Icons.tune_rounded,
                      color: AppColors.warning,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _CorrectionSheet(account: stats.account),
                      ),
                    ),
                  ),
                ],
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

                      // Back + title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            stats.account.name,
                            style: AppTypography.headingM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Balance hero
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'SALDO ACTUAL',
                                style: AppTypography.eyebrow
                                    .copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${stats.balance.toStringAsFixed(2)}',
                            style: AppTypography.displayM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Ingresos',
                              value:
                                  '+\$${stats.income.toStringAsFixed(0)}',
                              color: AppColors.positive,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Egresos',
                              value:
                                  '-\$${stats.expenses.toStringAsFixed(0)}',
                              color: AppColors.negative,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Neto',
                              value: stats.net >= 0
                                  ? '+\$${stats.net.toStringAsFixed(0)}'
                                  : '-\$${stats.net.abs().toStringAsFixed(0)}',
                              color: stats.net >= 0
                                  ? AppColors.emerald
                                  : AppColors.negative,
                              icon: Icons.balance_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Category breakdown
                      if (stats.transactions.isNotEmpty) ...[
                        Text(
                          'Categorías',
                          style: AppTypography.headingS.copyWith(
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CategoryBreakdown(
                            transactions: stats.transactions),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Transactions list
                      Text(
                        'Movimientos',
                        style: AppTypography.headingS
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (stats.transactions.isEmpty)
                        _EmptyState(accountName: stats.account.name)
                      else
                        ...stats.transactions
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: TransactionItem(transaction: t),
                                )),

                      const SizedBox(height: 120),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
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
          Text(
            label,
            style: AppTypography.labelS
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.transactions});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final map = <TransactionCategory, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    if (map.isEmpty) return const SizedBox.shrink();

    final total = map.values.fold(0.0, (s, v) => s + v);
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final ratio = e.value / total;
        final color = e.key.color;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(e.key.icon, size: 13, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.label,
                            style: AppTypography.labelM
                                .copyWith(color: AppColors.textSecondary)),
                        Text('\$${e.value.toStringAsFixed(0)}',
                            style: AppTypography.labelM
                                .copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor:
                            color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.accountName});
  final String accountName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded,
              size: 32, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sin movimientos en $accountName',
            style: AppTypography.bodyM
                .copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelM
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Correction sheet ──────────────────────────────────────────────────────────

class _CorrectionSheet extends ConsumerStatefulWidget {
  const _CorrectionSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends ConsumerState<_CorrectionSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final newBalance = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (newBalance == null) return;

    final diff = newBalance - widget.account.balance;
    if (diff == 0) {
      Navigator.of(context).pop();
      return;
    }

    final tx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      merchant: 'Corrección de saldo',
      amount: diff.abs(),
      type: diff > 0 ? TransactionType.income : TransactionType.expense,
      category: TransactionCategory.other,
      date: DateTime.now(),
      note: 'Ajuste manual de saldo',
    );

    ref.read(transactionsProvider.notifier).add(tx);
    ref.read(accountsProvider.notifier).correctBalance(
          widget.account.id,
          newBalance,
        );

    HapticFeedback.mediumImpact();
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
          Text(
            'Corrección de saldo',
            style: AppTypography.headingS.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Úsalo cuando el saldo físico no coincide con el sistema.',
            style: AppTypography.labelM.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.20), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo actual',
                    style: AppTypography.labelM
                        .copyWith(color: AppColors.textSecondary)),
                Text(
                  '\$${widget.account.balance.toStringAsFixed(2)}',
                  style: AppTypography.headingS
                      .copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
              style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Saldo real',
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
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                      width: 0.5),
                ),
                child: Text(
                  'Aplicar corrección',
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.warning,
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

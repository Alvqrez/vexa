import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../home/domain/models/account.dart';
import '../../../home/presentation/widgets/transaction_item.dart';
import '../../../home/presentation/pages/add_transaction_page.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../home/domain/models/transfer_record.dart';

class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(accountStatsProvider(accountId));
    final color = stats.account.color;
    final currency = ref.watch(currencySymbolProvider);
    final allTransfers = ref.watch(transferHistoryProvider);
    final transfers = allTransfers
        .where(
          (r) => r.fromAccountId == accountId || r.toAccountId == accountId,
        )
        .toList();

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
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
                  colors: [color.withValues(alpha: 0.18), Colors.transparent],
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
                    horizontal: AppSpacing.screenPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Back + title + edit + delete
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
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              stats.account.name,
                              style: AppTypography.headingM.copyWith(
                                color: c.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                useSafeArea: true,
                                builder: (_) =>
                                    _EditAccountSheet(account: stats.account),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c.glass,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: c.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: c.card,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius,
                                    ),
                                  ),
                                  title: Text(
                                    'Eliminar cuenta',
                                    style: AppTypography.headingS.copyWith(
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  content: Text(
                                    '¿Eliminar "${stats.account.name}"? Esta acción no se puede deshacer.',
                                    style: AppTypography.bodyM.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancelar',
                                        style: AppTypography.labelM.copyWith(
                                          color: c.textTertiary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(accountsProvider.notifier)
                                            .deleteAccount(accountId);
                                        Navigator.of(context)
                                          ..pop()
                                          ..pop();
                                      },
                                      child: Text(
                                        'Eliminar',
                                        style: AppTypography.labelM.copyWith(
                                          color: AppColors.negative,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.negativeSurface,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: AppColors.negative.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.negative,
                              ),
                            ),
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
                                style: AppTypography.eyebrow.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currency${stats.balance.toStringAsFixed(2)}',
                            style: AppTypography.displayM.copyWith(
                              color: c.textPrimary,
                            ),
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
                                  '+$currency${stats.income.toStringAsFixed(0)}',
                              color: AppColors.positive,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Egresos',
                              value:
                                  '-$currency${stats.expenses.toStringAsFixed(0)}',
                              color: AppColors.negative,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Neto',
                              value: stats.net >= 0
                                  ? '+$currency${stats.net.toStringAsFixed(0)}'
                                  : '-$currency${stats.net.abs().toStringAsFixed(0)}',
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
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CategoryBreakdown(
                          transactions: stats.transactions,
                          currency: currency,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Transactions list
                      Text(
                        'Movimientos',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (stats.transactions.isEmpty)
                        _EmptyState(accountName: stats.account.name)
                      else
                        ...stats.transactions.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: TransactionItem(transaction: t),
                          ),
                        ),

                      // Transfers section
                      if (transfers.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Transferencias',
                          style: AppTypography.headingS.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...transfers.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _TransferRow(
                              record: r,
                              accountId: accountId,
                              accounts: ref.read(accountsProvider),
                              currency: currency,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Bottom action bar — rendered last so it sits above the scroll view
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
                color: c.background,
                border: Border(
                  top: BorderSide(color: c.glassBorder, width: 0.5),
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
                        useSafeArea: true,
                        builder: (_) =>
                            AddTransactionSheet(defaultAccountId: accountId),
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
                        builder: (_) =>
                            _CorrectionSheet(account: stats.account),
                      ),
                    ),
                  ),
                ],
              ),
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
        color: context.colors.card,
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
            style: AppTypography.labelS.copyWith(color: context.colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown({
    required this.transactions,
    required this.currency,
  });
  final List<Transaction> transactions;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletCats = ref.watch(walletCategoriesProvider);
    final map = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    if (map.isEmpty) return const SizedBox.shrink();

    final total = map.values.fold(0.0, (s, v) => s + v);
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((e) {
        final cat = resolveCategory(e.key, walletCats);
        final ratio = e.value / total;
        final color = cat.color;
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
                child: Icon(cat.icon, size: 13, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.name,
                          style: AppTypography.labelM.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        Text(
                          '$currency${e.value.toStringAsFixed(0)}',
                          style: AppTypography.labelM.copyWith(
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: color.withValues(alpha: 0.12),
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
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 32,
            color: context.colors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sin movimientos en $accountName',
            style: AppTypography.bodyM.copyWith(color: context.colors.textTertiary),
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
              style: AppTypography.labelM.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit account sheet ────────────────────────────────────────────────────────

const _kAccountColors = [
  Color(0xFF1565C0),
  Color(0xFF820AD1),
  Color(0xFF00D68F),
  Color(0xFFFF6B35),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFFFF9800),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
];

class _EditAccountSheet extends ConsumerStatefulWidget {
  const _EditAccountSheet({required this.account});
  final Account account;

  @override
  ConsumerState<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends ConsumerState<_EditAccountSheet> {
  late final TextEditingController _nameCtrl;
  late AccountIcon _icon;
  late int _colorIndex;
  late bool _isSavings;

  static const _icons = AccountIcon.values;
  static const _iconLabels = [
    'Banco',
    'Tarjeta',
    'Cartera',
    'Ahorros',
    'Inversión',
    'Efectivo',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.name);
    _icon = widget.account.icon;
    _isSavings = widget.account.isSavings;
    _colorIndex = _kAccountColors.indexWhere(
      (c) => c.toARGB32() == widget.account.color.toARGB32(),
    );
    if (_colorIndex < 0) _colorIndex = 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final updated = widget.account.copyWith(
      name: name,
      icon: _icon,
      color: _kAccountColors[_colorIndex],
      isSavings: _isSavings,
    );
    ref.read(accountsProvider.notifier).updateAccount(updated);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final color = _kAccountColors[_colorIndex];

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        24 + bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: context.colors.glassBorderStrong, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.glassMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Text(
              'Editar cuenta',
              style: AppTypography.headingS.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetLabel('Nombre'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      style: AppTypography.labelL.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ej. BBVA, Efectivo…',
                        hintStyle: AppTypography.labelL.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: context.colors.glass,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          borderSide: BorderSide(
                            color: context.colors.glassBorder,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          borderSide: BorderSide(
                            color: context.colors.glassBorder,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.emerald,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SheetLabel('Tipo'),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 68,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _icons.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final selected = _icon == _icons[i];
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _icon = _icons[i]);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 60,
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.15)
                                    : context.colors.glass,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? color.withValues(alpha: 0.40)
                                      : context.colors.glassBorder,
                                  width: selected ? 1.5 : 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _icons[i].iconData,
                                    size: 20,
                                    color: selected
                                        ? color
                                        : context.colors.textTertiary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _iconLabels[i],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: selected
                                          ? color
                                          : context.colors.textTertiary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
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
                    _SheetLabel('Color'),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _kAccountColors.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final selected = i == _colorIndex;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _colorIndex = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _kAccountColors[i],
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: context.colors.textPrimary,
                                        width: 2.5,
                                      )
                                    : null,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: _kAccountColors[i].withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: -2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isSavings = !_isSavings);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _isSavings
                              ? AppColors.emerald.withValues(alpha: 0.10)
                              : context.colors.glass,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(
                            color: _isSavings
                                ? AppColors.emerald.withValues(alpha: 0.40)
                                : context.colors.glassBorder,
                            width: _isSavings ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _isSavings
                                    ? AppColors.emerald.withValues(alpha: 0.15)
                                    : context.colors.glassMedium,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.savings_outlined,
                                size: 16,
                                color: _isSavings
                                    ? AppColors.emerald
                                    : context.colors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuenta de ahorro',
                                    style: AppTypography.labelL.copyWith(
                                      color: _isSavings
                                          ? context.colors.textPrimary
                                          : context.colors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Las transferencias a esta cuenta cuentan como ahorro',
                                    style: AppTypography.labelS.copyWith(
                                      color: context.colors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _isSavings
                                    ? AppColors.emerald
                                    : context.colors.glassMedium,
                                shape: BoxShape.circle,
                              ),
                              child: _isSavings
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.30),
                              blurRadius: 20,
                              spreadRadius: -4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Guardar cambios',
                            style: AppTypography.labelL.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelM.copyWith(
      color: context.colors.textSecondary,
      fontWeight: FontWeight.w600,
    ),
  );
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

  Future<void> _submit() async {
    final newBalance = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (newBalance == null) return;

    final diff = newBalance - widget.account.balance;
    if (diff == 0) {
      Navigator.of(context).pop();
      return;
    }

    final tx = Transaction(
      id: generateId(),
      merchant: 'Corrección de saldo',
      amount: diff.abs(),
      type: diff > 0 ? TransactionType.income : TransactionType.expense,
      category: 'wc6',
      date: DateTime.now(),
      accountId: widget.account.id,
      note: 'Ajuste manual de saldo',
    );

    await ref.read(transactionsProvider.notifier).add(tx);
    await ref
        .read(accountsProvider.notifier)
        .correctBalance(widget.account.id, newBalance);

    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl + bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
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
                color: context.colors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Corrección de saldo',
            style: AppTypography.headingS.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Úsalo cuando el saldo físico no coincide con el sistema.',
            style: AppTypography.labelM.copyWith(color: context.colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.20),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo actual',
                  style: AppTypography.labelM.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  '\$${widget.account.balance.toStringAsFixed(2)}',
                  style: AppTypography.headingS.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
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
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.bodyM.copyWith(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Saldo real',
                hintStyle: AppTypography.bodyM.copyWith(
                  color: context.colors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.attach_money_rounded,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
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
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
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

// ── Transfer row ──────────────────────────────────────────────────────────────

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.record,
    required this.accountId,
    required this.accounts,
    required this.currency,
  });

  final TransferRecord record;
  final String accountId;
  final List<Account> accounts;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = record.fromAccountId == accountId;
    final otherAccountId = isOutgoing
        ? record.toAccountId
        : record.fromAccountId;
    final otherAccount = accounts
        .where((a) => a.id == otherAccountId)
        .firstOrNull;
    final color = isOutgoing ? AppColors.negative : AppColors.positive;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(record.date.year, record.date.month, record.date.day);
    final String dateLabel;
    if (day == today) {
      dateLabel = 'Hoy';
    } else if (day == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Ayer';
    } else {
      dateLabel = '${record.date.day}/${record.date.month}/${record.date.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOutgoing
                  ? Icons.arrow_outward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOutgoing
                      ? 'Transferencia enviada'
                      : 'Transferencia recibida',
                  style: AppTypography.labelL.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOutgoing
                      ? 'A: ${otherAccount?.name ?? 'Cuenta desconocida'}'
                      : 'De: ${otherAccount?.name ?? 'Cuenta desconocida'}',
                  style: AppTypography.labelS.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isOutgoing ? '-' : '+'}$currency${record.amount.toStringAsFixed(2)}',
                style: AppTypography.labelL.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: AppTypography.labelS.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import 'add_transaction_page.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    final account = transaction.accountId != null
        ? accounts.where((a) => a.id == transaction.accountId).firstOrNull
        : null;
    final cats = ref.watch(walletCategoriesProvider);
    final cat = resolveCategory(transaction.category, cats);
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppColors.positive : AppColors.negative;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.glassMedium,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: c.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Detalle',
          style: AppTypography.headingS.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
        actions: [
          _MoreMenuButton(transaction: transaction, account: account),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero amount card
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xxxl,
                horizontal: AppSpacing.xxl,
              ),
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
                border: Border.all(
                  color: amountColor.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                children: [
                  // Hero: icon expanding from transaction list
                  Hero(
                    tag: 'txn_icon_${transaction.id}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: cat.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 28),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Amount
                  Text(
                    transaction.formattedWith(currency),
                    style: AppTypography.displayM.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Merchant
                  Text(
                    transaction.merchant,
                    style: AppTypography.headingM.copyWith(
                      color: c.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                    child: Text(
                      isIncome ? 'Ingreso' : 'Gasto',
                      style: AppTypography.labelM.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Details list
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: c.glassBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Categoría',
                    value: cat.name,
                    valueColor: cat.color,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Fecha',
                    value: _formatDate(transaction.date),
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Hora',
                    value: DateFormat('HH:mm').format(transaction.date),
                  ),
                  if (account != null) ...[
                    _Divider(),
                    _DetailRow(
                      icon: account.icon.iconData,
                      label: 'Cuenta',
                      value: account.name,
                      valueColor: account.color,
                    ),
                  ],
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    _Divider(),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Nota',
                      value: transaction.note!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Editar',
                    icon: Icons.edit_rounded,
                    color: AppColors.petroleum,
                    onTap: () => _openEdit(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ActionButton(
                    label: 'Eliminar',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.negative,
                    onTap: () => _deleteWithUndo(context, ref),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(existing: transaction),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(transactionsProvider.notifier);
    final c = context.colors;
    final deleted = transaction;

    notifier.delete(deleted);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '"${deleted.merchant}" eliminada',
          style: AppTypography.labelM.copyWith(color: c.textPrimary),
        ),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: AppColors.emerald,
          onPressed: () => notifier.add(deleted),
        ),
        backgroundColor: c.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    if (txDay == today) return 'Hoy';
    if (txDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return DateFormat('d MMM yyyy', 'es').format(date);
  }
}

// ── More menu ─────────────────────────────────────────────────────────────────

class _MoreMenuButton extends ConsumerWidget {
  const _MoreMenuButton({required this.transaction, required this.account});

  final Transaction transaction;
  final Account? account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return PopupMenuButton<String>(
      color: c.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.glassMedium,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: c.textSecondary,
          size: 20,
        ),
      ),
      onSelected: (v) {
        if (v == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTransactionSheet(existing: transaction),
          );
        } else if (v == 'delete') {
          HapticFeedback.mediumImpact();
          final messenger = ScaffoldMessenger.of(context);
          final notifier = ref.read(transactionsProvider.notifier);
          final c = context.colors;
          final deleted = transaction;

          notifier.delete(deleted);
          Navigator.of(context).pop();

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '"${deleted.merchant}" eliminada',
                style: AppTypography.labelM.copyWith(color: c.textPrimary),
              ),
              action: SnackBarAction(
                label: 'Deshacer',
                textColor: AppColors.emerald,
                onPressed: () => notifier.add(deleted),
              ),
              backgroundColor: c.card,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, color: c.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text('Editar',
                style: TextStyle(color: c.textPrimary, fontSize: 14)),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.negative, size: 18),
            SizedBox(width: 10),
            Text('Eliminar',
                style: TextStyle(color: AppColors.negative, fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.glassMedium,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.textSecondary, size: 17),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodyM.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.labelL.copyWith(
              color: valueColor ?? context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: context.colors.glassBorder,
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _press.reverse();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/models/transaction.dart';
import '../pages/transaction_detail_page.dart';
import '../pages/add_transaction_page.dart';
import '../providers/home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class TransactionItem extends ConsumerStatefulWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.isLast = false,
    this.enableSwipe = true,
    this.isSelected = false,
    this.selectionMode = false,
    this.onSelectToggle,
    this.selectionRadius,
  });

  final Transaction transaction;
  final bool isLast;
  final bool enableSwipe;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onSelectToggle;
  /// Dynamic corner radius for the selection highlight.
  /// Passed by the parent so adjacent selected items form one merged rect.
  final BorderRadius? selectionRadius;

  @override
  ConsumerState<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends ConsumerState<TransactionItem>
    with TickerProviderStateMixin {
  late AnimationController _press;
  late AnimationController _flash;
  late Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Single smooth pulse: fast in, brief hold, slow out.
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.11)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(0.11), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: 0.11, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_flash);

    // Fire flash on mount if this transaction was just added via Quick Add.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(newTransactionIdsProvider).contains(widget.transaction.id)) {
        _startFlash();
      }
    });
  }

  @override
  void dispose() {
    _press.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _startFlash() {
    if (_flash.isAnimating) return;
    final current = ref.read(newTransactionIdsProvider);
    if (current.contains(widget.transaction.id)) {
      ref.read(newTransactionIdsProvider.notifier).state =
          {...current}..remove(widget.transaction.id);
    }
    _flash.forward(from: 0);
  }

  void _openDetail() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(transaction: widget.transaction),
      ),
    );
  }

  void _openEdit() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddTransactionSheet(existing: widget.transaction),
    );
  }

  Future<void> _delete() async {
    HapticFeedback.heavyImpact();
    final t = widget.transaction;
    final c = context.colors;
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(transactionsProvider.notifier).delete(t);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Transacción eliminada',
            style: AppTypography.labelM.copyWith(color: c.textPrimary),
          ),
          backgroundColor: c.card,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.bottomNavHeight +
                AppSpacing.bottomNavBottomPadding +
                AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: AppColors.emerald,
            onPressed: () async {
              await ref.read(transactionsProvider.notifier).add(t);
            },
          ),
        ),
      );
  }

  void _openNote() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteSheet(note: widget.transaction.note!),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fires when provider changes while tile is already mounted (e.g. already on screen).
    ref.listen<Set<String>>(newTransactionIdsProvider, (_, ids) {
      if (ids.contains(widget.transaction.id)) _startFlash();
    });

    final c = context.colors;
    final t = widget.transaction;
    final cats = ref.watch(walletCategoriesProvider);
    final cat = resolveCategory(t.category, cats);
    final isIncome = t.isIncome;
    final currency = ref.watch(currencySymbolProvider);

    // Find the account matching this transaction
    final accounts = ref.watch(accountsProvider);
    final account = t.accountId != null
        ? accounts.where((a) => a.id == t.accountId).firstOrNull
        : null;

    final hasNote = t.note != null && t.note!.isNotEmpty;

    Widget tile = GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.selectionMode ? widget.onSelectToggle : _openDetail,
      onLongPress: !widget.selectionMode && widget.onSelectToggle != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onSelectToggle!();
            }
          : null,
      child: ScaleTransition(
        scale: _press,
        child: AnimatedBuilder(
          animation: _flash,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.petroleum.withValues(alpha: 0.18)
                  : AppColors.emerald.withValues(alpha: _flashOpacity.value),
              borderRadius: widget.isSelected
                  ? (widget.selectionRadius ??
                      BorderRadius.circular(AppSpacing.cardRadius.toDouble()))
                  : null,
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Hero: icon expands into the detail page
                Hero(
                  tag: 'txn_icon_${t.id}',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cat.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.merchant,
                        style: AppTypography.bodyM.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (account != null) ...[
                            Text(
                              account.name,
                              style: AppTypography.labelS.copyWith(
                                color: account.color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3, height: 3,
                              decoration: BoxDecoration(
                                color: c.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(_relativeDate(t.date),
                              style: AppTypography.labelS
                                  .copyWith(color: c.textTertiary)),
                        ],
                      ),
                      if (t.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: t.tags.take(3).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: c.glassMedium,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag,
                                style: AppTypography.labelS.copyWith(
                                    color: c.textTertiary,
                                    fontSize: 9)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasNote)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _openNote();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(
                                Icons.notes_rounded,
                                size: 13,
                                color: c.textTertiary,
                              ),
                            ),
                          ),
                        Text(
                          t.formattedWith(currency),
                          style: AppTypography.labelL.copyWith(
                            color: isIncome
                                ? AppColors.positive
                                : c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppColors.positiveSurface
                            : c.card,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                      ),
                      child: Text(
                        isIncome ? 'Entrada' : 'Salida',
                        style: AppTypography.labelS.copyWith(
                          color: isIncome
                              ? AppColors.positive
                              : c.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.enableSwipe || widget.selectionMode) return tile;

    return Dismissible(
      key: ValueKey(t.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: AppColors.petroleum,
        icon: Icons.edit_rounded,
        label: 'Editar',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: AppColors.negative,
        icon: Icons.delete_outline_rounded,
        label: 'Eliminar',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit — don't actually dismiss
          _openEdit();
          return false;
        }
        // Delete — confirm
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _delete();
        }
      },
      child: tile,
    );
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays}d';
  }
}

// ── Note sheet ────────────────────────────────────────────────────────────────

class _NoteSheet extends StatelessWidget {
  const _NoteSheet({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: c.glassBorderStrong, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                  top: AppSpacing.md, bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 15,
                      color: c.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Nota',
                      style: AppTypography.labelM.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  note,
                  style: AppTypography.bodyM.copyWith(
                    color: c.textPrimary,
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

// ── Swipe background ──────────────────────────────────────────────────────────

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? AppSpacing.xl : 0,
        right: isLeft ? 0 : AppSpacing.xl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: AppTypography.labelM
                        .copyWith(color: color, fontWeight: FontWeight.w600)),
              ]
            : [
                Text(label,
                    style: AppTypography.labelM
                        .copyWith(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
      ),
    );
  }
}

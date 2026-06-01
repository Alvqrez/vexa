import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../home/domain/models/account.dart';
import 'account_detail_page.dart';

class AllAccountsPage extends ConsumerWidget {
  const AllAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
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
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Mis cuentas',
                            style: AppTypography.headingM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          // Drag-to-reorder hint badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.glassLight,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.pillRadius),
                              border: Border.all(
                                  color: AppColors.glassBorder, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_vert_rounded,
                                    size: 13,
                                    color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text('Arrastra para ordenar',
                                    style: AppTypography.labelS.copyWith(
                                        color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Total balance
                      Text(
                        'PATRIMONIO TOTAL',
                        style: AppTypography.eyebrow
                            .copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 8),
                      AnimatedNumber(
                        value: totalBalance,
                        style: AppTypography.displayM.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Text(
                        '${accounts.length} cuentas',
                        style: AppTypography.headingS
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // ── Reorderable list ─────────────────────────────────────
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      0,
                      AppSpacing.screenPadding,
                      120,
                    ),
                    onReorderItem: (oldIndex, newIndex) {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(accountsProvider.notifier)
                          .reorder(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double elevation =
                              Tween<double>(begin: 0, end: 8)
                                  .evaluate(
                                      CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOut))
                                  .toDouble();
                          return Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Padding(
                        key: ValueKey(account.id),
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _AccountRow(account: account),
                      );
                    },
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

// ── Account row ───────────────────────────────────────────────────────────────

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final color = account.color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountDetailPage(accountId: account.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Account icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(account.icon.iconData, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: color.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedNumber(
                  value: account.balance,
                  style: AppTypography.headingS.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ver detalle',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.petroleum),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textTertiary),

            // Drag handle
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.drag_handle_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

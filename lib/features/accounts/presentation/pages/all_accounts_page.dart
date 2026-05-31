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
    final totalBalance =
        accounts.fold(0.0, (s, a) => s + a.balance);

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
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Header
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Total balance
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Accounts list
                      Text(
                        '${accounts.length} cuentas',
                        style: AppTypography.headingS
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ...accounts.map(
                        (account) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AccountRow(account: account),
                        ),
                      ),

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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final color = account.color;
    final pct = account.balance /
        (account.balance + 1); // just visual placeholder

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
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
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
          ],
        ),
      ),
    );
  }
}

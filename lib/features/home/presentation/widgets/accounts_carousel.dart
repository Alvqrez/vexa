import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import '../../../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../../../features/accounts/presentation/pages/all_accounts_page.dart';

class AccountsCarousel extends ConsumerWidget {
  const AccountsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis cuentas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AllAccountsPage()),
              ),
              child: Text(
                'Ver todo',
                style: AppTypography.labelM.copyWith(
                  color: AppColors.petroleum,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = (screenWidth -
                  2 * AppSpacing.screenPadding -
                  AppSpacing.md) /
              2.25;
          return SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: accounts.length,
              separatorBuilder: (context, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) =>
                  _AccountCard(account: accounts[index], width: cardWidth),
            ),
          );
        }),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.width});
  final Account account;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = account.color;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountDetailPage(accountId: account.id),
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          color: c.glass,
          border: Border.all(
            color: c.glassBorder,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  account.icon.iconData,
                  size: 17,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                account.name,
                style: AppTypography.labelM.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedNumber(
                value: account.balance,
                style: AppTypography.headingS.copyWith(
                  color: c.textPrimary,
                  fontSize: 15,
                  letterSpacing: -0.5,
                ),
                duration: const Duration(milliseconds: 900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

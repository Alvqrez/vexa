import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
                    color: AppColors.textPrimary,
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
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: accounts.length,
            separatorBuilder: (context, _) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _AccountCard(account: accounts[index]),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
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
        width: 148,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          color: Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
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
            color: AppColors.card,
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
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedNumber(
                value: account.balance,
                style: AppTypography.headingS.copyWith(
                  color: AppColors.textPrimary,
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

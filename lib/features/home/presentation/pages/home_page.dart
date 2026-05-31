import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../widgets/accounts_carousel.dart';
import '../widgets/categories_row.dart';
import '../widgets/home_header.dart';
import '../widgets/spending_card.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transactions_section.dart';
import '../../../health/presentation/widgets/health_score_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
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
                        const HomeHeader(),
                        const SizedBox(height: AppSpacing.xxl),
                        const SummaryBalanceCard(),
                        const SizedBox(height: AppSpacing.md),
                        const SummaryCardsRow(),
                        const SizedBox(height: AppSpacing.xl),
                        const HealthScoreWidget(),
                        const SizedBox(height: AppSpacing.xl),
                        const AccountsCarousel(),
                        const SizedBox(height: AppSpacing.xl),
                        const SpendingCard(),
                        const SizedBox(height: AppSpacing.xxl),
                        const _SectionBlock(),
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
        ),
      ),
    );
  }
}

// ── Section block: categories + transactions ──────────────────────────────────

class _SectionBlock extends StatelessWidget {
  const _SectionBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Categorías'),
        SizedBox(height: AppSpacing.md),
        CategoriesRow(),
        SizedBox(height: AppSpacing.xxl),
        TransactionsSection(),
      ],
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -140,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.06),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
    );
  }
}


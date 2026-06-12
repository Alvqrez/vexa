import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../domain/models/home_config.dart';
import '../providers/home_config_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/accounts_carousel.dart';
import '../widgets/balance_chart_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/categories_row.dart';
import '../widgets/home_header.dart';
import '../widgets/smart_insights_widget.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transactions_section.dart';
import '../widgets/financial_projection_widget.dart';
import '../../../education/presentation/widgets/daily_tip_card.dart';
import '../../../budget/presentation/widgets/budget_notification_banner.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    // Isar is local — brief pause gives satisfying visual feedback
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Widget _section(int i, Widget child) {
    final start = (i * 0.09).clamp(0.0, 0.7);
    final end = (start + 0.45).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: AppCurves.gentle),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.10),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  Widget _real(HomeSection section) => switch (section) {
        HomeSection.balanceCard => const SummaryBalanceCard(),
        HomeSection.accounts => const AccountsCarousel(),
        HomeSection.summaryCards => const SummaryCardsRow(),
        HomeSection.budgets => const BudgetSummaryCard(),
        HomeSection.balanceChart => const BalanceChartCard(),
        HomeSection.projection => const FinancialProjectionWidget(),
        HomeSection.insights => const SmartInsightsWidget(),
        HomeSection.tip => const DailyTipCard(),
        HomeSection.categories => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionLabel(label: 'Categorías'),
              const SizedBox(height: AppSpacing.md),
              const CategoriesRow(),
            ],
          ),
        HomeSection.transactions => const TransactionsSection(),
      };

  Widget _skeleton(HomeSection section) => switch (section) {
        HomeSection.balanceCard => const _BalanceSkeleton(),
        HomeSection.summaryCards => const _SummaryCardsSkeleton(),
        HomeSection.balanceChart => const _ChartSkeleton(),
        HomeSection.transactions => const _TransactionsSkeleton(),
        _ => const _GenericSkeleton(),
      };

  Widget _buildSection(HomeSection section) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: _dataReady
          ? KeyedSubtree(key: ValueKey('r_${section.name}'), child: _real(section))
          : KeyedSubtree(key: ValueKey('s_${section.name}'), child: _skeleton(section)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final config = ref.watch(homeConfigProvider);
    final visible = config.visibleSections;

    // Switch from skeleton to real content once accounts have loaded from Isar.
    // Accounts always have ≥2 defaults after first load.
    final accounts = ref.watch(accountsProvider);
    if (!_dataReady && accounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dataReady) setState(() => _dataReady = true);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                backgroundColor: c.card,
                color: AppColors.emerald,
                strokeWidth: 2.5,
                displacement: 48,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const BudgetNotificationBanner(),
                          const SizedBox(height: AppSpacing.lg),

                          // ── Header (always visible) ────────────────────
                          _section(0, const HomeHeader()),
                          const SizedBox(height: AppSpacing.xxl),

                          // ── Config-driven sections ─────────────────────
                          for (int i = 0; i < visible.length; i++) ...[
                            _section(i + 1, _buildSection(visible[i].section)),
                            SizedBox(height: _spacingAfter(visible[i].section)),
                          ],

                          SizedBox(
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
            ),
          ],
        ),
      ),
    );
  }

  double _spacingAfter(HomeSection section) => AppSpacing.xl;
}

// ── Background ────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
          // Top-right: petroleum
          Positioned(
            top: -140,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Mid-left: emerald
          Positioned(
            top: 280,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Bottom-right: purple accent
          Positioned(
            bottom: 80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.catShopping.withValues(alpha: 0.07),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      label,
      style: AppTypography.headingS.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }
}

// ── Skeleton shapes ───────────────────────────────────────────────────────────

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonPlaceholder(width: 90, height: 11, borderRadius: 6),
          const SizedBox(height: 12),
          SkeletonPlaceholder(width: 200, height: 42, borderRadius: 10),
          const SizedBox(height: 10),
          SkeletonPlaceholder(width: 140, height: 11, borderRadius: 6),
        ],
      ),
    );
  }
}

class _SummaryCardsSkeleton extends StatelessWidget {
  const _SummaryCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Row(
        children: [
          Expanded(child: _CardSkel()),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _CardSkel()),
        ],
      ),
    );
  }
}

class _CardSkel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SkeletonPlaceholder(width: 32, height: 32, borderRadius: 10),
            const SizedBox(width: 8),
            SkeletonPlaceholder(width: 60, height: 10, borderRadius: 5),
          ]),
          const SizedBox(height: AppSpacing.md),
          SkeletonPlaceholder(width: 100, height: 22, borderRadius: 8),
          const SizedBox(height: 6),
          SkeletonPlaceholder(width: 60, height: 10, borderRadius: 5),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SkeletonLoader(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonPlaceholder(width: 70, height: 16, borderRadius: 6),
                SkeletonPlaceholder(width: 90, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SkeletonPlaceholder(width: double.infinity, height: 180, borderRadius: 10),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonPlaceholder(width: 100, height: 11, borderRadius: 5),
                SkeletonPlaceholder(width: 80, height: 11, borderRadius: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SkeletonLoader(
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonPlaceholder(width: 80, height: 16, borderRadius: 6),
              SkeletonPlaceholder(width: 55, height: 14, borderRadius: 6),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Column(
              children: List.generate(4, (i) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          SkeletonPlaceholder(width: 46, height: 46, borderRadius: 14),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonPlaceholder(width: 110 + (i % 3) * 20.0, height: 13, borderRadius: 5),
                                const SizedBox(height: 6),
                                SkeletonPlaceholder(width: 70, height: 10, borderRadius: 5),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SkeletonPlaceholder(width: 55, height: 13, borderRadius: 5),
                              const SizedBox(height: 5),
                              SkeletonPlaceholder(width: 38, height: 10, borderRadius: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Divider(height: 1, thickness: 0.5, color: c.glassBorder),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericSkeleton extends StatelessWidget {
  const _GenericSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SkeletonLoader(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
      ),
    );
  }
}

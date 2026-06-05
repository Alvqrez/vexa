import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../widgets/accounts_carousel.dart';
import '../widgets/categories_row.dart';
import '../widgets/home_header.dart';
import '../widgets/smart_insights_widget.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transactions_section.dart';
import '../../../health/presentation/widgets/health_score_widget.dart';
import '../../../education/presentation/widgets/daily_tip_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

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

  Widget _section(int i, Widget child) {
    // Each section starts 60ms after the previous (overlapping)
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
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
                        const SizedBox(height: AppSpacing.lg),
                        _section(0, const HomeHeader()),
                        const SizedBox(height: AppSpacing.xxl),
                        _section(1, const SummaryBalanceCard()),
                        const SizedBox(height: AppSpacing.md),
                        _section(1, const SummaryCardsRow()),
                        const SizedBox(height: AppSpacing.xl),
                        _section(2, const SmartInsightsWidget()),
                        const SizedBox(height: AppSpacing.xl),
                        _section(3, const DailyTipCard()),
                        const SizedBox(height: AppSpacing.xl),
                        _section(4, const HealthScoreWidget()),
                        const SizedBox(height: AppSpacing.xl),
                        _section(5, const AccountsCarousel()),
                        const SizedBox(height: AppSpacing.xxl),
                        _section(6, _SectionLabel(label: 'Categorías')),
                        const SizedBox(height: AppSpacing.md),
                        _section(7, const CategoriesRow()),
                        const SizedBox(height: AppSpacing.xxl),
                        _section(8, const TransactionsSection()),
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
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.16),
                  Colors.transparent,
                ]),
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
                gradient: RadialGradient(colors: [
                  AppColors.emerald.withValues(alpha: 0.06),
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
    return Text(
      label,
      style: AppTypography.headingS.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }
}

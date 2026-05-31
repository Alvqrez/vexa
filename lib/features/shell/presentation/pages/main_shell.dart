import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../home/presentation/pages/add_transaction_page.dart';
import '../../../analysis/presentation/pages/analysis_page.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../home/presentation/providers/home_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  static const _pages = [
    HomePage(),
    AnalysisPage(),
    BudgetPage(),
    GoalsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedNavIndexProvider);

    ref.listen<int>(selectedNavIndexProvider, (prev, next) {
      if (next == 3) {
        _fabController.reverse();
      } else {
        _fabController.forward();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: index,
              children: _pages,
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(),
            ),
            Positioned(
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.bottomNavHeight +
                  AppSpacing.bottomNavBottomPadding +
                  AppSpacing.lg,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _fabController,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fabController,
                    curve: Curves.easeOut,
                  ),
                  child: _ShellAddFab(
                    onTap: () => _showAddTransaction(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

class _ShellAddFab extends StatefulWidget {
  const _ShellAddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ShellAddFab> createState() => _ShellAddFabState();
}

class _ShellAddFabState extends State<_ShellAddFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.91,
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.emerald, AppColors.emeraldDim],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.30),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.textInverse,
            size: 26,
          ),
        ),
      ),
    );
  }
}

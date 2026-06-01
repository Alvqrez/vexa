import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/expandable_fab.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../home/presentation/pages/add_transaction_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../analysis/presentation/pages/analysis_page.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../goals/presentation/pages/goals_page.dart';
import '../../../goals/domain/models/financial_goal.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  bool _fabOpen = false;
  final _fabKey = GlobalKey<ExpandableFabState>();

  static const _pages = [
    HomePage(),
    WalletPage(),
    AnalysisPage(),
    BudgetPage(),
    GoalsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _closeFab() => _fabKey.currentState?.close();

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedNavIndexProvider);

    ref.listen<int>(selectedNavIndexProvider, (_, next) {
      _closeFab(); // Close FAB on tab switch
      if (next == 4) {
        _fabCtrl.reverse();
      } else {
        _fabCtrl.forward();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // ── Animated tab content ───────────────────────────────────
            _FadeIndexedStack(index: index, children: _pages),

            // ── Dismissal barrier — sits ABOVE pages but BELOW nav and FAB.
            // Visible only when the FAB menu is open. Tapping it closes the FAB.
            if (_fabOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeFab,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // ── Bottom nav ─────────────────────────────────────────────
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(),
            ),

            // ── Expandable FAB ─────────────────────────────────────────
            Positioned(
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.bottomNavHeight +
                  AppSpacing.bottomNavBottomPadding +
                  AppSpacing.lg,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _fabCtrl,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fabCtrl,
                    curve: Curves.easeOut,
                  ),
                  child: ExpandableFab(
                    key: _fabKey,
                    actions: _buildActions(context),
                    onOpenChanged: (open) =>
                        setState(() => _fabOpen = open),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FabAction> _buildActions(BuildContext context) => [
        FabAction(
          icon: Icons.remove_rounded,
          label: 'Nuevo gasto',
          color: AppColors.negative,
          onTap: () => showTransactionSheet(context,
              defaultType: TransactionType.expense),
        ),
        FabAction(
          icon: Icons.add_rounded,
          label: 'Nuevo ingreso',
          color: AppColors.positive,
          onTap: () => showTransactionSheet(context,
              defaultType: TransactionType.income),
        ),
        FabAction(
          icon: Icons.flag_rounded,
          label: 'Nueva meta',
          color: AppColors.petroleum,
          onTap: () => _showAddGoal(context),
        ),
        FabAction(
          icon: Icons.subscriptions_rounded,
          label: 'Suscripción',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionsPage()),
          ),
        ),
      ];

  void _showAddGoal(BuildContext context) {
    ref.read(selectedNavIndexProvider.notifier).state = 4;
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _QuickAddGoalSheet(),
      );
    });
  }
}

// ── Global helper to show AddTransactionSheet consistently ────────────────────

void showTransactionSheet(
  BuildContext context, {
  Transaction? existing,
  TransactionType defaultType = TransactionType.expense,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => AddTransactionSheet(
      existing: existing,
      defaultType: defaultType,
    ),
  );
}

// ── Fade-in tab switcher (replaces IndexedStack) ──────────────────────────────
//
// • Paints only the ACTIVE page (all others are Offstage after fade-out)
// • RepaintBoundary isolates each page's repaint layer
// • 200ms cross-fade on tab switch
// • No widget state is lost (all pages remain in the tree)

class _FadeIndexedStack extends StatefulWidget {
  const _FadeIndexedStack({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<bool> _visible;

  @override
  void initState() {
    super.initState();
    final n = widget.children.length;
    _visible = List.generate(n, (i) => i == widget.index);
    _ctrls = List.generate(n, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
        value: i == widget.index ? 1.0 : 0.0,
      );
      ctrl.addStatusListener((status) {
        if (!mounted) return;
        if (status == AnimationStatus.dismissed) {
          setState(() => _visible[i] = false);
        }
      });
      return ctrl;
    });
  }

  @override
  void didUpdateWidget(_FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      setState(() => _visible[widget.index] = true);
      _ctrls[old.index].reverse();
      _ctrls[widget.index].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final anim = CurvedAnimation(
          parent: _ctrls[i],
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Offstage(
          offstage: !_visible[i],
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(anim),
              child: RepaintBoundary(child: widget.children[i]),
            ),
          ),
        );
      }),
    );
  }
}

// ── Quick add goal sheet ──────────────────────────────────────────────────────

class _QuickAddGoalSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QuickAddGoalSheet> createState() => _QuickAddGoalSheetState();
}

class _QuickAddGoalSheetState extends ConsumerState<_QuickAddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  Color _color = AppColors.petroleum;
  IconData _icon = Icons.flag_rounded;

  static const _icons = [
    Icons.flag_rounded,
    Icons.laptop_rounded,
    Icons.flight_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.savings_rounded,
  ];
  static const _colors = [
    AppColors.petroleum,
    AppColors.emerald,
    AppColors.catFood,
    AppColors.catTransport,
    AppColors.warning,
    AppColors.catShopping,
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (title.isEmpty || target == null || target <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    ref.read(goalsProvider.notifier).add(FinancialGoal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          icon: _icon,
          color: _color,
          current: 0,
          target: target,
          deadline: DateTime.now().add(const Duration(days: 90)),
        ));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Nueva meta',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xl),
          _GoalField(_titleCtrl, 'Nombre de la meta', Icons.label_outline_rounded),
          const SizedBox(height: AppSpacing.md),
          _GoalField(_targetCtrl, 'Monto objetivo', Icons.attach_money_rounded,
              numeric: true),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: _icons.map((ic) {
              final sel = ic == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? _color.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel
                            ? _color.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Icon(ic,
                      size: 20,
                      color: sel ? _color : AppColors.textTertiary),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: _colors.map((c) {
              final sel = c.toARGB32() == _color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 2.5),
                  ),
                  child: sel
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldDim]),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: const Text('Crear meta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  const _GoalField(this.controller, this.hint, this.icon, {this.numeric = false});
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        autofocus: !numeric,
        keyboardType:
            numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon:
              Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

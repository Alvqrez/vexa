import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/utils/id_gen.dart';
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
import '../../../../core/providers/settings_provider.dart';
import '../../../home/domain/models/account.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/domain/models/recurring_transaction.dart';
import '../../../home/domain/models/transfer_record.dart';
import '../../../home/presentation/providers/home_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

// ── Tutorial step data ────────────────────────────────────────────────────────

class _TutorialStep {
  const _TutorialStep({
    required this.navIndex,
    required this.title,
    required this.description,
  });
  final int navIndex; // -1 = FAB
  final String title;
  final String description;
}

const _kTutorialSteps = [
  _TutorialStep(
    navIndex: 0,
    title: 'Inicio',
    description: 'Ve tu saldo total, el resumen del mes y las últimas transacciones de todas tus cuentas.',
  ),
  _TutorialStep(
    navIndex: 1,
    title: 'Cartera',
    description: 'Gestiona tus cuentas y organiza las categorías de gastos e ingresos.',
  ),
  _TutorialStep(
    navIndex: 2,
    title: 'Análisis',
    description: 'Gráficas y reportes que muestran hacia dónde va tu dinero cada mes.',
  ),
  _TutorialStep(
    navIndex: 3,
    title: 'Presupuesto',
    description: 'Asigna límites de gasto por categoría y controla que no te pases.',
  ),
  _TutorialStep(
    navIndex: 4,
    title: 'Metas',
    description: 'Define objetivos de ahorro y sigue tu progreso hacia cada uno.',
  ),
  _TutorialStep(
    navIndex: -1,
    title: 'Agregar transacción',
    description: 'Con este botón registras gastos, ingresos, nuevas metas y suscripciones de forma rápida.',
  ),
];

// ── Main shell state ──────────────────────────────────────────────────────────

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  bool _fabOpen = false;
  final _fabKey = GlobalKey<ExpandableFabState>();

  bool _showTutorial = false;
  int _tutorialStep = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shown = await LocalPrefsService.getBool('tutorial_shown');
      if (!shown && mounted) {
        setState(() => _showTutorial = true);
        // Savings explainer fires after the tutorial (_endTutorial handles it)
      } else {
        // Tutorial already done — show savings explainer once if not yet seen
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await _maybeShowSavingsExplainer();
      }
      if (!mounted) return;
      await _processRecurring();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _closeFab() => _fabKey.currentState?.close();

  void _nextTutorialStep() {
    if (_tutorialStep < _kTutorialSteps.length - 1) {
      final next = _tutorialStep + 1;
      final navIndex = _kTutorialSteps[next].navIndex;
      if (navIndex >= 0) {
        ref.read(selectedNavIndexProvider.notifier).state = navIndex;
      }
      setState(() => _tutorialStep = next);
    } else {
      _endTutorial();
    }
  }

  Future<void> _processRecurring() async {
    try {
      final all = await RecurringTransaction.loadAll();
      if (all.isEmpty) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool changed = false;
      final updated = <RecurringTransaction>[];
      for (var r in all) {
        if (!r.isActive) { updated.add(r); continue; }
        var current = r;
        try {
          while (!current.nextDate.isAfter(today)) {
            // Skip days not in weekDays (if set)
            final dayAllowed = current.weekDays == null ||
                current.weekDays!.contains(current.nextDate.weekday);
            if (dayAllowed) {
              final baseType = TransactionType.values.firstWhere(
                  (v) => v.name == current.type,
                  orElse: () => TransactionType.expense);
              final baseCat = TransactionCategory.values.firstWhere(
                  (v) => v.name == current.category,
                  orElse: () => TransactionCategory.other);
              for (var i = 0; i < current.timesPerOccurrence; i++) {
                final t = Transaction(
                  id: '${current.id}_${current.nextDate.millisecondsSinceEpoch}_$i',
                  merchant: current.merchant,
                  amount: current.amount,
                  type: baseType,
                  category: baseCat,
                  date: current.nextDate,
                  accountId: current.accountId,
                  note: current.note,
                );
                ref.read(transactionsProvider.notifier).add(t);
              }
            }
            final nextD = current.frequency.nextDateFrom(
                current.nextDate, current.weekDays);
            current = current.copyWith(nextDate: nextD);
            changed = true;
          }
        } catch (_) {
          // Skip this recurring entry if processing fails; keep its current state.
        }
        updated.add(current);
      }
      if (changed) await RecurringTransaction.saveAll(updated);
    } catch (_) {}
  }

  Future<void> _endTutorial() async {
    setState(() => _showTutorial = false);
    await LocalPrefsService.setBool('tutorial_shown', true);
    await Future.delayed(const Duration(milliseconds: 400));
    await _maybeShowSavingsExplainer();
  }

  Future<void> _maybeShowSavingsExplainer() async {
    final already = await LocalPrefsService.getBool('savings_explained');
    if (already || !mounted) return;
    await LocalPrefsService.setBool('savings_explained', true);
    if (!mounted) return;
    final name = ref.read(userProfileProvider).firstName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _SavingsExplainerSheet(name: name),
    );
  }

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

            // ── Tutorial coach marks ───────────────────────────────────
            if (_showTutorial)
              _TutorialOverlay(
                step: _tutorialStep,
                steps: _kTutorialSteps,
                onNext: _nextTutorialStep,
                onSkip: _endTutorial,
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
          icon: Icons.compare_arrows_rounded,
          label: 'Transferencia',
          color: AppColors.catTransport,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _TransferSheet(),
          ),
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
          id: generateId(),
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

// ── Tutorial overlay ──────────────────────────────────────────────────────────

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({
    required this.step,
    required this.steps,
    required this.onNext,
    required this.onSkip,
  });
  final int step;
  final List<_TutorialStep> steps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[widget.step];
    const sp = AppSpacing.screenPadding;
    const navH = AppSpacing.bottomNavHeight;
    const navBP = AppSpacing.bottomNavBottomPadding;

    final navCenterY = size.height - navBP - navH / 2;
    final tabW = (size.width - 2 * sp) / 5;

    final Offset center;
    final double radius;
    if (step.navIndex >= 0) {
      center = Offset(sp + (step.navIndex + 0.5) * tabW, navCenterY);
      radius = 34;
    } else {
      // FAB
      center = Offset(
        size.width - sp - 28,
        size.height - navH - navBP - AppSpacing.lg - 28,
      );
      radius = 36;
    }

    // Card sits above the spotlight, clamped within safe area
    final cardTop =
        (center.dy - radius - 20 - 190).clamp(16.0, size.height - 240.0);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _SpotlightPainter(center: center, radius: radius),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: cardTop,
              child: _TutorialCard(
                step: widget.step,
                total: widget.steps.length,
                title: step.title,
                description: step.description,
                isLast: widget.step == widget.steps.length - 1,
                onNext: widget.onNext,
                onSkip: widget.onSkip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.center, required this.radius});
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.center != center || old.radius != radius;
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.step,
    required this.total,
    required this.title,
    required this.description,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });
  final int step;
  final int total;
  final String title;
  final String description;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(
            color: AppColors.glassBorderStrong, width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSurface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Text('${step + 1} / $total',
                    style: AppTypography.eyebrow
                        .copyWith(color: AppColors.emerald)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSkip();
                },
                child: Text('Omitir',
                    style: AppTypography.labelM
                        .copyWith(color: AppColors.textTertiary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTypography.headingS
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(description,
              style: AppTypography.bodyM.copyWith(
                  color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onNext();
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldDim]),
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Text(isLast ? 'Comenzar' : 'Siguiente',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transfer sheet ────────────────────────────────────────────────────────────

class _TransferSheet extends ConsumerStatefulWidget {
  const _TransferSheet();

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  final _amountCtrl = TextEditingController();
  String? _fromId;
  String? _toId;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(accountsProvider);
    if (accounts.length >= 2) {
      _fromId = accounts.first.id;
      _toId = accounts[1].id;
    } else if (accounts.isNotEmpty) {
      _fromId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTypography.labelM.copyWith(color: AppColors.textPrimary)),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
    ));
  }

  void _confirm() {
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError('Ingresa un monto válido');
      return;
    }
    if (_fromId == null || _toId == null) {
      _showError('Selecciona ambas cuentas');
      return;
    }
    if (_fromId == _toId) {
      _showError('Las cuentas deben ser diferentes');
      return;
    }
    final fromAccount =
        ref.read(accountsProvider).firstWhere((a) => a.id == _fromId);
    if (fromAccount.balance < amount) {
      _showError('Saldo insuficiente en ${fromAccount.name}');
      return;
    }
    HapticFeedback.mediumImpact();
    final accounts = ref.read(accountsProvider);
    final toAccount = accounts.firstWhere((a) => a.id == _toId);
    final notifier = ref.read(accountsProvider.notifier);
    notifier.adjustBalance(_fromId!, -amount);
    notifier.adjustBalance(_toId!, amount);
    if (toAccount.isSavings) {
      ref.read(savingsTransfersProvider.notifier).addTransfer(amount);
    }
    // Save audit record
    final record = TransferRecord(
      id: generateId(),
      fromAccountId: _fromId!,
      toAccountId: _toId!,
      amount: amount,
      date: DateTime.now(),
    );
    ref.read(transferHistoryProvider.notifier).add(record);
    Navigator.of(context).pop();
  }

  void _pickAccount({required bool isFrom}) {
    HapticFeedback.selectionClick();
    final accounts = ref.read(accountsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(isFrom ? 'Cuenta origen' : 'Cuenta destino',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            ...accounts.map((a) {
              final sel = isFrom ? a.id == _fromId : a.id == _toId;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isFrom) { _fromId = a.id; } else { _toId = a.id; }
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: sel
                        ? a.color.withValues(alpha: 0.12)
                        : AppColors.glassLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: sel
                          ? a.color.withValues(alpha: 0.35)
                          : AppColors.glassBorder,
                      width: sel ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(a.icon.iconData, size: 18, color: a.color),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(a.name,
                            style: AppTypography.labelL
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                      if (sel)
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: a.color),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final fromAccount = accounts.where((a) => a.id == _fromId).firstOrNull;
    final toAccount = accounts.where((a) => a.id == _toId).firstOrNull;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md,
          AppSpacing.xxl, AppSpacing.xxl + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.catTransport.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.compare_arrows_rounded,
                    size: 18, color: AppColors.catTransport),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Transferencia',
                  style: AppTypography.headingS
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10), width: 0.5),
            ),
            child: TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTypography.headingM
                  .copyWith(color: AppColors.catTransport, fontSize: 28),
              decoration: InputDecoration(
                hintText: '${currency}0.00',
                hintStyle: AppTypography.headingM.copyWith(
                    color: AppColors.textTertiary, fontSize: 28),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickAccount(isFrom: true),
                  child: _TransferAccountChip(
                    label: fromAccount?.name ?? 'Origen',
                    color: fromAccount?.color ?? AppColors.textTertiary,
                    icon: fromAccount?.icon.iconData ??
                        Icons.account_balance_wallet_rounded,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.textTertiary),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickAccount(isFrom: false),
                  child: _TransferAccountChip(
                    label: toAccount?.name ?? 'Destino',
                    color: toAccount?.color ?? AppColors.textTertiary,
                    icon: toAccount?.icon.iconData ??
                        Icons.account_balance_wallet_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: _confirm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.catTransport,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.catTransport.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text('Confirmar transferencia',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelL.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferAccountChip extends StatelessWidget {
  const _TransferAccountChip(
      {required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelM.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 14, color: color.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

// ── Savings explainer sheet ───────────────────────────────────────────────────

class _SavingsExplainerSheet extends StatelessWidget {
  const _SavingsExplainerSheet({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    const savingsColor = Color(0xFF7C5CFC);
    final greeting = name.isEmpty ? '' : '$name, ';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          // Icon + title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: savingsColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.savings_outlined,
                    size: 24, color: savingsColor),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'Tu cuenta de Ahorro',
                  style: AppTypography.headingS
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Body text
          _Paragraph(
            'Lo más importante para una buena gestión de finanzas es el ahorro. '
            'Hemos creado una cuenta especialmente para ello.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tip card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: savingsColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: savingsColor.withValues(alpha: 0.22), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${greeting}en tu cuarto o en tu hogar, designa una botella '
                    'con un corte, una cartera, una lata —cualquier recipiente '
                    'donde puedas guardar monedas y billetes. Ponle "Ahorro" con plumón.',
                    style: AppTypography.bodyM.copyWith(
                        color: AppColors.textSecondary, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Paragraph(
            'Cada vez que metas dinero en ese recipiente, regístralo en esta cuenta. '
            'Vexa usará ese dato para darte predicciones del mes y mostrarte '
            'información financiera más precisa.',
          ),
          const SizedBox(height: AppSpacing.xxl),

          // CTA button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C5CFC), Color(0xFF5A3FD4)]),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '¡Entendido!',
                textAlign: TextAlign.center,
                style: AppTypography.labelL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyM
          .copyWith(color: AppColors.textSecondary, height: 1.55),
    );
  }
}

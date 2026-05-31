import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

// ── Budget item model ─────────────────────────────────────────────────────────

class BudgetItem {
  const BudgetItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.limit,
  });

  final String name;
  final IconData icon;
  final Color color;
  final double spent;
  final double limit;

  double get ratio => (spent / limit).clamp(0.0, 1.0);
  double get remaining => limit - spent;
  bool get isWarning => ratio >= 0.80;

  Color get surface => color.withValues(alpha: 0.18);
}

// ── Preset icon options ───────────────────────────────────────────────────────

const _kIconOptions = [
  Icons.fork_right_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.favorite_rounded,
  Icons.home_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.sports_esports_rounded,
  Icons.fitness_center_rounded,
  Icons.local_cafe_rounded,
  Icons.pets_rounded,
  Icons.music_note_rounded,
  Icons.health_and_safety_rounded,
  Icons.savings_rounded,
  Icons.category_rounded,
];

// ── Preset color options ──────────────────────────────────────────────────────

const _kColorOptions = [
  AppColors.catFood,
  AppColors.catTransport,
  AppColors.catShopping,
  AppColors.catEntertainment,
  AppColors.catHealth,
  AppColors.emerald,
  AppColors.petroleum,
  AppColors.negative,
  AppColors.warning,
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  AppColors.catOther,
];

// ── Page ──────────────────────────────────────────────────────────────────────

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  static const _sectionCount = 4;

  final List<BudgetItem> _items = const [
    BudgetItem(
      name: 'Comida',
      icon: Icons.fork_right_rounded,
      color: AppColors.catFood,
      spent: 92.20,
      limit: 300,
    ),
    BudgetItem(
      name: 'Compras',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.catShopping,
      spent: 89.95,
      limit: 200,
    ),
    BudgetItem(
      name: 'Salud',
      icon: Icons.favorite_rounded,
      color: AppColors.catHealth,
      spent: 45.00,
      limit: 100,
    ),
    BudgetItem(
      name: 'Entretenimiento',
      icon: Icons.movie_rounded,
      color: AppColors.catEntertainment,
      spent: 9.99,
      limit: 50,
    ),
    BudgetItem(
      name: 'Transporte',
      icon: Icons.directions_car_rounded,
      color: AppColors.catTransport,
      spent: 12.50,
      limit: 150,
    ),
  ];

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final start = i / _sectionCount * 0.55;
    final end = (start + 0.55).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: AppCurves.gentle),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _BudgetBg(),
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
                    _reveal(0, const _BudgetHeader()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _BudgetOverviewCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, _BudgetCategoryList(items: _items)),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, _AddBudgetButton(onTap: _showAddSheet)),
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
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _BudgetBg extends StatelessWidget {
  const _BudgetBg();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 420,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.07),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presupuesto',
              style: AppTypography.headingM.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Mayo 2026',
              style: AppTypography.labelM.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.glassLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ],
    );
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _BudgetOverviewCard extends StatefulWidget {
  const _BudgetOverviewCard();

  @override
  State<_BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<_BudgetOverviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arc;
  late Animation<double> _arcAnim;

  static const double _spent = 249.64;
  static const double _limit = 2000.0;

  @override
  void initState() {
    super.initState();
    _arc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _arcAnim = CurvedAnimation(parent: _arc, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _arc.forward();
    });
  }

  @override
  void dispose() {
    _arc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _spent / _limit;
    final remaining = _limit - _spent;
    final daysLeft = DateTime(2026, 6, 1)
        .difference(DateTime.now())
        .inDays
        .clamp(0, 31);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFF1C1C32), Color(0xFF141428), Color(0xFF0F0F1E)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.06),
              blurRadius: 60,
              spreadRadius: -8,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _arcAnim,
              builder: (_, child) => SizedBox(
                width: 116,
                height: 116,
                child: CustomPaint(
                  painter:
                      _BudgetArcPainter(progress: ratio * _arcAnim.value),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: AppTypography.headingS.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'usado',
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                    child: Text(
                      'MAYO 2026',
                      style: AppTypography.eyebrow
                          .copyWith(color: AppColors.emeraldDim),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$${_spent.toStringAsFixed(0)}',
                          style: AppTypography.headingL
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        TextSpan(
                          text: ' / \$${_limit.toStringAsFixed(0)}',
                          style: AppTypography.bodyM
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(
                    icon: Icons.savings_outlined,
                    label: 'Disponible',
                    value: '\$${remaining.toStringAsFixed(0)}',
                    color: AppColors.positive,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Días restantes',
                    value: '$daysLeft',
                    color: AppColors.petroleum,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 11, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style:
                AppTypography.labelM.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(value,
            style: AppTypography.labelL.copyWith(color: color)),
      ],
    );
  }
}

class _BudgetArcPainter extends CustomPainter {
  const _BudgetArcPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 7.0;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.card
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = AppColors.emeraldGlow
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress,
          colors: [
            AppColors.emerald.withValues(alpha: 0.6),
            AppColors.emerald,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BudgetArcPainter old) => old.progress != progress;
}

// ── Category list ─────────────────────────────────────────────────────────────

class _BudgetCategoryList extends StatelessWidget {
  const _BudgetCategoryList({required this.items});

  final List<BudgetItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Por categoría',
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${items.length} activos',
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _BudgetCategoryCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryCard extends StatefulWidget {
  const _BudgetCategoryCard({required this.item});
  final BudgetItem item;

  @override
  State<_BudgetCategoryCard> createState() => _BudgetCategoryCardState();
}

class _BudgetCategoryCardState extends State<_BudgetCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.spring);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, size: 17, color: item.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.labelL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${item.remaining.toStringAsFixed(0)} disponible',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.spent.toStringAsFixed(0)}',
                      style: AppTypography.labelL.copyWith(
                        color: item.isWarning
                            ? AppColors.warning
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'de \$${item.limit.toStringAsFixed(0)}',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: item.color.withValues(alpha: 0.12),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: item.ratio * _anim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.isWarning
                              ? [AppColors.warning, AppColors.warning]
                              : [
                                  item.color.withValues(alpha: 0.7),
                                  item.color,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add budget button ─────────────────────────────────────────────────────────

class _AddBudgetButton extends StatelessWidget {
  const _AddBudgetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border:
              Border.all(color: AppColors.glassBorderStrong, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.emerald,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Añadir categoría',
              style: AppTypography.labelL.copyWith(color: AppColors.emerald),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add budget sheet ──────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({required this.onAdd});

  final void Function(BudgetItem) onAdd;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();

  IconData _selectedIcon = _kIconOptions.first;
  Color _selectedColor = _kColorOptions.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || limit == null || limit <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    widget.onAdd(BudgetItem(
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
      spent: 0,
      limit: limit,
    ));
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl + bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            Text(
              'Nueva categoría',
              style:
                  AppTypography.headingS.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Name ──────────────────────────────────────────────────────────
            _Label('Nombre'),
            const SizedBox(height: AppSpacing.sm),
            _TextField(
              controller: _nameCtrl,
              hint: 'ej. Gimnasio, Suscripciones…',
              icon: Icons.label_outline_rounded,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Icon picker ───────────────────────────────────────────────────
            _Label('Icono'),
            const SizedBox(height: AppSpacing.sm),
            _IconGrid(
              icons: _kIconOptions,
              selected: _selectedIcon,
              color: _selectedColor,
              onChanged: (ic) => setState(() => _selectedIcon = ic),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Color picker ──────────────────────────────────────────────────
            _Label('Color'),
            const SizedBox(height: AppSpacing.sm),
            _ColorGrid(
              colors: _kColorOptions,
              selected: _selectedColor,
              onChanged: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Limit ─────────────────────────────────────────────────────────
            _Label('Límite mensual'),
            const SizedBox(height: AppSpacing.sm),
            _TextField(
              controller: _limitCtrl,
              hint: 'ej. 200',
              icon: Icons.attach_money_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Preview ───────────────────────────────────────────────────────
            _BudgetPreviewRow(
              icon: _selectedIcon,
              color: _selectedColor,
              name: _nameCtrl.text.isEmpty ? 'Categoría' : _nameCtrl.text,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Submit ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.30),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'Agregar',
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet sub-widgets ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelM.copyWith(color: AppColors.textTertiary),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
        style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.icons,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final List<IconData> icons;
  final IconData selected;
  final Color color;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: icons.map((ic) {
        final isSelected = ic == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(ic);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.06),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Icon(
              ic,
              size: 20,
              color: isSelected ? color : AppColors.textTertiary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: colors.map((c) {
        final isSelected = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.50),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetPreviewRow extends StatelessWidget {
  const _BudgetPreviewRow({
    required this.icon,
    required this.color,
    required this.name,
  });

  final IconData icon;
  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            name,
            style: AppTypography.labelL.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          Text(
            'Vista previa',
            style: AppTypography.labelS.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

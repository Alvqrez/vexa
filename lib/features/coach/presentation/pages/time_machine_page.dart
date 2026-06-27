import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';

/// Vexa Time Machine: muestra el costo de oportunidad de un gasto.
/// No es una herramienta de inversión — es una reflexión financiera.
class TimeMachinePage extends ConsumerStatefulWidget {
  const TimeMachinePage({super.key});

  @override
  ConsumerState<TimeMachinePage> createState() => _TimeMachinePageState();
}

class _TimeMachinePageState extends ConsumerState<TimeMachinePage>
    with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController(text: '2000');
  double _annualRate = 0.08;
  int _selectedYears = 10;

  late AnimationController _anim;

  static const _accent = Color(0xFF7C5CFC);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..revealForward();
    _amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;

  double _futureValue(int years) =>
      _amount * math.pow(1 + _annualRate, years).toDouble();

  void _replay() => _anim.forward(from: 0);

  String _fmt(double v, String sym) {
    final String s = v >= 1000000
        ? '$sym${(v / 1000000).toStringAsFixed(2)}M'
        : v >= 10000
            ? '$sym${(v / 1000).toStringAsFixed(1)}k'
            : '$sym${v.toStringAsFixed(0)}';
    return pmask(s);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currency = ref.watch(currencySymbolProvider);
    final transactions = ref.watch(transactionsProvider);
    final cats = ref.watch(walletCategoriesProvider);

    // Mayores gastos de los últimos 90 días como puntos de partida
    final ninetyAgo = DateTime.now().subtract(const Duration(days: 90));
    final topExpenses = transactions
        .where((t) => !t.isIncome && t.date.isAfter(ninetyAgo))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final suggestions = topExpenses.take(3).toList();

    final future = _futureValue(_selectedYears);
    final growth = _amount > 0 ? (future / _amount - 1) * 100 : 0.0;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _accent.withValues(alpha: 0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // ── Top bar ───────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Haptics.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c.glass,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                    color: c.glassBorder, width: 0.5),
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  size: 18, color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Título ────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                _accent,
                                Color(0xFF5A3FD4),
                              ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.history_toggle_off_rounded,
                                size: 22, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vexa Time Machine',
                                    style: AppTypography.headingM
                                        .copyWith(color: c.textPrimary)),
                                Text('¿Cuánto vale realmente un gasto?',
                                    style: AppTypography.labelM
                                        .copyWith(color: c.textTertiary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Monto ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border:
                              Border.all(color: c.glassBorder, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Si en lugar de gastar…',
                                style: AppTypography.labelM
                                    .copyWith(color: c.textTertiary)),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onSubmitted: (_) => _replay(),
                              style: AppTypography.headingM.copyWith(
                                color: _accent,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                prefixText: currency,
                                prefixStyle: AppTypography.headingM.copyWith(
                                  color: _accent.withValues(alpha: 0.6),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                                hintText: '0',
                                hintStyle: AppTypography.headingM.copyWith(
                                    color: c.textTertiary, fontSize: 30),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (suggestions.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text('Prueba con tus mayores gastos recientes:',
                                  style: AppTypography.labelS
                                      .copyWith(color: c.textTertiary)),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: suggestions.map((t) {
                                  final cat =
                                      resolveCategory(t.category, cats);
                                  return GestureDetector(
                                    onTap: () {
                                      Haptics.selectionClick();
                                      _amountCtrl.text =
                                          t.amount.toStringAsFixed(0);
                                      _replay();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 11, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: cat.surface,
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.pillRadius),
                                        border: Border.all(
                                            color: cat.color
                                                .withValues(alpha: 0.3),
                                            width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(cat.icon,
                                              size: 12, color: cat.color),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${t.merchant} · ${_fmt(t.amount, currency)}',
                                            style: AppTypography.labelS
                                                .copyWith(
                                                    color: cat.color,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Horizonte ─────────────────────────────────
                      Row(
                        children: [1, 5, 10].map((y) {
                          final sel = y == _selectedYears;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Haptics.selectionClick();
                                setState(() => _selectedYears = y);
                                _replay();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                    right: y != 10 ? AppSpacing.sm : 0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _accent.withValues(alpha: 0.16)
                                      : c.glass,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius),
                                  border: Border.all(
                                    color: sel
                                        ? _accent.withValues(alpha: 0.5)
                                        : c.glassBorder,
                                    width: sel ? 1 : 0.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  y == 1 ? '1 año' : '$y años',
                                  style: AppTypography.labelL.copyWith(
                                    color:
                                        sel ? _accent : c.textSecondary,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Resultado ─────────────────────────────────
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) {
                          final t = Curves.easeOutCubic
                              .transform(_anim.value);
                          final displayed =
                              _amount + (future - _amount) * t;
                          return Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _accent.withValues(alpha: 0.16),
                                  _accent.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadiusL),
                              border: Border.all(
                                  color:
                                      _accent.withValues(alpha: 0.30),
                                  width: 0.5),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'podrían convertirse en',
                                  style: AppTypography.labelM
                                      .copyWith(color: c.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _fmt(displayed, currency),
                                    style:
                                        AppTypography.displayM.copyWith(
                                      color: _accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 44,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldSurface,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.pillRadius),
                                  ),
                                  child: Text(
                                    '+${growth.toStringAsFixed(0)}% en $_selectedYears ${_selectedYears == 1 ? 'año' : 'años'}',
                                    style: AppTypography.labelM.copyWith(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                SizedBox(
                                  height: 110,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _GrowthCurvePainter(
                                      progress: t,
                                      rate: _annualRate,
                                      years: _selectedYears,
                                      color: _accent,
                                      gridColor: c.glassBorder,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Tasa anual ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border:
                              Border.all(color: c.glassBorder, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rendimiento anual estimado',
                                    style: AppTypography.labelM
                                        .copyWith(color: c.textSecondary)),
                                Text(
                                  '${(_annualRate * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.labelL.copyWith(
                                      color: _accent,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: _accent,
                                inactiveTrackColor:
                                    _accent.withValues(alpha: 0.15),
                                thumbColor: _accent,
                                overlayColor:
                                    _accent.withValues(alpha: 0.15),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _annualRate,
                                min: 0.04,
                                max: 0.15,
                                divisions: 11,
                                onChanged: (v) =>
                                    setState(() => _annualRate = v),
                                onChangeEnd: (_) => _replay(),
                              ),
                            ),
                            Text(
                              'Referencia: un fondo indexado histórico ronda el 8–10% anual.',
                              style: AppTypography.labelS
                                  .copyWith(color: c.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Nota de reflexión ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.petroleumSurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                              color: AppColors.petroleum
                                  .withValues(alpha: 0.22),
                              width: 0.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.self_improvement_rounded,
                                size: 18, color: AppColors.petroleum),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Esto no es una recomendación de inversión. '
                                'Es una forma de ver tus gastos con otros ojos: '
                                'cada compra también tiene un costo en el futuro.',
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.petroleum,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),
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

// ── Curva de crecimiento compuesto ────────────────────────────────────────────

class _GrowthCurvePainter extends CustomPainter {
  const _GrowthCurvePainter({
    required this.progress,
    required this.rate,
    required this.years,
    required this.color,
    required this.gridColor,
  });

  final double progress;
  final double rate;
  final int years;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Líneas guía
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 2; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxVal = math.pow(1 + rate, years).toDouble();
    final path = Path()..moveTo(0, size.height);
    final visible = (size.width * progress).clamp(1.0, size.width);

    for (double x = 0; x <= visible; x += 2) {
      final yearAt = x / size.width * years;
      final val = math.pow(1 + rate, yearAt).toDouble();
      final y = size.height - (val - 1) / (maxVal - 1) * size.height * 0.92;
      path.lineTo(x, y);
    }

    // Área bajo la curva
    final area = Path.from(path)
      ..lineTo(visible, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Punto final
    if (progress > 0.05) {
      final yearAt = visible / size.width * years;
      final val = math.pow(1 + rate, yearAt).toDouble();
      final y =
          size.height - (val - 1) / (maxVal - 1) * size.height * 0.92;
      canvas.drawCircle(Offset(visible, y), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GrowthCurvePainter old) =>
      old.progress != progress || old.rate != rate || old.years != years;
}

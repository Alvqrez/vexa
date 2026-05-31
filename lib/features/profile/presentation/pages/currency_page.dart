import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  String _selected = 'EUR';

  static const _currencies = [
    _Currency('EUR', '€', 'Euro', 'Zona Euro'),
    _Currency('USD', '\$', 'Dólar estadounidense', 'Estados Unidos'),
    _Currency('MXN', '\$', 'Peso mexicano', 'México'),
    _Currency('GBP', '£', 'Libra esterlina', 'Reino Unido'),
    _Currency('JPY', '¥', 'Yen japonés', 'Japón'),
    _Currency('BRL', 'R\$', 'Real brasileño', 'Brasil'),
    _Currency('ARS', '\$', 'Peso argentino', 'Argentina'),
    _Currency('COP', '\$', 'Peso colombiano', 'Colombia'),
  ];

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _reveal(int i, int total, Widget child) {
    final start = i / total * 0.5;
    final end = (start + 0.55).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.gentle)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _stagger,
            curve: Interval(start, end, curve: AppCurves.spring))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ProfileSubBg(),
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
                      _reveal(0, 3, const _SubPageHeader(title: 'Moneda')),
                      const SizedBox(height: AppSpacing.sm),
                      _reveal(1, 3, Padding(
                        padding: const EdgeInsets.only(
                            left: 56, top: AppSpacing.xs),
                        child: Text(
                          'Elige la moneda principal para mostrar tus cifras.',
                          style: AppTypography.bodyS
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      )),
                      const SizedBox(height: AppSpacing.xl),
                      _reveal(2, 3, Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                              color: AppColors.glassBorder, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0;
                                i < _currencies.length;
                                i++) ...[
                              _CurrencyItem(
                                currency: _currencies[i],
                                selected:
                                    _currencies[i].code == _selected,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() =>
                                      _selected = _currencies[i].code);
                                },
                              ),
                              if (i < _currencies.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md),
                                  child: Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: AppColors.glassBorder),
                                ),
                            ],
                          ],
                        ),
                      )),
                      const SizedBox(height: AppSpacing.xxxl),
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

class _Currency {
  const _Currency(this.code, this.symbol, this.name, this.region);
  final String code;
  final String symbol;
  final String name;
  final String region;
}

class _CurrencyItem extends StatelessWidget {
  const _CurrencyItem({
    required this.currency,
    required this.selected,
    required this.onTap,
  });
  final _Currency currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.emeraldSurface
                    : AppColors.glassLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.emeraldGlow
                      : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  currency.symbol,
                  style: AppTypography.headingS.copyWith(
                    color: selected
                        ? AppColors.emerald
                        : AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.name,
                    style: AppTypography.labelL
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currency.code} · ${currency.region}',
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 13, color: AppColors.textInverse),
              )
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style:
                AppTypography.headingS.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ProfileSubBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.12),
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

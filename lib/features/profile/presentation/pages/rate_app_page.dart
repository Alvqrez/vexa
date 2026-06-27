import 'package:flutter/material.dart';
import 'package:vexa_finance/core/providers/settings_provider.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

class RateAppPage extends StatefulWidget {
  const RateAppPage({super.key});

  @override
  State<RateAppPage> createState() => _RateAppPageState();
}

class _RateAppPageState extends State<RateAppPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int _stars = 0;
  bool _submitted = false;
  final _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..revealForward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Widget _reveal(int i, int total, Widget child) {
    final start = i / total * 0.5;
    final end = (start + 0.6).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: AppCurves.gentle),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _stagger,
                curve: Interval(start, end, curve: AppCurves.spring),
              ),
            ),
        child: child,
      ),
    );
  }

  String get _starLabel {
    switch (_stars) {
      case 1:
        return 'Necesita mejoras';
      case 2:
        return 'Aceptable';
      case 3:
        return 'Buena';
      case 4:
        return 'Muy buena';
      case 5:
        return '¡Excelente!';
      default:
        return 'Toca para valorar';
    }
  }

  void _submit() {
    if (_stars == 0) return;
    Haptics.mediumImpact();
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          _ProfileSubBg(),
          SafeArea(
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
                      _reveal(
                        0,
                        4,
                        const _SubPageHeader(title: 'Valorar Vexa'),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      if (_submitted) ...[
                        _reveal(1, 4, _ThankYouCard()),
                      ] else ...[
                        // Star selector
                        _reveal(
                          1,
                          4,
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius,
                              ),
                              border: Border.all(
                                color: c.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // App icon placeholder
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.petroleum,
                                        AppColors.emeraldDim,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'V',
                                      style: AppTypography.headingM.copyWith(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 28,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  '¿Cómo va tu experiencia con Vexa?',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.headingS.copyWith(
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                // Stars row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (i) {
                                    final filled = i < _stars;
                                    return GestureDetector(
                                      onTap: () {
                                        Haptics.selectionClick();
                                        setState(() => _stars = i + 1);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: Icon(
                                            filled
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            key: ValueKey(filled),
                                            size: 40,
                                            color: filled
                                                ? AppColors.catEntertainment
                                                : c.textTertiary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _starLabel,
                                  style: AppTypography.labelM.copyWith(
                                    color: _stars > 0
                                        ? AppColors.catEntertainment
                                        : c.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Review text
                        _reveal(
                          2,
                          4,
                          Container(
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius,
                              ),
                              border: Border.all(
                                color: c.glassBorder,
                                width: 0.5,
                              ),
                            ),
                            child: TextField(
                              controller: _reviewController,
                              maxLines: 4,
                              style: AppTypography.bodyM.copyWith(
                                color: c.textPrimary,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(
                                  AppSpacing.lg,
                                ),
                                border: InputBorder.none,
                                hintText:
                                    'Cuéntanos qué mejorarías o qué te encanta… (opcional)',
                                hintStyle: AppTypography.bodyM.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        _reveal(
                          3,
                          4,
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                gradient: _stars > 0
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.emerald,
                                          AppColors.emeraldDim,
                                        ],
                                      )
                                    : null,
                                color: _stars == 0
                                    ? c.glass
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                                boxShadow: _stars > 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.emerald.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Enviar valoración',
                                textAlign: TextAlign.center,
                                style: AppTypography.labelL.copyWith(
                                  color: _stars > 0
                                      ? AppColors.textInverse
                                      : c.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ThankYouCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.emeraldSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.emeraldGlow, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.emerald,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '¡Gracias por tu valoración!',
            style: AppTypography.headingS.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu opinión nos ayuda a mejorar Vexa para todos.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyS.copyWith(color: context.colors.textSecondary),
          ),
        ],
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
    final c = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTypography.headingS.copyWith(color: c.textPrimary),
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
          Container(color: context.colors.background),
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

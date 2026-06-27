import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/providers/settings_provider.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int _logoTapCount = 0;

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

  void _onLogoTap() {
    if (kReleaseMode) return;
    _logoTapCount++;
    final remaining = 10 - _logoTapCount;
    if (remaining > 0 && remaining <= 3) {
      Haptics.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$remaining tap${remaining == 1 ? '' : 's'} para activar modo demo',
          style: AppTypography.labelM
              .copyWith(color: context.colors.textPrimary),
        ),
        backgroundColor: context.colors.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ));
    }
    if (_logoTapCount >= 10) {
      _logoTapCount = 0;
      _confirmDemoMode();
    }
  }

  Future<void> _confirmDemoMode() async {
    Haptics.mediumImpact();
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        ),
        title: Text('Modo demo',
            style: AppTypography.headingS.copyWith(color: c.textPrimary)),
        content: Text(
          'Se cargarán datos de ejemplo y se reemplazarán los datos actuales. '
          'Esta acción no se puede deshacer.\n\n'
          '⚠️ Solo disponible en modo debug.',
          style: AppTypography.bodyM.copyWith(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: AppTypography.labelM
                    .copyWith(color: c.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cargar demo',
                style: AppTypography.labelM
                    .copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(accountsProvider.notifier).seed();
      await ref.read(transactionsProvider.notifier).seed();
      await ref.read(subscriptionsProvider.notifier).seed();
      await ref.read(goalsProvider.notifier).seed();
      await ref.read(budgetProvider.notifier).seed();
      await ref.read(loansProvider.notifier).seed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Datos de demo cargados',
              style: AppTypography.labelM
                  .copyWith(color: context.colors.textPrimary)),
          backgroundColor: context.colors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ));
      }
    }
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
                      _reveal(0, 4, const _SubPageHeader(title: 'Sobre Vexa')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Logo hero — 10 taps activan modo demo (solo debug)
                      _reveal(
                        1,
                        4,
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _onLogoTap,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.petroleum,
                                        AppColors.emeraldDim,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.petroleum.withValues(
                                          alpha: 0.30,
                                        ),
                                        blurRadius: 32,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'V',
                                      style: AppTypography.headingM.copyWith(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Vexa Finance',
                                style: AppTypography.headingM.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Versión 1.0.0 (build 1)',
                                style: AppTypography.labelM.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Info card
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
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.info_outline_rounded,
                                color: AppColors.petroleum,
                                title: 'Versión',
                                value: '1.0.0',
                              ),
                              _Divider(),
                              _InfoRow(
                                icon: Icons.build_outlined,
                                color: c.textSecondary,
                                title: 'Build',
                                value: '1',
                              ),
                              _Divider(),
                              _InfoRow(
                                icon: Icons.smartphone_rounded,
                                color: AppColors.emerald,
                                title: 'Plataforma',
                                value: 'Flutter 3.x',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Legal links
                      _reveal(
                        3,
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
                          child: Column(
                            children: [
                              _LinkRow(
                                icon: Icons.privacy_tip_outlined,
                                color: AppColors.catTransport,
                                title: 'Política de privacidad',
                              ),
                              _Divider(),
                              _LinkRow(
                                icon: Icons.description_outlined,
                                color: AppColors.catShopping,
                                title: 'Términos de uso',
                              ),
                              _Divider(),
                              _LinkRow(
                                icon: Icons.code_rounded,
                                color: c.textTertiary,
                                title: 'Licencias de código abierto',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      _reveal(
                        3,
                        4,
                        Center(
                          child: Text(
                            'Hecho con ♥ para ti',
                            style: AppTypography.labelS.copyWith(
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.labelL.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelM.copyWith(color: context.colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
  });
  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.labelL.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(height: 1, thickness: 0.5, color: context.colors.glassBorder),
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
              color: context.colors.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.glassBorder, width: 0.5),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style: AppTypography.headingS.copyWith(color: context.colors.textPrimary),
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

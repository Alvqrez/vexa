import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  int? _expanded;

  static const _faqs = [
    _Faq(
      q: '¿Cómo agrego una transacción?',
      a: 'Pulsa el botón "+" en la esquina inferior derecha de la pantalla de inicio. Completa el importe, la descripción y la categoría.',
    ),
    _Faq(
      q: '¿Puedo agregar mis propias cuentas?',
      a: 'Sí. En la sección "Mis cuentas" del inicio puedes añadir, editar o eliminar cuentas bancarias y carteras.',
    ),
    _Faq(
      q: '¿Cómo funciona el presupuesto mensual?',
      a: 'Establece un límite mensual en la pestaña Presupuesto. Vexa trackea tus gastos y te avisa cuando te acercas al límite.',
    ),
    _Faq(
      q: '¿Mis datos están seguros?',
      a: 'Toda la información se almacena localmente en tu dispositivo. Vexa no comparte ni vende tus datos financieros.',
    ),
    _Faq(
      q: '¿Cómo cambio la moneda principal?',
      a: 'Ve a Perfil → Moneda y selecciona la divisa que prefieras. Las cifras se actualizarán de inmediato.',
    ),
    _Faq(
      q: '¿Puedo exportar mis transacciones?',
      a: 'La exportación a CSV y PDF estará disponible en una próxima actualización de Vexa.',
    ),
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
    final end = (start + 0.6).clamp(0.0, 1.0);
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
                      _reveal(
                          0, 3, const _SubPageHeader(title: 'Centro de ayuda')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Search hint
                      _reveal(
                        1,
                        3,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  size: 18, color: AppColors.textTertiary),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Buscar en la ayuda…',
                                style: AppTypography.bodyM
                                    .copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // FAQ accordion
                      _reveal(
                        2,
                        3,
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _faqs.length; i++) ...[
                                _FaqTile(
                                  faq: _faqs[i],
                                  expanded: _expanded == i,
                                  onTap: () => setState(() =>
                                      _expanded = _expanded == i ? null : i),
                                ),
                                if (i < _faqs.length - 1)
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
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Contact button
                      _reveal(
                        2,
                        3,
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.petroleumSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: AppColors.petroleum.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.support_agent_rounded,
                                  color: AppColors.petroleum, size: 24),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Contactar soporte',
                                style: AppTypography.labelL.copyWith(
                                    color: AppColors.petroleumLight,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Respuesta en menos de 24 h',
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.petroleum),
                              ),
                            ],
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

class _Faq {
  const _Faq({required this.q, required this.a});
  final String q;
  final String a;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });
  final _Faq faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(faq.q,
                      style: AppTypography.labelL
                          .copyWith(color: AppColors.textPrimary)),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded,
                      size: 18, color: AppColors.textTertiary),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(faq.a,
                    style: AppTypography.bodyS
                        .copyWith(color: AppColors.textSecondary)),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
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
        Text(
          title,
          style:
              AppTypography.headingS.copyWith(color: AppColors.textPrimary),
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

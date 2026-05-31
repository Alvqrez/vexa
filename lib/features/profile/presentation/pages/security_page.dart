import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;
  bool _biometrics = true;

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

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cambiar PIN',
            style: AppTypography.headingS
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Esta función estará disponible próximamente.',
          style:
              AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Entendido',
                style: AppTypography.labelL
                    .copyWith(color: AppColors.emerald)),
          ),
        ],
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
                      _reveal(0, 4, const _SubPageHeader(title: 'Seguridad')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Status banner
                      _reveal(
                        1,
                        4,
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSurface,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.emeraldGlow, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined,
                                  color: AppColors.emerald, size: 20),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cuenta protegida',
                                      style: AppTypography.labelL.copyWith(
                                          color: AppColors.emerald,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Todas las medidas de seguridad activas.',
                                      style: AppTypography.labelS.copyWith(
                                          color: AppColors.emerald
                                              .withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Options
                      _reveal(
                        2,
                        4,
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
                              _SecurityToggle(
                                icon: Icons.fingerprint_rounded,
                                color: AppColors.petroleum,
                                title: 'Autenticación biométrica',
                                subtitle: 'Usa huella o Face ID al entrar.',
                                value: _biometrics,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _biometrics = v);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: AppColors.glassBorder),
                              ),
                              _SecurityAction(
                                icon: Icons.pin_outlined,
                                color: AppColors.catTransport,
                                title: 'Cambiar PIN',
                                subtitle: 'Actualiza tu código de acceso.',
                                onTap: _showChangePinDialog,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                child: Divider(
                                    height: 1,
                                    thickness: 0.5,
                                    color: AppColors.glassBorder),
                              ),
                              _SecurityAction(
                                icon: Icons.lock_reset_rounded,
                                color: AppColors.warning,
                                title: 'Cambiar contraseña',
                                subtitle: 'Última modificación: hace 60 días.',
                                onTap: _showChangePinDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _reveal(
                        3,
                        4,
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: _SecurityAction(
                            icon: Icons.devices_outlined,
                            color: AppColors.textSecondary,
                            title: 'Sesiones activas',
                            subtitle: '1 dispositivo conectado.',
                            onTap: () {},
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

class _SecurityToggle extends StatelessWidget {
  const _SecurityToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelL
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.emerald,
            activeTrackColor: AppColors.emeraldSurface,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.glassLight,
          ),
        ],
      ),
    );
  }
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.labelL
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.labelS
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
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

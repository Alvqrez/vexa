import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import '../../../gamification/presentation/widgets/streak_widget.dart';
import '../../../education/presentation/pages/education_page.dart';
import 'personal_data_page.dart';
import 'currency_page.dart';
import 'notifications_page.dart';
import 'security_page.dart';
import 'help_center_page.dart';
import '../../../coach/presentation/pages/time_machine_page.dart';
import 'rate_app_page.dart';
import 'about_page.dart';
import 'settings_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../home/presentation/pages/customize_home_sheet.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  static const _sectionCount = 6;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..revealForward();
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
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(start, end, curve: AppCurves.spring),
        )),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
      children: [
        const _ProfileBg(),
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
                    _reveal(0, const _ProfilePageHeader()),
                    const SizedBox(height: AppSpacing.xxl),
                    _reveal(1, const _ProfileHeroCard()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(2, const StreakWidget()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _StatsRow()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const _AccountSettings()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(4, const _SupportSettings()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(5, const _UseSeedButton()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(5, const _SignOutButton()),
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
    ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _ProfileBg extends StatelessWidget {
  const _ProfileBg();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.06),
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

// ── Page header ───────────────────────────────────────────────────────────────

class _ProfilePageHeader extends StatelessWidget {
  const _ProfilePageHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canPop = Navigator.canPop(context);
    return Row(
      children: [
        if (canPop) ...[
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
                color: c.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            'Perfil',
            style: AppTypography.headingM.copyWith(
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends ConsumerWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.name.isEmpty ? 'Usuario' : profile.name;
    final displayEmail = profile.email.isEmpty ? 'Sin email' : profile.email;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: c.glass,
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          color: c.cardElevated,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Builder(builder: (context) {
                  final path = profile.photoPath;
                  final file = path != null ? File(path) : null;
                  final hasPhoto = file != null && file.existsSync();
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: hasPhoto
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.petroleum, AppColors.emeraldDim],
                            ),
                      image: hasPhoto
                          ? DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : Center(
                            child: Text(
                              profile.initial,
                              style: AppTypography.headingM.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                          ),
                  );
                }),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.cardElevated,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayEmail,
                    style: AppTypography.bodyS.copyWith(
                      color: c.textTertiary,
                    ),
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

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  String _fmtAmount(double v, String sym) =>
      v >= 1000 ? '$sym${(v / 1000).toStringAsFixed(1)}k' : '$sym${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final txns = ref.watch(transactionsProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final currency = ref.watch(currencySymbolProvider);

    final monthTxns = txns
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .length;
    final savingsRate = income > 0
        ? ((income - expenses) / income * 100).round().clamp(0, 100)
        : 0;
    final rawMonth = DateFormat('MMM', 'es').format(now);
    final monthLabel = rawMonth[0].toUpperCase() + rawMonth.substring(1);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            value: '$monthTxns',
            label: 'Transacciones',
            icon: Icons.receipt_long_outlined,
            color: AppColors.petroleum,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            value: _fmtAmount(expenses, currency),
            label: 'Gastos $monthLabel',
            icon: Icons.north_rounded,
            color: AppColors.negative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            value: '$savingsRate%',
            label: 'Tasa ahorro',
            icon: Icons.trending_up_rounded,
            color: AppColors.positive,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: c.glass,
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: AppTypography.headingS.copyWith(
                color: c.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings sections ─────────────────────────────────────────────────────────

class _AccountSettings extends ConsumerWidget {
  const _AccountSettings();

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _openCustomizeHome(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const CustomizeHomeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);
    return _SettingsSection(
      title: 'Mi cuenta',
      items: [
        _SettingsItem(
          icon: Icons.person_outline_rounded,
          label: 'Datos personales',
          color: AppColors.petroleum,
          onTap: () => _push(context, const PersonalDataPage()),
        ),
        _SettingsItem(
          icon: Icons.dashboard_customize_rounded,
          label: 'Personalizar inicio',
          color: AppColors.catEntertainment,
          onTap: () => _openCustomizeHome(context),
        ),
        _SettingsItem(
          icon: Icons.euro_rounded,
          label: 'Moneda',
          trailing: currencyCode,
          color: AppColors.emerald,
          onTap: () => _push(context, const CurrencyPage()),
        ),
        _SettingsItem(
          icon: Icons.notifications_outlined,
          label: 'Notificaciones',
          color: AppColors.warning,
          onTap: () => _push(context, const NotificationsPage()),
        ),
        _SettingsItem(
          icon: Icons.lock_outline_rounded,
          label: 'Seguridad',
          color: AppColors.catTransport,
          onTap: () => _push(context, const SecurityPage()),
        ),
        _SettingsItem(
          icon: Icons.settings_outlined,
          label: 'Configuración',
          color: context.colors.textSecondary,
          onTap: () => _push(context, const SettingsPage()),
        ),
      ],
    );
  }
}

class _SupportSettings extends StatelessWidget {
  const _SupportSettings();

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Soporte',
      items: [
        _SettingsItem(
          icon: Icons.school_outlined,
          label: 'Educación financiera',
          color: AppColors.petroleum,
          onTap: () => _push(context, const EducationPage()),
        ),
        _SettingsItem(
          icon: Icons.history_toggle_off_rounded,
          label: 'Vexa Time Machine',
          color: const Color(0xFF7C5CFC),
          onTap: () => _push(context, const TimeMachinePage()),
        ),
        _SettingsItem(
          icon: Icons.help_outline_rounded,
          label: 'Preguntas frecuentes',
          color: AppColors.catShopping,
          onTap: () => _push(context, const HelpCenterPage()),
        ),
        _SettingsItem(
          icon: Icons.star_outline_rounded,
          label: 'Valorar Vexa',
          color: AppColors.catEntertainment,
          onTap: () => _push(context, const RateAppPage()),
        ),
        _SettingsItem(
          icon: Icons.info_outline_rounded,
          label: 'Sobre Vexa',
          trailing: '1.0.0',
          color: context.colors.textTertiary,
          onTap: () => _push(context, const AboutPage()),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            title,
            style: AppTypography.headingS.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: c.glassBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: c.glassBorder,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
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
                label,
                style: AppTypography.labelL.copyWith(
                  color: c.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  trailing!,
                  style: AppTypography.labelM.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: c.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Use seed ──────────────────────────────────────────────────────────────────

class _UseSeedButton extends ConsumerWidget {
  const _UseSeedButton();

  Future<void> _load(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.colors;
        return AlertDialog(
          backgroundColor: cc.cardElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cargar datos de ejemplo',
              style: AppTypography.headingS.copyWith(color: cc.textPrimary)),
          content: Text(
            'Se cargarán cuentas, transacciones, préstamos, suscripciones, metas y presupuestos de muestra. Los datos actuales serán reemplazados.',
            style: AppTypography.bodyM.copyWith(color: cc.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: AppTypography.labelL.copyWith(color: cc.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Cargar',
                  style: AppTypography.labelL.copyWith(color: AppColors.petroleum)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    Haptics.mediumImpact();
    await ref.read(accountsProvider.notifier).seed();
    await ref.read(transactionsProvider.notifier).seed();
    await ref.read(subscriptionsProvider.notifier).seed();
    await ref.read(goalsProvider.notifier).seed();
    await ref.read(budgetProvider.notifier).seed();
    await ref.read(loansProvider.notifier).seed();
    if (!context.mounted) return;
    final sc = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Datos de ejemplo cargados.',
          style: AppTypography.labelM.copyWith(color: sc.textPrimary)),
      backgroundColor: sc.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _load(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.petroleumSurface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.petroleum.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.petroleumLight, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Usar seed',
                style: AppTypography.labelL
                    .copyWith(color: AppColors.petroleumLight)),
          ],
        ),
      ),
    );
  }
}

// ── Sign out ──────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.colors;
        return AlertDialog(
          backgroundColor: cc.cardElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cerrar sesión',
            style: AppTypography.headingS.copyWith(color: cc.textPrimary),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: AppTypography.bodyM.copyWith(color: cc.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: AppTypography.labelL
                      .copyWith(color: cc.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Cerrar sesión',
                  style: AppTypography.labelL.copyWith(color: AppColors.negative)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const LoginPage(),
        transitionsBuilder: (_, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.negativeSurface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.negative.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.negative,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Cerrar sesión',
              style: AppTypography.labelL.copyWith(
                color: AppColors.negative,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../gamification/presentation/widgets/streak_widget.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../gamification/presentation/pages/achievements_page.dart';
import '../../../education/presentation/pages/education_page.dart';
import 'personal_data_page.dart';
import 'currency_page.dart';
import 'notifications_page.dart';
import 'security_page.dart';
import 'help_center_page.dart';
import 'rate_app_page.dart';
import 'about_page.dart';
import 'settings_page.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    const SizedBox(height: AppSpacing.md),
                    _reveal(2, _AchievementsSummary(
                      unlockedCount: ref.watch(unlockedAchievementsProvider).length,
                      totalCount: ref.watch(achievementsProvider).length,
                      xp: ref.watch(totalXpProvider),
                    )),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(3, const _StatsRow()),
                    const SizedBox(height: AppSpacing.xl),
                    _reveal(4, const _AccountSettings()),
                    const SizedBox(height: AppSpacing.md),
                    _reveal(4, const _SupportSettings()),
                    const SizedBox(height: AppSpacing.xl),
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
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
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
                color: AppColors.glassLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary,
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
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context) {
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
            colors: [
              Color(0xFF1C1C32),
              Color(0xFF141428),
              Color(0xFF0F0F1E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.petroleum.withValues(alpha: 0.12),
              blurRadius: 48,
              spreadRadius: -6,
              offset: const Offset(0, 20),
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
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.petroleum, AppColors.emeraldDim],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'L',
                      style: AppTypography.headingM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
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
                        color: const Color(0xFF141428),
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
                    'Leonardo Alvarez',
                    style: AppTypography.headingS.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'leoo.azdz@gmail.com',
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.petroleumSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: AppColors.petroleum.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'VEXA PREMIUM',
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.petroleumLight,
                      ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            value: '7',
            label: 'Transacciones',
            icon: Icons.receipt_long_outlined,
            color: AppColors.petroleum,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            value: '\$249',
            label: 'Gastos mayo',
            icon: Icons.north_rounded,
            color: AppColors.negative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MiniStat(
            value: '86%',
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
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
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings sections ─────────────────────────────────────────────────────────

class _AccountSettings extends StatelessWidget {
  const _AccountSettings();

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          icon: Icons.euro_rounded,
          label: 'Moneda',
          trailing: 'EUR',
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
          color: AppColors.textSecondary,
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
          icon: Icons.help_outline_rounded,
          label: 'Centro de ayuda',
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
          color: AppColors.textTertiary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            title,
            style: AppTypography.headingS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
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
                      color: AppColors.glassBorder,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
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
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  trailing!,
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievements summary ──────────────────────────────────────────────────────

class _AchievementsSummary extends StatelessWidget {
  const _AchievementsSummary({
    required this.unlockedCount,
    required this.totalCount,
    required this.xp,
  });

  final int unlockedCount;
  final int totalCount;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AchievementsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.catEntertainment.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.catEntertainment.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: AppColors.catEntertainment,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logros',
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$unlockedCount/$totalCount desbloqueados · $xp XP',
                    style: AppTypography.labelS
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign out ──────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Cerrar sesión',
          style: AppTypography.headingS.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.labelL
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar sesión',
              style:
                  AppTypography.labelL.copyWith(color: AppColors.negative),
            ),
          ),
        ],
      ),
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

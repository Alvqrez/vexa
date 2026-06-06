import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/utils/export_utils.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../splash/presentation/pages/splash_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  bool _haptics = true;
  bool _analytics = false;
  String _language = 'Español';

  static const _languages = ['Español', 'English', 'Português', 'Français'];

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final haptics = await LocalPrefsService.getBool('settings_haptics', defaultValue: true);
    final analytics = await LocalPrefsService.getBool('settings_analytics', defaultValue: false);
    final lang = await LocalPrefsService.getString('settings_language') ?? 'Español';
    if (!mounted) return;
    setState(() {
      _haptics = haptics;
      _analytics = analytics;
      _language = lang;
    });
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

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagePicker(
        selected: _language,
        languages: _languages,
        onSelect: (lang) {
          HapticFeedback.selectionClick();
          setState(() => _language = lang);
          LocalPrefsService.setString('settings_language', lang);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showResetConfirm() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.colors;
        return AlertDialog(
          backgroundColor: cc.cardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reiniciar todos los datos',
              style: AppTypography.headingS
                  .copyWith(color: cc.textPrimary)),
          content: Text(
            'Se eliminarán todas tus transacciones y se restaurarán las cuentas a sus valores iniciales. Esta acción no se puede deshacer.',
            style: AppTypography.bodyM
                .copyWith(color: cc.textSecondary),
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
              child: Text('Reiniciar',
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.negative)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.heavyImpact();

    await ref.read(transactionsProvider.notifier).reset();
    await ref.read(streakProvider.notifier).reset();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Datos reiniciados correctamente.',
            style: AppTypography.labelM.copyWith(color: c.textPrimary)),
        backgroundColor: c.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      ),
    );
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.colors;
        return AlertDialog(
          backgroundColor: cc.cardElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Eliminar cuenta',
              style: AppTypography.headingS
                  .copyWith(color: cc.textPrimary)),
          content: Text(
            'Esta acción es irreversible. Se borrarán todos tus datos y volverás a la pantalla inicial.',
            style: AppTypography.bodyM
                .copyWith(color: cc.textSecondary),
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
              child: Text('Eliminar',
                  style: AppTypography.labelL
                      .copyWith(color: AppColors.negative)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.heavyImpact();

    try {
      // Reset in-memory state
      await ref.read(transactionsProvider.notifier).reset();
      await ref.read(streakProvider.notifier).reset();

      // Clear ALL remaining Isar collections
      final isar = ref.read(isarProvider);
      await isar.writeTxn(() async {
        await isar.isarWalletCategorys.clear();
        await isar.isarSubscriptions.clear();
        await isar.isarFinancialGoals.clear();
        await isar.isarBudgetItems.clear();
        await isar.isarAccounts.clear();
      });

      // Wipe all local prefs (clears onboarding_done, transactions_seeded, currency, etc.)
      await LocalPrefsService.clear();

      // Delete profile photo file so it doesn't get auto-restored
      try {
        final dir = await getApplicationDocumentsDirectory();
        final photo = File('${dir.path}/profile_photo.jpg');
        if (photo.existsSync()) await photo.delete();
      } catch (_) {}

      // Clear profile notifier state (keeps photo from reappearing in-session)
      ref.read(userProfileProvider.notifier).clearProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar datos. Inténtalo de nuevo.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const SplashPage(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          _SettingsBg(),
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
                      _reveal(0, 5, const _SubPageHeader(title: 'Configuración')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Apariencia
                      _reveal(
                        1,
                        5,
                        _SettingsSection(
                          title: 'Apariencia',
                          items: [
                            _ToggleItem(
                              icon: Icons.dark_mode_outlined,
                              color: AppColors.petroleum,
                              title: 'Modo oscuro',
                              subtitle: 'Tema oscuro de la app.',
                              value: ref.watch(themeModeProvider) == ThemeMode.dark,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                final mode = v ? ThemeMode.dark : ThemeMode.light;
                                ref.read(themeModeProvider.notifier).state = mode;
                                saveThemeMode(mode);
                              },
                            ),
                            _ActionItem(
                              icon: Icons.language_rounded,
                              color: AppColors.catTransport,
                              title: 'Idioma',
                              trailing: _language,
                              onTap: _showLanguagePicker,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Accesibilidad
                      _reveal(
                        2,
                        5,
                        _SettingsSection(
                          title: 'Accesibilidad',
                          items: [
                            _ToggleItem(
                              icon: Icons.vibration_rounded,
                              color: AppColors.catEntertainment,
                              title: 'Vibración y hápticos',
                              subtitle: 'Feedback táctil en acciones.',
                              value: _haptics,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                setState(() => _haptics = v);
                                LocalPrefsService.setBool('settings_haptics', v);
                              },
                            ),
                            _ToggleItem(
                              icon: Icons.animation_rounded,
                              color: AppColors.catShopping,
                              title: 'Animaciones',
                              subtitle:
                                  'Transiciones y efectos visuales.',
                              value: ref.watch(animationsEnabledProvider),
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                ref.read(animationsEnabledProvider.notifier).state = v;
                                LocalPrefsService.setBool('settings_animations', v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Privacidad
                      _reveal(
                        3,
                        5,
                        _SettingsSection(
                          title: 'Privacidad y datos',
                          items: [
                            _ToggleItem(
                              icon: Icons.visibility_off_outlined,
                              color: AppColors.negative,
                              title: 'Ocultar montos',
                              subtitle: 'Muestra asteriscos en lugar de valores.',
                              value: ref.watch(hideAmountsProvider),
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                ref.read(hideAmountsProvider.notifier).state = v;
                                LocalPrefsService.setBool('settings_hide_amounts', v);
                              },
                            ),
                            _ToggleItem(
                              icon: Icons.analytics_outlined,
                              color: c.textSecondary,
                              title: 'Enviar analíticas',
                              subtitle:
                                  'Ayuda a mejorar Vexa de forma anónima.',
                              value: _analytics,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                setState(() => _analytics = v);
                                LocalPrefsService.setBool('settings_analytics', v);
                              },
                            ),
                            _ActionItem(
                              icon: Icons.download_outlined,
                              color: AppColors.emerald,
                              title: 'Exportar mis datos (CSV)',
                              onTap: () async {
                                final txns = ref.read(transactionsProvider);
                                final accs = ref.read(accountsProvider);
                                final count = await ExportUtils.copyToClipboard(txns, accounts: accs);
                                if (!context.mounted) return;
                                final sc = context.colors;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$count transacciones copiadas al portapapeles.',
                                      style: AppTypography.labelM.copyWith(
                                          color: sc.textPrimary),
                                    ),
                                    backgroundColor: sc.card,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.cardRadius),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Zona peligrosa
                      _reveal(
                        4,
                        5,
                        Column(
                          children: [
                            // Reiniciar datos
                            GestureDetector(
                              onTap: _showResetConfirm,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800)
                                        .withValues(alpha: 0.25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.restart_alt_rounded,
                                        color: Color(0xFFFF9800), size: 18),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Reiniciar todos los datos',
                                      style: AppTypography.labelL.copyWith(
                                          color: const Color(0xFFFF9800)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Eliminar cuenta
                            GestureDetector(
                              onTap: _showDeleteConfirm,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.negativeSurface,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius),
                                  border: Border.all(
                                    color: AppColors.negative
                                        .withValues(alpha: 0.20),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delete_outline_rounded,
                                        color: AppColors.negative, size: 18),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Eliminar cuenta',
                                      style: AppTypography.labelL.copyWith(
                                          color: AppColors.negative),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

// ── Section widget ────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

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
            style: AppTypography.labelL.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
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
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
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
                        horizontal: AppSpacing.md),
                    child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: c.glassBorder),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Toggle item ───────────────────────────────────────────────────────────────

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
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
    final c = context.colors;
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
                        .copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.labelS
                        .copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.emerald,
            activeTrackColor: AppColors.emeraldSurface,
            inactiveThumbColor: c.textTertiary,
            inactiveTrackColor: c.glass,
          ),
        ],
      ),
    );
  }
}

// ── Action item ───────────────────────────────────────────────────────────────

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              child: Text(title,
                  style: AppTypography.labelL
                      .copyWith(color: c.textPrimary)),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(trailing!,
                    style: AppTypography.labelM
                        .copyWith(color: c.textTertiary)),
              ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Language picker sheet ─────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.selected,
    required this.languages,
    required this.onSelect,
  });
  final String selected;
  final List<String> languages;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 32),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: c.glassBorderStrong, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.glassMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Idioma',
                style: AppTypography.headingS
                    .copyWith(color: c.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(
                height: 1, thickness: 0.5, color: c.glassBorder),
          ),
          for (final lang in languages)
            GestureDetector(
              onTap: () => onSelect(lang),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(lang,
                          style: AppTypography.labelL
                              .copyWith(color: c.textPrimary)),
                    ),
                    if (lang == selected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 13, color: AppColors.textInverse),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
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
            child: Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: c.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title,
          style:
              AppTypography.headingS.copyWith(color: c.textPrimary),
        ),
      ],
    );
  }
}

class _SettingsBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.10),
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

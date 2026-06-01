import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/export_utils.dart';
import '../../../home/presentation/providers/home_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  // State
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
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar cuenta',
            style: AppTypography.headingS
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Esta acción es irreversible. Se borrarán todos tus datos.',
          style: AppTypography.bodyM
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: AppTypography.labelL
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Eliminar',
                style: AppTypography.labelL
                    .copyWith(color: AppColors.negative)),
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
                                ref.read(themeModeProvider.notifier).state =
                                    v ? ThemeMode.dark : ThemeMode.light;
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
                                ref
                                    .read(animationsEnabledProvider.notifier)
                                    .state = v;
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
                              },
                            ),
                            _ToggleItem(
                              icon: Icons.analytics_outlined,
                              color: AppColors.textSecondary,
                              title: 'Enviar analíticas',
                              subtitle:
                                  'Ayuda a mejorar Vexa de forma anónima.',
                              value: _analytics,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                setState(() => _analytics = v);
                              },
                            ),
                            _ActionItem(
                              icon: Icons.download_outlined,
                              color: AppColors.emerald,
                              title: 'Exportar mis datos (CSV)',
                              onTap: () async {
                                final txns = ref.read(transactionsProvider);
                                final count = await ExportUtils.copyToClipboard(txns);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$count transacciones copiadas al portapapeles.',
                                      style: AppTypography.labelM.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                    backgroundColor: AppColors.card,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            title,
            style: AppTypography.labelL.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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
                        color: AppColors.glassBorder),
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
                      .copyWith(color: AppColors.textPrimary)),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(trailing!,
                    style: AppTypography.labelM
                        .copyWith(color: AppColors.textTertiary)),
              ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 32),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: AppColors.glassBorderStrong, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Idioma',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(
                height: 1, thickness: 0.5, color: AppColors.glassBorder),
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
                              .copyWith(color: AppColors.textPrimary)),
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

class _SettingsBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: AppColors.background),
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

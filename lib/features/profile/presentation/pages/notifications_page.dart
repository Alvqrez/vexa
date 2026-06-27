import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/services/notification_service.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _stagger;

  bool _dailyTip = true;
  bool _logReminder = true;
  bool _budgetAlerts = true;
  bool _subscriptionAlerts = true;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..revealForward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dailyTip =
        await LocalPrefsService.getBool('notif_daily_tip', defaultValue: true);
    final logReminder = await LocalPrefsService.getBool('notif_log_reminder',
        defaultValue: true);
    final budgetAlerts = await LocalPrefsService.getBool('notif_budget_alerts',
        defaultValue: true);
    final subscriptionAlerts = await LocalPrefsService.getBool(
        'notif_subscription_alerts',
        defaultValue: true);
    if (!mounted) return;
    setState(() {
      _dailyTip = dailyTip;
      _logReminder = logReminder;
      _budgetAlerts = budgetAlerts;
      _subscriptionAlerts = subscriptionAlerts;
    });
  }

  Future<void> _save(String key, bool value) async {
    // Request iOS permissions when the user enables any notification type.
    if (value) await NotificationService.requestPermissions();
    await LocalPrefsService.setBool(key, value);
    // Sync the shared prefs provider so the rest of the app reacts.
    ref.read(notifPrefsProvider.notifier).reload();

    // Scheduled notifications take effect immediately.
    if (key == 'notif_daily_tip') {
      if (value) {
        await NotificationService.scheduleDailyTip();
      } else {
        await NotificationService.cancelDailyTip();
      }
    }
    if (key == 'notif_log_reminder') {
      if (value) {
        await NotificationService.scheduleLogReminder();
      } else {
        await NotificationService.cancelLogReminder();
      }
    }
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
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),
                      _reveal(
                          0, 3, const _SubPageHeader(title: 'Notificaciones')),
                      const SizedBox(height: AppSpacing.xxl),

                      // Recordatorios
                      _reveal(
                          0,
                          3,
                          _NotifSection(
                            title: 'Recordatorios',
                            footnote:
                                'El tip llega a las 9:00 y el recordatorio a las 21:00.',
                            items: [
                              _NotifItem(
                                icon: Icons.lightbulb_outline_rounded,
                                color: AppColors.warning,
                                title: 'Tip financiero diario',
                                subtitle:
                                    'Un consejo para mejorar tus finanzas cada día.',
                                value: _dailyTip,
                                onChanged: (v) {
                                  Haptics.selectionClick();
                                  setState(() => _dailyTip = v);
                                  _save('notif_daily_tip', v);
                                },
                              ),
                              _NotifItem(
                                icon: Icons.edit_note_rounded,
                                color: AppColors.petroleum,
                                title: 'Recuérdame registrar gastos',
                                subtitle:
                                    'Aviso diario para anotar tus movimientos.',
                                value: _logReminder,
                                onChanged: (v) {
                                  Haptics.selectionClick();
                                  setState(() => _logReminder = v);
                                  _save('notif_log_reminder', v);
                                },
                              ),
                            ],
                          )),
                      const SizedBox(height: AppSpacing.lg),

                      // Alertas
                      _reveal(
                          1,
                          3,
                          _NotifSection(
                            title: 'Alertas',
                            footnote:
                                'Se revisan al abrir la app, una vez al día.',
                            items: [
                              _NotifItem(
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.negative,
                                title: 'Excediste tu presupuesto',
                                subtitle:
                                    'Avisa al alcanzar el 80% y al pasarte del límite.',
                                value: _budgetAlerts,
                                onChanged: (v) {
                                  Haptics.selectionClick();
                                  setState(() => _budgetAlerts = v);
                                  _save('notif_budget_alerts', v);
                                },
                              ),
                              _NotifItem(
                                icon: Icons.event_repeat_rounded,
                                color: AppColors.emerald,
                                title: 'Suscripción por vencer',
                                subtitle:
                                    'Avisa cuando un cobro está a 3 días o menos.',
                                value: _subscriptionAlerts,
                                onChanged: (v) {
                                  Haptics.selectionClick();
                                  setState(() => _subscriptionAlerts = v);
                                  _save('notif_subscription_alerts', v);
                                },
                              ),
                            ],
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

class _NotifItem {
  const _NotifItem({
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
}

class _NotifSection extends StatelessWidget {
  const _NotifSection({
    required this.title,
    required this.items,
    this.footnote,
  });
  final String title;
  final List<_NotifItem> items;
  final String? footnote;

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
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _NotifRow(item: items[i]),
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
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              footnote!,
              style: AppTypography.labelS.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.item});
  final _NotifItem item;

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
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 17, color: item.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTypography.labelL
                        .copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: AppTypography.labelS
                        .copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch.adaptive(
            value: item.value,
            onChanged: item.onChanged,
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

class _ProfileSubBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: c.background),
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

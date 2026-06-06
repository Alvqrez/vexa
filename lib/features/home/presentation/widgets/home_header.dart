import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../gamification/presentation/pages/streak_page.dart';
import '../providers/home_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final streak = ref.watch(streakProvider);
    final profile = ref.watch(userProfileProvider);
    final displayName = profile.firstName.isEmpty ? 'Usuario' : profile.firstName;
    const flameColor = Color(0xFFFF6B35);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTypography.labelM.copyWith(
                  color: c.textTertiary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: AppTypography.headingM.copyWith(
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Streak pill
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StreakPage()),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: flameColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: flameColor.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 15,
                  color: flameColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${streak.currentStreak}',
                  style: AppTypography.labelM.copyWith(
                    color: flameColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const _NotificationButton(),
        const SizedBox(width: AppSpacing.md),
        const _AvatarButton(),
      ],
    );
  }
}

// ── Notification button with dropdown ────────────────────────────────────────

class _NotificationButton extends ConsumerStatefulWidget {
  const _NotificationButton();

  @override
  ConsumerState<_NotificationButton> createState() =>
      _NotificationButtonState();
}

class _NotificationButtonState extends ConsumerState<_NotificationButton> {
  final _link = LayerLink();
  final _overlayController = OverlayPortalController();
  final _dismissed = <String>{};

  @override
  void initState() {
    super.initState();
    _loadClearedState();
  }

  Future<void> _loadClearedState() async {
    final clearedDay = await LocalPrefsService.getInt('notif_cleared_day');
    final today = _todayInt();
    if (clearedDay == today) {
      if (mounted) setState(() => _dismissed.addAll(['n1', 'n2']));
    }
  }

  int _todayInt() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    _overlayController.toggle();
  }

  void _dismissOne(String id) {
    HapticFeedback.selectionClick();
    setState(() => _dismissed.add(id));
    if (_dismissed.containsAll(['n1', 'n2'])) {
      LocalPrefsService.setInt('notif_cleared_day', _todayInt());
    }
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _dismissed.addAll(['n1', 'n2']);
    });
    LocalPrefsService.setInt('notif_cleared_day', _todayInt());
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prediction = ref.watch(predictionProvider);
    final txns = ref.watch(transactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final now = DateTime.now();
    final hasTransactionsThisMonth = txns.any(
        (t) => t.date.month == now.month && t.date.year == now.year);

    final allNotifs = [
      if (hasTransactionsThisMonth)
        _Notif(
          id: 'n1',
          icon: Icons.auto_graph_rounded,
          color: prediction.isOnTrack ? AppColors.emerald : AppColors.negative,
          title: 'Predicción del mes',
          body: prediction.isOnTrack
              ? 'Vas bien. Ahorro estimado: +$currency${prediction.predictedSavings.toStringAsFixed(0)}'
              : 'Atención: gastos superarán ingresos este mes.',
          time: 'hoy',
          unread: true,
        ),
    ];

    final notifications =
        allNotifs.where((n) => !_dismissed.contains(n.id)).toList();

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => _NotifDropdown(
          link: _link,
          notifications: notifications,
          onDismiss: _overlayController.hide,
          onDismissOne: _dismissOne,
          onClear: notifications.isEmpty ? null : _clearAll,
        ),
        child: GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: c.textSecondary,
                  size: 20,
                ),
                if (notifications.any((n) => n.unread))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Returns (tipText, icon, color) for today's tip
}

class _Notif {
  const _Notif({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class _NotifDropdown extends StatelessWidget {
  const _NotifDropdown({
    required this.link,
    required this.notifications,
    required this.onDismiss,
    required this.onDismissOne,
    this.onClear,
  });

  final LayerLink link;
  final List<_Notif> notifications;
  final VoidCallback onDismiss;
  final ValueChanged<String> onDismissOne;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(-240, 48),
          child: Material(
            color: Colors.transparent,
            child: _DropdownCard(
              notifications: notifications,
              onDismissOne: onDismissOne,
              onClear: onClear,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownCard extends StatelessWidget {
  const _DropdownCard({
    required this.notifications,
    required this.onDismissOne,
    this.onClear,
  });
  final List<_Notif> notifications;
  final ValueChanged<String> onDismissOne;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unreadCount = notifications.where((n) => n.unread).length;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorderStrong, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificaciones',
                  style: AppTypography.headingS.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.pillRadius),
                          border: Border.all(
                              color: AppColors.emeraldGlow, width: 0.5),
                        ),
                        child: Text(
                          '$unreadCount nuevas',
                          style: AppTypography.labelS
                              .copyWith(color: AppColors.emerald),
                        ),
                      ),
                    if (onClear != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onClear,
                        child: Text(
                          'Limpiar',
                          style: AppTypography.labelS.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(
                height: 1, thickness: 0.5, color: c.glassBorder),
          ),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 28, color: c.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Sin notificaciones',
                    style: AppTypography.labelM
                        .copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < notifications.length; i++) ...[
              _NotifRow(notif: notifications[i], onDismiss: onDismissOne),
              if (i < notifications.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: c.glassBorder),
                ),
            ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.notif, required this.onDismiss});
  final _Notif notif;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: notif.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(notif.icon, size: 16, color: notif.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: AppTypography.labelL.copyWith(
                          color: c.textPrimary,
                          fontWeight: notif.unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (notif.unread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onDismiss(notif.id),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: c.glass,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 11, color: c.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notif.body,
                  style: AppTypography.labelS
                      .copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  notif.time,
                  style: AppTypography.labelS
                      .copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar button → Profile page ─────────────────────────────────────────────

class _AvatarButton extends ConsumerWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final path = profile.photoPath;
    final file = path != null ? File(path) : null;
    final hasPhoto = file != null && file.existsSync();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: hasPhoto
              ? Image.file(file, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.petroleum, AppColors.emeraldDim],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      profile.initial,
                      style: AppTypography.labelL.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/budget_notifications_provider.dart';

class BudgetNotificationBanner extends ConsumerWidget {
  const BudgetNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(activeBudgetNotificationsProvider);

    if (notifications.isEmpty) return const SizedBox.shrink();

    final notification = notifications.first;

    final (bgColor, borderColor, textColor) = switch (notification.type) {
      BudgetNotificationType.warning => (
        AppColors.warningSurface,
        AppColors.warning,
        AppColors.warning,
      ),
      BudgetNotificationType.critical => (
        AppColors.warningSurface,
        AppColors.warning,
        AppColors.warning,
      ),
      BudgetNotificationType.overspent => (
        AppColors.negativeSurface,
        AppColors.negative,
        AppColors.negative,
      ),
    };

    final icon = switch (notification.type) {
      BudgetNotificationType.warning => Icons.info_outline_rounded,
      BudgetNotificationType.critical => Icons.warning_rounded,
      BudgetNotificationType.overspent => Icons.error_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.budgetName,
                  style: AppTypography.labelM.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${notification.message} • ${notification.percentage.toStringAsFixed(0)}%',
                  style: AppTypography.labelS.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(budgetNotificationsProvider.notifier).dismiss(notification.id);
            },
            child: Icon(
              Icons.close_rounded,
              color: textColor.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

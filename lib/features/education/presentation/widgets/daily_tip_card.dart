import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/financial_tip.dart';
import '../pages/tip_detail_page.dart';

class DailyTipCard extends ConsumerWidget {
  const DailyTipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tip = FinancialTips.daily;
    final color = tip.category.color;

    return GestureDetector(
      onTap: () {
        Haptics.lightImpact();
        _showFullTip(context, tip);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.20), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(tip.category.icon, size: 17, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Consejo del día',
                        style: AppTypography.eyebrow.copyWith(color: color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.pillRadius,
                          ),
                        ),
                        child: Text(
                          tip.category.label,
                          style: AppTypography.labelS.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tip.title,
                    style: AppTypography.labelL.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tip.content,
                    style: AppTypography.labelS.copyWith(
                      color: c.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullTip(BuildContext context, FinancialTip tip) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TipDetailPage(tip: tip)));
  }
}

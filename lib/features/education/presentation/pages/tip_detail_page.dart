import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/financial_tip.dart';

class TipDetailPage extends StatelessWidget {
  const TipDetailPage({super.key, required this.tip});
  final FinancialTip tip;

  @override
  Widget build(BuildContext context) {
    final color = tip.category.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding, AppSpacing.lg,
                    AppSpacing.screenPadding, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.glassLight,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: AppColors.glassBorder, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tip.category.icon, size: 12, color: color),
                          const SizedBox(width: 5),
                          Text(tip.category.label,
                              style: AppTypography.labelS.copyWith(
                                  color: color, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding, AppSpacing.xxl,
                    AppSpacing.screenPadding, AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(tip.category.icon, size: 28, color: color),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      tip.title,
                      style: AppTypography.headingM
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(
                            color: color.withValues(alpha: 0.15), width: 0.5),
                      ),
                      child: Text(
                        tip.content,
                        style: AppTypography.bodyM.copyWith(
                            color: AppColors.textSecondary, height: 1.7),
                      ),
                    ),
                    if (tip.steps.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Pasos concretos',
                            style: AppTypography.headingS
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...tip.steps.asMap().entries.map(
                            (e) => _StepTile(
                              number: e.key + 1,
                              text: e.value,
                              color: color,
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.text,
    required this.color,
  });
  final int number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.labelM.copyWith(
                    color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyM
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

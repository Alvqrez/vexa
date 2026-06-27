import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/financial_tip.dart';
import 'tip_detail_page.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  TipCategory? _selectedCategory;

  List<FinancialTip> get _filtered {
    if (_selectedCategory == null) return FinancialTips.all;
    return FinancialTips.all
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
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

                      // Header
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Haptics.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Educación financiera',
                                style: AppTypography.headingM.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                              Text(
                                '${FinancialTips.all.length} consejos',
                                style: AppTypography.labelS.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Featured: tip del día
                      _FeaturedTipCard(tip: FinancialTips.daily),
                      const SizedBox(height: AppSpacing.xl),

                      // Category filters
                      Text(
                        'Categorías',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: TipCategory.values.length + 1,
                          separatorBuilder: (context2, i2) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return _CategoryChip(
                                label: 'Todos',
                                icon: Icons.apps_rounded,
                                color: AppColors.petroleum,
                                selected: _selectedCategory == null,
                                onTap: () =>
                                    setState(() => _selectedCategory = null),
                              );
                            }
                            final cat = TipCategory.values[i - 1];
                            return _CategoryChip(
                              label: cat.label,
                              icon: cat.icon,
                              color: cat.color,
                              selected: _selectedCategory == cat,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Tips list
                      ..._filtered.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _TipCard(tip: tip),
                        ),
                      ),

                      const SizedBox(height: 120),
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

// ── Featured tip ──────────────────────────────────────────────────────────────

class _FeaturedTipCard extends StatelessWidget {
  const _FeaturedTipCard({required this.tip});
  final FinancialTip tip;

  @override
  Widget build(BuildContext context) {
    final color = tip.category.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), context.colors.card],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 10, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'Consejo del día',
                      style: AppTypography.eyebrow.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            tip.title,
            style: AppTypography.headingS.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.content,
            style: AppTypography.bodyS.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(tip.category.icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                tip.category.label,
                style: AppTypography.labelS.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? color : context.colors.textTertiary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelM.copyWith(
                color: selected ? color : context.colors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final FinancialTip tip;

  @override
  Widget build(BuildContext context) {
    final color = tip.category.color;
    return GestureDetector(
      onTap: () {
        Haptics.lightImpact();
        _showDetail(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(tip.category.icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: AppTypography.labelL.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.content,
                    style: AppTypography.labelS.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TipDetailPage(tip: tip)));
  }
}

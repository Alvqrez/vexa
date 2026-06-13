import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class CategoriesRow extends ConsumerWidget {
  const CategoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final expenseCats = ref.watch(expenseCategoriesProvider).take(5).toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: expenseCats.length + 1, // +1 for "Todos"
        separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _CategoryChip(
              category: null,
              isActive: selected == null,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(selectedSubcategoryProvider.notifier).state = null;
              },
            );
          }
          final cat = expenseCats[i - 1];
          return _CategoryChip(
            category: cat,
            isActive: selected == cat.id,
            onTap: () {
              if (ref.read(selectedCategoryProvider) != cat.id) {
                ref.read(selectedSubcategoryProvider.notifier).state = null;
              }
              ref.read(selectedCategoryProvider.notifier).state = cat.id;
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final WalletCategory? category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = category?.name ?? 'Todos';
    final icon = category?.icon ?? Icons.grid_view_rounded;
    final color = category?.color ?? AppColors.emerald;
    final surface = category?.surface ?? AppColors.emeraldSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? color : c.card,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: isActive ? color : c.glassBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.textInverse : surface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelM.copyWith(
                color: isActive ? AppColors.textInverse : c.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/transaction.dart';
import '../providers/home_provider.dart';

class CategoriesRow extends ConsumerWidget {
  const CategoriesRow({super.key});

  static const _categories = [
    null, // "Todos"
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.shopping,
    TransactionCategory.entertainment,
    TransactionCategory.health,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isActive = cat == selected;
          return _CategoryChip(
            category: cat,
            isActive: isActive,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = cat;
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

  final TransactionCategory? category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = category?.label ?? 'Todos';
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
                color: isActive
                    ? AppColors.textInverse
                    : c.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/home_config.dart';
import '../providers/home_config_provider.dart';

/// Bottom sheet for drag-and-drop reordering and show/hide toggling of home
/// screen sections.  Uses [ReorderableListView] for first-class drag support.
class CustomizeHomeSheet extends ConsumerWidget {
  const CustomizeHomeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final config = ref.watch(homeConfigProvider);
    final notifier = ref.read(homeConfigProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.glassBorderStrong,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalizar inicio',
                        style: AppTypography.headingS.copyWith(
                          color: c.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Arrastra para reordenar · Toca el ojo para mostrar/ocultar',
                        style: AppTypography.labelS
                            .copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    notifier.reset();
                  },
                  child: Text(
                    'Restaurar',
                    style: AppTypography.labelM.copyWith(
                      color: AppColors.petroleum,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Reorderable list ──────────────────────────────────────────
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.03).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
              onReorderItem: (oldIndex, newIndex) {
                HapticFeedback.selectionClick();
                notifier.reorder(oldIndex, newIndex);
              },
              itemCount: config.sections.length,
              itemBuilder: (context, index) {
                final entry = config.sections[index];
                return _SectionRow(
                  key: ValueKey(entry.section),
                  entry: entry,
                  index: index,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    notifier.toggleVisibility(entry.section);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section row ───────────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    super.key,
    required this.entry,
    required this.index,
    required this.onToggle,
  });

  final HomeSectionEntry entry;
  final int index;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final section = entry.section;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 12),
        decoration: BoxDecoration(
          color: entry.visible ? c.card : c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: entry.visible ? c.glassBorder : c.glassBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Visibility toggle
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  entry.visible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  key: ValueKey(entry.visible),
                  size: 18,
                  color: entry.visible
                      ? AppColors.petroleum
                      : c.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Section icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: entry.visible
                    ? AppColors.petroleum.withValues(alpha: 0.10)
                    : c.glass,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                section.icon,
                size: 15,
                color: entry.visible ? AppColors.petroleum : c.textTertiary,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Section label
            Expanded(
              child: Text(
                section.label,
                style: AppTypography.labelL.copyWith(
                  color: entry.visible ? c.textPrimary : c.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: c.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

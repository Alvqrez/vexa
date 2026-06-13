import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/vexa_colors_ext.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.glassBorderStrong,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
      ),
    );
  }
}

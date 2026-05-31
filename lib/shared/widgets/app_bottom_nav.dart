import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/home/presentation/providers/home_provider.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  static const _items = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Análisis'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Cartera'),
    _NavItem(icon: Icons.flag_rounded, label: 'Metas'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedNavIndexProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.bottomNavBottomPadding,
      ),
      child: Container(
        height: AppSpacing.bottomNavHeight,
        decoration: BoxDecoration(
          // Solid color — no BackdropFilter/saveLayer that would break Impeller compositing
          color: const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.glassBorderStrong,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            return _NavButton(
              item: _items[i],
              isActive: i == selected,
              onTap: () {
                ref.read(selectedNavIndexProvider.notifier).state = i;
              },
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.emeraldSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: isActive ? AppColors.emerald : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.labelS.copyWith(
                color: isActive ? AppColors.emerald : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

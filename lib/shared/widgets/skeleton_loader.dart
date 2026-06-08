import 'package:flutter/material.dart';
import '../../core/theme/vexa_colors_ext.dart';

/// Widget de skeleton loader con efecto shimmer
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShimmerEffect(
          position: _shimmerAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Efecto shimmer (destello) que desliza sobre el contenido
class ShimmerEffect extends StatelessWidget {
  const ShimmerEffect({
    super.key,
    required this.position,
    required this.child,
  });

  final double position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(position - 1, 0),
          end: Alignment(position, 0),
          colors: [
            c.surface.withValues(alpha: 0.0),
            c.surface.withValues(alpha: 0.3),
            c.surface.withValues(alpha: 0.0),
          ],
          stops: const [0.1, 0.5, 0.9],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}

/// Placeholder rectangular para skeleton
class SkeletonPlaceholder extends StatelessWidget {
  const SkeletonPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton para un card completo de transacción
class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon placeholder
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonPlaceholder(
                    width: 120,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  SkeletonPlaceholder(
                    width: 80,
                    height: 10,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            // Amount placeholder
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para un card de account/balance
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            SkeletonPlaceholder(
              width: 100,
              height: 14,
              borderRadius: 4,
            ),
            const SizedBox(height: 12),
            // Balance
            SkeletonPlaceholder(
              width: 150,
              height: 20,
              borderRadius: 4,
            ),
            const SizedBox(height: 12),
            // Subtitle
            SkeletonPlaceholder(
              width: 80,
              height: 10,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para lista de transacciones
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, _) => const TransactionSkeleton(),
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}

/// Skeleton para lista de accounts
class AccountListSkeleton extends StatelessWidget {
  final int itemCount;

  const AccountListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, _) => const AccountSkeleton(),
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}

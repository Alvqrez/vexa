import 'package:flutter/material.dart';

/// Colección de transiciones suaves y elegantes para navegación
class PageTransitions {
  /// Transición fade suave
  static PageRoute<T> fadeInTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Transición slide desde la derecha (estándar)
  static PageRoute<T> slideRightTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        final secondaryOffsetAnimation =
            secondaryAnimation.drive(tween.chain(
          CurveTween(curve: curve),
        ));

        return Stack(
          children: [
            SlideTransition(
              position: secondaryOffsetAnimation,
              child: child,
            ),
            SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Transición scale + fade (ideal para dialogs y overlays)
  static PageRoute<T> scaleTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;
        final scaleTween = Tween(begin: 0.85, end: 1.0);
        final fadeTween = Tween(begin: 0.0, end: 1.0);

        final scaleAnimation = animation.drive(scaleTween.chain(
          CurveTween(curve: curve),
        ));

        final fadeAnimation = animation.drive(fadeTween.chain(
          CurveTween(curve: Curves.easeIn),
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Transición slide + fade desde abajo (ideal para bottom sheets como páginas)
  static PageRoute<T> slideUpTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        final slideTween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero);
        final fadeTween = Tween(begin: 0.0, end: 1.0);

        final slideAnimation = animation.drive(slideTween.chain(
          CurveTween(curve: curve),
        ));

        final fadeAnimation = animation.drive(fadeTween.chain(
          CurveTween(curve: Curves.easeIn),
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Transición material (matching platform behavior)
  static PageRoute<T> materialTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        final slideAnimation = animation.drive(
          Tween(begin: const Offset(0.3, 0.0), end: Offset.zero).chain(
            CurveTween(curve: curve),
          ),
        );

        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: Curves.easeIn),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

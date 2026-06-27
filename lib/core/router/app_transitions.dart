import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

/// Premium slide-up + fade transition used for all pushed routes.
/// Duration: 280ms — fast enough to feel snappy, slow enough to feel elegant.
class VexaPageRoute<T> extends PageRouteBuilder<T> {
  VexaPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Reduced motion: skip the transition entirely.
            if (!AppMotion.enabled) return child;
            // Forward: slide up 4% + fade in
            final enterSlide = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1.0, 0.36, 1.0),
            ));

            final enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            );

            // Reverse: previous screen slides down slightly
            final exitSlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.02),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInCubic,
            ));

            final exitFade = Tween<double>(begin: 1.0, end: 0.92).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInCubic,
              ),
            );

            return SlideTransition(
              position: exitSlide,
              child: FadeTransition(
                opacity: exitFade,
                child: SlideTransition(
                  position: enterSlide,
                  child: FadeTransition(opacity: enterFade, child: child),
                ),
              ),
            );
          },
        );
}

/// PageTransitionsBuilder for MaterialApp's PageTransitionsTheme.
class VexaPageTransitionsBuilder extends PageTransitionsBuilder {
  const VexaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Reduced motion: skip the transition entirely.
    if (!AppMotion.enabled) return child;
    final enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    ));

    final enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    final exitScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      ),
    );

    final exitFade = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      ),
    );

    return ScaleTransition(
      scale: exitScale,
      child: FadeTransition(
        opacity: exitFade,
        child: SlideTransition(
          position: enterSlide,
          child: FadeTransition(opacity: enterFade, child: child),
        ),
      ),
    );
  }
}

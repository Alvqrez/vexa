import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../shell/presentation/pages/main_shell.dart';
import '../../../../core/data/local_prefs_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _logoScale = Tween<double>(begin: 0.68, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 860));
    await _exitCtrl.forward();
    if (!mounted) return;
    final onboardingDone = await LocalPrefsService.getBool('onboarding_done');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) =>
            onboardingDone ? const MainShell() : const OnboardingPage(),
        transitionsBuilder: (ctx, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF09090F) : const Color(0xFFF7F6F2);
    final blobColor =
        isDark ? const Color(0x0800D68F) : const Color(0xFFEBEAE3);
    final logoBox = isDark ? const Color(0xFFF0F0EE) : const Color(0xFF0D0D14);
    final checkColor =
        isDark ? const Color(0xFF09090F) : const Color(0xFFF7F6F2);
    final titleColor =
        isDark ? const Color(0xFFF0F0EE) : const Color(0xFF0D0D14);
    final subtitleColor =
        isDark ? const Color(0xFF9090B0) : const Color(0xFF9090A8);
    final indicatorBg =
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFDDDCD6);
    final indicatorIcon =
        isDark ? const Color(0xFF9090B0) : const Color(0xFF5A5A7A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bg,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _exitOpacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ambient blob
                    Positioned(
                      bottom: -constraints.maxHeight * 0.08,
                      left: constraints.maxWidth * 0.08,
                      right: constraints.maxWidth * 0.08,
                      child: Container(
                        height: constraints.maxHeight * 0.52,
                        decoration: BoxDecoration(
                          color: blobColor,
                          borderRadius: BorderRadius.circular(240),
                        ),
                      ),
                    ),

                    // Centered logo + wordmark
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoOpacity,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: logoBox,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.10),
                                    blurRadius: 36,
                                    spreadRadius: -6,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(46, 46),
                                  painter: _CheckPainter(color: checkColor),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vexa',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.8,
                                    height: 1.0,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'PERSONAL FINANCE',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 3.8,
                                    height: 1.0,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom scroll indicator
                    Positioned(
                      bottom: 44,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: indicatorBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: indicatorIcon,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.092
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.17, size.height * 0.52)
      ..lineTo(size.width * 0.41, size.height * 0.74)
      ..lineTo(size.width * 0.81, size.height * 0.27);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

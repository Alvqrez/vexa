import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight confetti overlay — pure Flutter, no packages.
/// Call [ConfettiOverlay.show] to trigger a 2-second burst.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiEntry(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Overlay entry ─────────────────────────────────────────────────────────────

class _ConfettiEntry extends StatefulWidget {
  const _ConfettiEntry({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_ConfettiEntry> createState() => _ConfettiEntryState();
}

class _ConfettiEntryState extends State<_ConfettiEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;

  static const _count = 60;
  static const _colors = [
    Color(0xFF00D68F), // emerald
    Color(0xFF1A7A9A), // petroleum
    Color(0xFFFF5F82), // negative
    Color(0xFFFFB74D), // warning
    Color(0xFFCE93D8), // shopping
    Color(0xFF64B5F6), // transport
    Color(0xFFFFD54F), // entertainment
    Color(0xFFFFFFFF), // white
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(_count, (_) => _Particle.random(rng));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _ctrl.value,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ── Particle model ────────────────────────────────────────────────────────────

class _Particle {
  _Particle.random(math.Random rng)
      : x = rng.nextDouble(),
        vx = (rng.nextDouble() - 0.5) * 0.6,
        vy = -(0.4 + rng.nextDouble() * 0.8),
        size = 5.0 + rng.nextDouble() * 7.0,
        rotation = rng.nextDouble() * math.pi * 2,
        rotationSpeed = (rng.nextDouble() - 0.5) * 8,
        color = _ConfettiEntryState._colors[
            rng.nextInt(_ConfettiEntryState._colors.length)],
        isRect = rng.nextBool(),
        delay = rng.nextDouble() * 0.2;

  final double x;       // horizontal start (0–1)
  final double vx;      // horizontal velocity
  final double vy;      // vertical velocity (negative = upward)
  final double size;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final bool isRect;
  final double delay;   // 0–0.2 stagger
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  static const _gravity = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Physics: position
      final px = p.x * size.width + p.vx * t * size.width;
      final py = (p.vy * t + 0.5 * _gravity * t * t) * size.height + size.height * 0.1;

      // Fade out in last 30%
      final alpha = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A premium animated gradient background with soft floating orbs.
///
/// Wraps a [child] widget and renders a slowly shifting gradient with
/// translucent glowing circles drifting across the canvas. The effect is
/// intentionally subtle so it never distracts from gameplay.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _gradientProgress = 0.0;
  double _orbProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Single controller that ticks at a reduced rate via a long duration.
    // We manually derive gradient and orb progress from it.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _controller.addListener(_onTick);
  }

  void _onTick() {
    // Map the single controller value to two different cycle speeds.
    final t = _controller.value;
    _gradientProgress = (t * 3) % 1.0; // ~20s cycle (60/3)
    _orbProgress = (t * 2) % 1.0;      // ~30s cycle (60/2)
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(
            gradientProgress: _gradientProgress,
            orbProgress: _orbProgress,
            isDark: isDark,
          ),
          child: child,
        );
      },
      child: RepaintBoundary(child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter
// ---------------------------------------------------------------------------

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.gradientProgress,
    required this.orbProgress,
    required this.isDark,
  });

  final double gradientProgress;
  final double orbProgress;
  final bool isDark;

  // Cache orbs to avoid allocating per frame.
  static List<_Orb>? _cachedOrbs;
  static Size? _cachedSize;
  static bool? _cachedIsDark;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGradient(canvas, size);
    _paintOrbs(canvas, size);
  }

  // ---------- gradient ----------

  void _paintGradient(Canvas canvas, Size size) {
    final colors = isDark ? AppColors.darkGradient : AppColors.lightGradient;

    // Rotate the gradient alignment smoothly over time.
    final angle = gradientProgress * 2 * pi;
    final beginX = cos(angle);
    final beginY = sin(angle);

    final gradient = LinearGradient(
      begin: Alignment(beginX, beginY),
      end: Alignment(-beginX, -beginY),
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  // ---------- orbs ----------

  void _paintOrbs(Canvas canvas, Size size) {
    // Cache orbs so we don't allocate every frame.
    if (_cachedOrbs == null || _cachedSize != size || _cachedIsDark != isDark) {
      _cachedOrbs = _generateOrbs(size);
      _cachedSize = size;
      _cachedIsDark = isDark;
    }
    final orbs = _cachedOrbs!;

    for (final orb in orbs) {
      // Each orb drifts on its own sin/cos path at a unique phase offset.
      final dx =
          sin(orbProgress * 2 * pi + orb.phaseX) * orb.driftRadius;
      final dy =
          cos(orbProgress * 2 * pi + orb.phaseY) * orb.driftRadius;

      final center = Offset(orb.baseX + dx, orb.baseY + dy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withAlpha(orb.peakAlpha),
            orb.color.withAlpha(0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(
          Rect.fromCircle(center: center, radius: orb.radius),
        );

      canvas.drawCircle(center, orb.radius, paint);
    }
  }

  List<_Orb> _generateOrbs(Size size) {
    final accent = isDark
        ? const Color(0xFF9C8FFF) // soft purple in dark mode
        : const Color(0xFF6C63FF); // main purple in light mode

    return [
      _Orb(
        baseX: size.width * 0.2,
        baseY: size.height * 0.15,
        radius: size.width * 0.35,
        driftRadius: size.width * 0.04,
        phaseX: 0,
        phaseY: 1.2,
        color: accent,
        peakAlpha: isDark ? 18 : 22,
      ),
      _Orb(
        baseX: size.width * 0.8,
        baseY: size.height * 0.35,
        radius: size.width * 0.28,
        driftRadius: size.width * 0.05,
        phaseX: 2.0,
        phaseY: 0.5,
        color: isDark
            ? const Color(0xFF4A3FBB)
            : const Color(0xFFCE93D8),
        peakAlpha: isDark ? 15 : 18,
      ),
      _Orb(
        baseX: size.width * 0.5,
        baseY: size.height * 0.75,
        radius: size.width * 0.40,
        driftRadius: size.width * 0.06,
        phaseX: 4.0,
        phaseY: 3.3,
        color: isDark
            ? const Color(0xFF1A237E)
            : const Color(0xFF81D4FA),
        peakAlpha: isDark ? 14 : 16,
      ),
      _Orb(
        baseX: size.width * 0.15,
        baseY: size.height * 0.55,
        radius: size.width * 0.22,
        driftRadius: size.width * 0.03,
        phaseX: 1.5,
        phaseY: 4.7,
        color: accent,
        peakAlpha: isDark ? 12 : 14,
      ),
    ];
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.gradientProgress != gradientProgress ||
        oldDelegate.orbProgress != orbProgress ||
        oldDelegate.isDark != isDark;
  }
}

// ---------------------------------------------------------------------------
// Orb data class
// ---------------------------------------------------------------------------

class _Orb {
  const _Orb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.driftRadius,
    required this.phaseX,
    required this.phaseY,
    required this.color,
    required this.peakAlpha,
  });

  final double baseX;
  final double baseY;
  final double radius;
  final double driftRadius;
  final double phaseX;
  final double phaseY;
  final Color color;
  final int peakAlpha;
}

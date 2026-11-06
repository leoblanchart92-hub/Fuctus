/// ArcReactor — animated Iron-Man arc reactor painted in Flutter.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ArcReactor extends StatefulWidget {
  final double size;
  final bool firing; // brighter core when speaking/listening

  const ArcReactor({super.key, required this.size, this.firing = false});

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coreBoost = widget.firing ? 1.0 : 0.55;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _ArcReactorPainter(progress: _controller.value, coreBoost: coreBoost),
      ),
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  final double progress;
  final double coreBoost;
  _ArcReactorPainter({required this.progress, required this.coreBoost});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final glow = Color.lerp(const Color(0xFF2BB8D8), const Color(0xFFA8F4FF), coreBoost - 0.5)!;

    // ambient bloom
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.40 * coreBoost), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // outer housing ring
    _ring(canvas, center, r * 0.92, r * 0.055, const Color(0xFF101820));
    _ring(canvas, center, r * 0.86, 1.6, glow.withValues(alpha: 0.9));

    // rotating dashed ring
    _dashedRing(canvas, center, r * 0.745, r * 0.045, 12, progress * 2 * math.pi, glow);

    // static tick ring (inner)
    _tickRing(canvas, center, r * 0.60, 24, const Color(0xFF3A5A6A), glow);

    // counter-rotating inner ring
    _dashedRing(canvas, center, r * 0.475, r * 0.065, 3, -progress * 4 * math.pi,
        glow.withValues(alpha: 0.95));

    // reactor core
    final coreGradient = RadialGradient(
      colors: [
        const Color(0xFFFFFFFF),
        const Color(0xFFCFFFFF),
        glow,
        glow.withValues(alpha: 0.05),
      ],
      stops: const [0.0, 0.32, 0.62, 1.0],
    );
    canvas.drawCircle(
      center,
      r * 0.36,
      Paint()
        ..shader = coreGradient.createShader(Rect.fromCircle(center: center, radius: r * 0.36)),
    );

    // triangular struts
    final strut = Paint()
      ..color = const Color(0xFF0A1016)
      ..strokeWidth = r * 0.055
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final angle = progress * 0 + i * (2 * math.pi / 3) - math.pi / 2;
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * r * 0.09;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * r * 0.32;
      canvas.drawLine(p1, p2, strut);
    }
  }

  void _ring(Canvas canvas, Offset center, double radius, double width, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  void _dashedRing(Canvas canvas, Offset center, double radius, double width, int dashes, double phase, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    final sweep = (2 * math.pi / dashes) * 0.62;
    for (var i = 0; i < dashes; i++) {
      final start = phase + i * (2 * math.pi / dashes);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
    }
  }

  void _tickRing(Canvas canvas, Offset center, double radius, int ticks, Color dim, Color bright) {
    for (var i = 0; i < ticks; i++) {
      final angle = i * (2 * math.pi / ticks);
      final major = i % 6 == 0;
      final inner = radius * (major ? 0.86 : 0.93);
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * inner;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 6);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = major ? 1.8 : 1.0
          ..color = major ? bright.withValues(alpha: 0.8) : dim,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcReactorPainter old) =>
      old.progress != progress || old.coreBoost != coreBoost;
}

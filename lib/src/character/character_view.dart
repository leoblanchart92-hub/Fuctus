/// CharacterView — live, animated JARVIS android for Flutter.
///
/// The widget is intentionally stateless about animation logic: the caller owns
/// a [HumanoidAnimator] (usually inside the app-wide JarvisController), ticks it,
/// and this widget simply renders the current frame at display rate.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'jarvis_3d/animator.dart';
import 'jarvis_3d/humanoid_rig.dart';
import 'jarvis_3d/math3d.dart';
import 'jarvis_3d/renderer.dart';

class CharacterView extends StatefulWidget {
  final HumanoidAnimator animator;

  /// When false the view renders a single static frame (tests, semantics).
  final bool live;

  const CharacterView({super.key, required this.animator, this.live = true});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _lastElapsed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.live) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _lastElapsed).clamp(0.0, 0.05);
    _lastElapsed = now;
    widget.animator.tick(dt);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _JarvisScenePainter(animator: widget.animator),
      fit: ui.BoxFit.contain,
    );
  }
}

class _JarvisScenePainter extends CustomPainter {
  final HumanoidAnimator animator;
  _JarvisScenePainter({required this.animator});

  // static camera framing the android
  final Camera3D _camera = Camera3D(
    position: const Vec3(0, 1.32, 3.05),
    target: const Vec3(0, 0.98, 0),
    fovY: 0.50,
  );

  @override
  void paint(ui.Canvas canvas, Size size) {
    // ---- ambient backdrop (deep space + core glow) ----
    final bg = ui.Gradient.radial(
      Offset(size.width / 2, size.height * 0.34),
      size.height * 0.72,
      const [Color(0xFF0D2334), Color(0xFF050D16), Color(0xFF02060B)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(Offset.zero & size, ui.Paint()..shader = bg);

    // ---- HUD floor grid ----
    _paintFloor(canvas, size);

    // ---- pedestal ring under the android ----
    final pelvis = 0.0;
    final ringCenter = _camera.project(const Vec3(0, pelvis, 0), size);
    final ringRx = 0.62 * ringCenter.scale;
    final ringRect = ui.Rect.fromCenter(
      center: ringCenter.screen + Offset(0, 0.02 * ringCenter.scale),
      width: ringRx * 2,
      height: ringRx * 0.46,
    );
    final ringPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF5CE8FF).withValues(alpha: 0.34 + 0.16 * animator.glowPulse);
    canvas.drawOval(ringRect, ringPaint);
    canvas.drawOval(
      ringRect.inflate(-7),
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF5CE8FF).withValues(alpha: 0.16),
    );

    // ---- the android ----
    final skeleton = buildSkeleton(animator.buildPose());
    final smile = animator.weightOf(JarvisExpression.smile);
    final thinking = animator.weightOf(JarvisExpression.thinking);
    final listening = animator.weightOf(JarvisExpression.listening);
    final success = animator.weightOf(JarvisExpression.success);
    final state = RenderState(
      time: animator.time,
      breath: animator.breath,
      eyeOpen: animator.eyeOpen.clamp(0.0, 1.0),
      mouthOpen: animator.mouthOpen.clamp(0.0, 1.0),
      smile: smile,
      thinking: thinking,
      listening: listening,
      success: success,
      glowPulse: animator.glowPulse,
    );
    HumanoidRenderer(_camera).paint(canvas, size, skeleton, state);

    // ---- vignette ----
    final vignette = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.78,
      const [Color(0x0002060B), Color(0x6602060B)],
      const [0.62, 1.0],
    );
    canvas.drawRect(Offset.zero & size, ui.Paint()..shader = vignette);
  }

  void _paintFloor(ui.Canvas canvas, Size size) {
    final horizon = size.height * 0.78;
    final fadePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, horizon),
        Offset(0, size.height),
        [const Color(0x0002060B), const Color(0x2E2BD8FF)],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, horizon, size.width, size.height - horizon), fadePaint);

    final line = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x332BD8FF);
    for (var i = 0; i < 7; i++) {
      final y = horizon + math.pow(i / 6, 1.7) * (size.height - horizon);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (var i = -6; i <= 6; i++) {
      final xBottom = size.width / 2 + i * size.width * 0.16;
      canvas.drawLine(Offset(size.width / 2 + i * 24.0, horizon), Offset(xBottom, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant _JarvisScenePainter oldDelegate) => true;
}

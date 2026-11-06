/// renderer — soft volumetric shading of the procedural humanoid onto Canvas.
///
/// Techniques (inspired by louis-cfm/coucou's gradient-shaded Mochi):
///  • capsules  → projected cylinder envelope, 5-stop linear gradient across the
///    short axis (dark rim / bright core) + cap arcs;
///  • ellipsoids → radial gradient offset toward the light;
///  • visor/reactor/palms → additive-style gradients & bloom (MaskFilter);
///  • everything depth-sorted far→near (painter's algorithm).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../jarvis_3d/humanoid_rig.dart';
import '../jarvis_3d/math3d.dart';

/// Everything the renderer needs beyond the skeleton.
class RenderState {
  final double time;
  final double breath; // -1..1
  final double eyeOpen; // 0..1
  final double mouthOpen; // 0..1
  final double smile; // 0..1 (smile expression weight)
  final double listening; // 0..1
  final double thinking; // 0..1
  final double success; // 0..1
  final double glowPulse; // 0..1

  const RenderState({
    required this.time,
    required this.breath,
    required this.eyeOpen,
    required this.mouthOpen,
    required this.smile,
    required this.listening,
    required this.thinking,
    required this.success,
    required this.glowPulse,
  });
}

class JarvisPalette {
  static const Color armorHi = Color(0xFFE8EEF5);
  static const Color armorLight = Color(0xFFC3CFDD);
  static const Color armorMid = Color(0xFF8296AB);
  static const Color armorDark = Color(0xFF46535F);
  static const Color armorDeep = Color(0xFF232B34);
  static const Color jointDark = Color(0xFF171D24);
  static const Color glow = Color(0xFF5CE8FF);
  static const Color glowSoft = Color(0xFF2BB8D8);
  static const Color visor = Color(0xFF04090F);
  static const Color eye = Color(0xFFA8F4FF);
}

class HumanoidRenderer {
  final Camera3D camera;
  HumanoidRenderer(this.camera);

  // light direction (from upper-left-front), used for gradient offsets
  static const Vec3 lightDir = Vec3(-0.55, 0.75, 0.55);

  void paint(ui.Canvas canvas, Size size, Skeleton sk, RenderState st) {
    final parts = <_DrawCmd>[];

    void add(double depth, void Function(ui.Canvas c) fn) =>
        parts.add(_DrawCmd(depth, fn));

    final pelvis = sk['pelvis'].position;
    final spine = sk['spine'].position;
    final chest = sk['chest'].position;
    final neck = sk['neck'].position;
    final head = sk['head'];

    // ---------------- legs ----------------
    for (final side in ['R', 'L']) {
      final hip = sk['hip$side'].position;
      final knee = sk['knee$side'].position;
      final ankle = sk['ankle$side'].position;
      final foot = sk['foot$side'];
      add(camera.project(knee, size).depth, (c) {
        _capsule(c, size, hip, knee, 0.088, 0.064);
      });
      add(camera.project(ankle, size).depth, (c) {
        _capsule(c, size, knee, ankle, 0.062, 0.047);
      });
      add(camera.project(foot.position, size).depth, (c) {
        _ellipsoid(c, size, foot.position, 0.062, 0.040, 0.108,
            rotationZ: 0, palette: _armorPair());
      });
      // knee pad
      add(camera.project(knee, size).depth - 0.001, (c) {
        _ellipsoid(c, size, knee + const Vec3(0, 0, 0.028), 0.052, 0.048, 0.03,
            palette: _armorPair(light: true));
      });
    }

    // ---------------- pelvis ----------------
    add(camera.project(pelvis, size).depth, (c) {
      _ellipsoid(c, size, pelvis + const Vec3(0, -0.01, 0), 0.150, 0.098, 0.118,
          palette: _armorPair());
    });

    // ---------------- torso ----------------
    final breathFlare = 1 + 0.045 * st.breath;
    add(camera.project(spine, size).depth, (c) {
      _capsule(c, size, pelvis + const Vec3(0, 0.02, 0),
          spine + const Vec3(0, 0.04, 0), 0.135, 0.128, scaleX: breathFlare);
    });
    add(camera.project(chest, size).depth, (c) {
      _ellipsoid(c, size, chest, 0.178 * breathFlare, 0.132, 0.122,
          palette: _armorPair());
    });
    // chest armor plate (slightly forward, darker)
    final chestPlateCenter = chest + const Vec3(0, 0.005, 0.055);
    add(camera.project(chestPlateCenter, size).depth - 0.002, (c) {
      _ellipsoid(c, size, chestPlateCenter, 0.128 * breathFlare, 0.095, 0.075,
          palette: _platePair(), rimGlow: true);
    });

    // ---------------- back arm (far side) & front arm ----------------
    // Arms depth handled globally by sorting; both added here.
    for (final side in ['R', 'L']) {
      final shoulder = sk['shoulder$side'].position;
      final elbow = sk['elbow$side'].position;
      final wrist = sk['wrist$side'].position;
      final hand = sk['hand$side'];

      add(camera.project(shoulder, size).depth, (c) {
        _capsule(c, size, shoulder, elbow, 0.056, 0.043, scaleX: 1);
        // shoulder pauldron
        _ellipsoid(c, size, shoulder + const Vec3(0, 0.022, 0), 0.074, 0.055, 0.068,
            palette: _armorPair(light: true));
      });
      add(camera.project(elbow, size).depth, (c) {
        _capsule(c, size, elbow, wrist, 0.046, 0.037, scaleX: 1);
        _ellipsoid(c, size, elbow, 0.044, 0.042, 0.042,
            palette: _platePair());
      });
      add(camera.project(hand.position, size).depth, (c) {
        _drawHand(c, size, side, sk, st);
      });
    }

    // ---------------- neck ----------------
    add(camera.project(neck, size).depth, (c) {
      _capsule(c, size, neck - const Vec3(0, 0.03, 0),
          head.position - const Vec3(0, 0.085, 0), 0.046, 0.042);
      // neck rings
      _ellipsoid(c, size, neck + const Vec3(0, -0.01, 0), 0.052, 0.018, 0.048,
          palette: _platePair());
    });

    // ---------------- head ----------------
    final headPos = head.position;
    add(camera.project(headPos, size).depth, (c) {
      _ellipsoid(c, size, headPos, 0.104, 0.122, 0.106,
          palette: _armorPair(light: true));
      // subtle cranial seam
      _seam(c, size, sk, st);
    });

    // ---------------- face (visor, eyes, mouth) ----------------
    add(camera.project(headPos + const Vec3(0, 0, 0.11), size).depth - 0.004,
        (c) {
      _drawFace(c, size, sk, st);
    });

    // ---------------- arc reactor on chest ----------------
    final reactor = chest + const Vec3(0, -0.01, 0.125);
    add(camera.project(reactor, size).depth - 0.005, (c) {
      _reactor(c, size, reactor, st);
    });

    // sort far → near, then draw
    parts.sort((a, b) => b.depth.compareTo(a.depth));
    for (final p in parts) {
      p.draw(canvas);
    }
  }

  // ==========================================================================
  // Primitive painters
  // ==========================================================================

  ({Color light, Color mid, Color dark}) _armorPair({bool light = false}) {
    if (light) {
      return (light: JarvisPalette.armorHi, mid: JarvisPalette.armorLight, dark: JarvisPalette.armorMid);
    }
    return (light: JarvisPalette.armorLight, mid: JarvisPalette.armorMid, dark: JarvisPalette.armorDark);
  }

  ({Color light, Color mid, Color dark}) _platePair() =>
      (light: JarvisPalette.armorDark, mid: const Color(0xFF2E3944), dark: JarvisPalette.jointDark);

  void _capsule(ui.Canvas canvas, Size size, Vec3 a, Vec3 b, double ra, double rb,
      {double scaleX = 1}) {
    final pa = camera.project(a, size);
    final pb = camera.project(b, size);
    final axis = pb.screen - pa.screen;
    final len = axis.distance;
    if (len < 1) return;
    final dir = axis / len;
    final perp = Offset(-dir.dy, dir.dx);

    final wa = ra * pa.scale * scaleX;
    final wb = rb * pb.scale * scaleX;

    final lightSide = _lightScreenSide(perp);
    final colors = [
      JarvisPalette.armorDeep,
      JarvisPalette.armorDark,
      lightSide > 0 ? JarvisPalette.armorHi : JarvisPalette.armorLight,
      JarvisPalette.armorMid,
      JarvisPalette.armorDeep,
    ];
    final gradient = ui.Gradient.linear(
      pa.screen + perp * wa,
      pa.screen - perp * wa,
      colors,
      const [0.0, 0.24, 0.42, 0.72, 1.0],
    );

    final path = ui.Path();
    path.moveTo(pa.screen.dx + perp.dx * wa, pa.screen.dy + perp.dy * wa);
    path.lineTo(pb.screen.dx + perp.dx * wb, pb.screen.dy + perp.dy * wb);
    // round cap at b
    path.arcToPoint(
      ui.Offset(pb.screen.dx - perp.dx * wb, pb.screen.dy - perp.dy * wb),
      radius: Radius.circular(wb),
      clockwise: true,
    );
    path.lineTo(pa.screen.dx - perp.dx * wa, pa.screen.dy - perp.dy * wa);
    path.arcToPoint(
      ui.Offset(pa.screen.dx + perp.dx * wa, pa.screen.dy + perp.dy * wa),
      radius: Radius.circular(wa),
      clockwise: true,
    );
    path.close();

    final paint = ui.Paint()..shader = gradient;
    canvas.drawPath(path, paint);

    // specular streak along the limb
    final spec = ui.Paint()
      ..color = const ui.Color(0x55FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, wa * 0.16)
      ..strokeCap = ui.StrokeCap.round;
    final offset = perp * (lightSide * wa * 0.42);
    canvas.drawLine(
      ui.Offset(pa.screen.dx, pa.screen.dy) + offset * 0.9 + dir * wa * 0.55,
      ui.Offset(pb.screen.dx, pb.screen.dy) + offset * 0.9 - dir * wb * 0.55,
      spec,
    );
  }

  double _lightScreenSide(Offset perp) {
    // sign of the light's projection onto the capsule's short axis
    final lightScreenish = Offset(-lightDir.x, -lightDir.y).direction;
    final perpAngle = perp.direction;
    final d = math.cos(lightScreenish - perpAngle);
    return d >= 0 ? 1 : -1;
  }

  void _ellipsoid(ui.Canvas canvas, Size size, Vec3 center, double rx, double ry, double rz,
      {({Color light, Color mid, Color dark})? palette,
      double rotationZ = 0,
      bool rimGlow = false}) {
    final p = camera.project(center, size);
    final px = rx * p.scale;
    final py = ry * p.scale;
    if (px < 0.5 || py < 0.5) return;

    final pal = palette ?? _armorPair();
    final lightOffset = Offset(-lightDir.x, -lightDir.y);
    final gradientCenter = p.screen + lightOffset * (px * 0.36);

    final gradient = ui.Gradient.radial(
      gradientCenter,
      px * 1.02,
      [pal.light, pal.mid, pal.dark, const Color(0xFF10151B)],
      const [0.0, 0.42, 0.82, 1.0],
    );

    canvas.save();
    canvas.translate(p.screen.dx, p.screen.dy);
    canvas.rotate(rotationZ);
    canvas.scale(1.0, py / px); // horizontal axis stays px wide
    final path = ui.Path()..addOval(ui.Rect.fromCircle(center: ui.Offset.zero, radius: px));
    canvas.drawPath(path, ui.Paint()..shader = gradient);
    canvas.restore();

    if (rimGlow) {
      final rim = ui.Paint()
        ..color = JarvisPalette.glow.withValues(alpha: 0.22)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawOval(
        ui.Rect.fromCenter(center: p.screen, width: px * 1.9, height: py * 1.9),
        rim,
      );
    }
  }

  void _seam(ui.Canvas canvas, Size size, Skeleton sk, RenderState st) {
    // subtle meridian seam on the cranium
    final head = sk['head'];
    final pts = <ui.Offset>[];
    for (var i = -4; i <= 4; i++) {
      final lon = i * 0.16;
      final y = 0.088;
      final k = math.sqrt(math.max(0.0, 1 - (y / 0.122) * (y / 0.122)));
      final local = Vec3(0.104 * k * math.sin(lon), y, 0.106 * k * math.cos(lon));
      final world = head.position +
          head.xAxis * local.x +
          head.yAxis * local.y +
          head.zAxis * local.z;
      pts.add(camera.project(world, size).screen);
    }
    final path = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0x33000000)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  // ==========================================================================
  // Face
  // ==========================================================================

  Vec3 _headLocal(Skeleton sk, Vec3 local) =>
      sk['head'].position +
      sk['head'].xAxis * local.x +
      sk['head'].yAxis * local.y +
      sk['head'].zAxis * local.z;

  ({double rx, double ry, double rz}) get _headRadii =>
      (rx: 0.104, ry: 0.122, rz: 0.106);

  Vec3 _headSurface(double y, double lon, double scale) {
    final r = _headRadii;
    final k = math.sqrt(math.max(0.0, 1 - (y / r.ry) * (y / r.ry)));
    return Vec3(r.rx * k * math.sin(lon) * scale, y, r.rz * k * math.cos(lon) * scale);
  }

  void _drawFace(ui.Canvas canvas, Size size, Skeleton sk, RenderState st) {
    final head = sk['head'];
    // facing factor: 1 when looking at the camera
    final facing = head.zAxis.z.clamp(0.0, 1.0);
    if (facing <= 0.03) return;

    // ---------- visor band ----------
    const visorTop = 0.062;
    const visorBottom = -0.072;
    final bandPtsTop = <ui.Offset>[];
    final bandPtsBottom = <ui.Offset>[];
    for (var i = -14; i <= 14; i++) {
      final lon = i / 14 * 0.82;
      bandPtsTop.add(camera.project(_headLocal(sk, _headSurface(visorTop, lon, 1.035)), size).screen);
      bandPtsBottom.add(camera.project(_headLocal(sk, _headSurface(visorBottom, lon, 1.035)), size).screen);
    }
    final visorPath = ui.Path()..moveTo(bandPtsTop.first.dx, bandPtsTop.first.dy);
    for (final p in bandPtsTop.skip(1)) {
      visorPath.lineTo(p.dx, p.dy);
    }
    for (final p in bandPtsBottom.reversed) {
      visorPath.lineTo(p.dx, p.dy);
    }
    visorPath.close();

    final visorRect = visorPath.getBounds();
    final visorGradient = ui.Gradient.linear(
      visorRect.topCenter,
      visorRect.bottomCenter,
      const [Color(0xFF0B1622), JarvisPalette.visor, Color(0xFF0A121B)],
    );
    canvas.drawPath(visorPath, ui.Paint()..shader = visorGradient);
    canvas.drawPath(
      visorPath,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = JarvisPalette.glow.withValues(alpha: 0.28 + 0.22 * st.listening * st.glowPulse),
    );

    // ---------- eyes ----------
    final eyeNarrow = 1 - 0.42 * st.thinking;
    final successHappy = st.success;
    for (final side in [-1.0, 1.0]) {
      final lon = side * 0.345;
      const y = 0.0;
      final world = _headLocal(sk, _headSurface(y, lon, 1.045));
      final p = camera.project(world, size);
      final ew = 0.036 * p.scale * (0.30 + 0.70 * facing);
      final eh = 0.0165 * p.scale * st.eyeOpen * eyeNarrow;
      if (ew < 1) continue;

      canvas.save();
      canvas.translate(p.screen.dx, p.screen.dy);
      if (successHappy > 0.25) {
        canvas.rotate(side * -0.18 * successHappy);
      }
      // glow
      final glowPaint = ui.Paint()
        ..color = JarvisPalette.glow.withValues(alpha: 0.55)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, ew * 0.9);
      canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset.zero, width: ew * 2.6, height: math.max(eh, 2) * 3.1), glowPaint);
      // slit
      final eyeGradient = ui.Gradient.radial(
        ui.Offset.zero,
        ew,
        const [Color(0xFFFFFFFF), JarvisPalette.eye, JarvisPalette.glowSoft],
      );
      canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset.zero, width: ew * 2, height: math.max(eh * 2, 1.6)),
        ui.Paint()..shader = eyeGradient,
      );
      canvas.restore();
    }

    // ---------- brow hints (thinking tilt) ----------
    if (st.thinking > 0.05) {
      final browPaint = ui.Paint()
        ..color = JarvisPalette.glow.withValues(alpha: 0.5 * st.thinking)
        ..strokeWidth = 1.6
        ..strokeCap = ui.StrokeCap.round;
      for (final side in [-1.0, 1.0]) {
        final a = _headLocal(sk, _headSurface(0.038, side * 0.46, 1.05));
        final b = _headLocal(sk, _headSurface(0.052 - (side < 0 ? 0.016 : 0.0), side * 0.22, 1.05));
        canvas.drawLine(camera.project(a, size).screen, camera.project(b, size).screen, browPaint);
      }
    }

    // ---------- core dot on forehead ----------
    final dot = _headLocal(sk, _headSurface(0.088, 0, 1.045));
    final dp = camera.project(dot, size);
    canvas.drawCircle(
      dp.screen,
      math.max(1.2, 0.0075 * dp.scale),
      ui.Paint()..color = JarvisPalette.glow.withValues(alpha: 0.9),
    );

    // ---------- mouth ----------
    const mouthY = -0.046;
    final left = _headLocal(sk, _headSurface(mouthY, -0.155, 1.05));
    final right = _headLocal(sk, _headSurface(mouthY, 0.155, 1.05));
    final mid = _headLocal(sk, _headSurface(mouthY, 0, 1.06));
    final pl = camera.project(left, size).screen;
    final pr = camera.project(right, size).screen;
    final pm = camera.project(mid, size).screen;
    final mouthW = (pr - pl).distance;

    final smileDrop = (0.012 + 0.020 * st.smile + 0.011 * st.success) * camera.project(mid, size).scale;

    if (st.mouthOpen < 0.13) {
      // closed — expressive curve
      final path = ui.Path()..moveTo(pl.dx, pl.dy);
      path.quadraticBezierTo(pm.dx, pm.dy + smileDrop * 2.1, pr.dx, pr.dy);
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = JarvisPalette.glow.withValues(alpha: 0.55 + 0.25 * st.smile)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = math.max(1.3, mouthW * 0.045)
          ..strokeCap = ui.StrokeCap.round,
      );
    } else {
      // open — viseme ellipse
      final openH = mouthW * 0.42 * st.mouthOpen;
      final rect = ui.Rect.fromCenter(center: Offset(pm.dx, pm.dy + smileDrop * 0.4 + openH * 0.35), width: mouthW * 0.66, height: openH);
      canvas.drawOval(rect, ui.Paint()..color = const Color(0xFF050B12));
      canvas.drawOval(
        rect,
        ui.Paint()
          ..color = JarvisPalette.glow.withValues(alpha: 0.35)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    // ---------- ear discs ----------
    for (final side in [-1.0, 1.0]) {
      final world = _headLocal(sk, _headSurface(0.005, side * 1.52, 1.0));
      final p = camera.project(world, size);
      final r = 0.021 * p.scale;
      canvas.drawCircle(p.screen, r, ui.Paint()..color = JarvisPalette.armorDark);
      canvas.drawCircle(
        p.screen,
        r,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = JarvisPalette.glow.withValues(alpha: 0.35 + 0.45 * st.listening * st.glowPulse),
      );
      canvas.drawCircle(p.screen, r * 0.35, ui.Paint()..color = JarvisPalette.glow.withValues(alpha: 0.8));
    }
  }

  // ==========================================================================
  // Hands
  // ==========================================================================

  void _drawHand(ui.Canvas canvas, Size size, String side, Skeleton sk, RenderState st) {
    final hand = sk['hand$side'];
    final mirror = side == 'R' ? 1.0 : -1.0;
    final center = hand.position;

    // palm
    _ellipsoid(canvas, size, center, 0.046, 0.055, 0.026,
        palette: _armorPair());

    // repulsor glow on the palm
    final glowWorld = center + hand.zAxis * 0.028 - hand.yAxis * 0.008;
    final gp = camera.project(glowWorld, size);
    final gr = 0.017 * gp.scale;
    canvas.drawCircle(
      gp.screen,
      gr * 2.1,
      ui.Paint()
        ..color = JarvisPalette.glow.withValues(alpha: 0.30)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, gr * 1.6),
    );
    canvas.drawCircle(gp.screen, gr, ui.Paint()..color = JarvisPalette.glow.withValues(alpha: 0.85));

    // fingers — 4 capsules fanned across the palm's x axis
    for (var i = 0; i < 4; i++) {
      final t = (i - 1.5) / 1.5; // -1..1
      final baseLocal = Vec3(t * 0.030, -0.048, 0.004);
      final tipLocal = Vec3(t * 0.036, -0.082 - (i == 1 || i == 2 ? 0.006 : 0.0), 0.006);
      final base = center + hand.xAxis * baseLocal.x + hand.yAxis * baseLocal.y + hand.zAxis * baseLocal.z;
      final tip = center + hand.xAxis * tipLocal.x + hand.yAxis * tipLocal.y + hand.zAxis * tipLocal.z;
      _capsule(canvas, size, base, tip, 0.0092, 0.0082);
    }

    // thumb — angled toward the mid-line
    final thumbBase = center + hand.xAxis * (0.044 * mirror) + hand.yAxis * -0.008 + hand.zAxis * 0.006;
    final thumbTip = thumbBase + hand.yAxis * -0.030 + hand.xAxis * (0.020 * mirror);
    _capsule(canvas, size, thumbBase, thumbTip, 0.0105, 0.0088);
  }

  // ==========================================================================
  // Reactor
  // ==========================================================================

  void _reactor(ui.Canvas canvas, Size size, Vec3 world, RenderState st) {
    final p = camera.project(world, size);
    final r = 0.030 * p.scale;
    final pulse = 0.75 + 0.25 * math.sin(st.time * 2.4) + 0.35 * st.listening * st.glowPulse;

    // bloom
    canvas.drawCircle(
      p.screen,
      r * 2.6,
      ui.Paint()
        ..color = JarvisPalette.glow.withValues(alpha: 0.22 * pulse.clamp(0.0, 1.4))
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, r * 1.8),
    );
    // ring
    canvas.drawCircle(
      p.screen,
      r,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = r * 0.34
        ..shader = ui.Gradient.radial(
          p.screen,
          r,
          [const Color(0xFFD9FBFF), JarvisPalette.glow, JarvisPalette.glowSoft],
          const [0.55, 0.82, 1.0],
        ),
    );
    // inner triangle-ish core (three arcs)
    final corePaint = ui.Paint()..color = const Color(0xFFEFFFFF);
    canvas.drawCircle(p.screen, r * 0.34, corePaint);
  }
}

class _DrawCmd {
  final double depth;
  final void Function(ui.Canvas canvas) draw;
  _DrawCmd(this.depth, this.draw);
}

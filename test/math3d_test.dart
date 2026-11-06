import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/character/jarvis_3d/math3d.dart';

void main() {
  group('Vec3', () {
    test('basic arithmetic', () {
      const a = Vec3(1, 2, 3);
      const b = Vec3(4, 5, 6);
      expect((a + b).x, 5);
      expect((b - a).y, 3);
      expect((a * 2).z, 6);
    });

    test('dot/cross/length', () {
      const x = Vec3(1, 0, 0);
      const y = Vec3(0, 1, 0);
      expect(x.dot(y), 0);
      expect(x.cross(y).z, 1);
      expect(const Vec3(3, 4, 0).length, closeTo(5, 1e-9));
    });

    test('normalized of zero vector is zero', () {
      expect(Vec3.zero.normalized().length, 0);
    });
  });

  group('rotateYawPitchRoll', () {
    test('identity rotation preserves the point', () {
      const p = Vec3(0.3, -0.7, 1.1);
      final r = rotateYawPitchRoll(p, 0, 0, 0);
      expect(r.x, closeTo(p.x, 1e-9));
      expect(r.y, closeTo(p.y, 1e-9));
      expect(r.z, closeTo(p.z, 1e-9));
    });

    test('yaw by pi turns +z into -z', () {
      final r = rotateYawPitchRoll(const Vec3(0, 0, 1), math.pi, 0, 0);
      expect(r.z, closeTo(-1, 1e-9));
      expect(r.x, closeTo(0, 1e-9));
    });

    test('pitch by pi/2 brings +y toward +z', () {
      final r = rotateYawPitchRoll(const Vec3(0, 1, 0), 0, math.pi / 2, 0);
      expect(r.z, closeTo(1, 1e-9));
      expect(r.y, closeTo(0, 1e-9));
    });
  });

  group('Camera3D', () {
    final camera = Camera3D(
      position: const Vec3(0, 1.3, 3.0),
      target: const Vec3(0, 1.0, 0),
    );
    const viewport = Size(400, 800);

    test('projecting the target lands near the screen anchor', () {
      final p = camera.project(const Vec3(0, 1.0, 0), viewport);
      expect(p.screen.dx, closeTo(viewport.width / 2, 1.0));
      // target is centered on the 0.46 anchor line
      expect(p.screen.dy, closeTo(viewport.height * 0.46, viewport.height * 0.12));
      expect(p.depth, greaterThan(0));
    });

    test('closer points get a larger perspective scale', () {
      final near = camera.project(const Vec3(0, 1.0, 1.0), viewport);
      final far = camera.project(const Vec3(0, 1.0, -2.0), viewport);
      expect(near.scale, greaterThan(far.scale));
    });

    test('points behind the near plane are clamped, not flipped', () {
      final behind = camera.project(
        const Vec3(0, 1.3, 10.0), // behind the camera (camera looks toward -z direction)
        viewport,
      );
      expect(behind.depth, greaterThan(0));
      expect(behind.scale.isFinite, isTrue);
    });
  });

  group('Spring1D', () {
    test('decays toward the target', () {
      final spring = Spring1D(stiffness: 60, damping: 9);
      spring.impulse(5);
      for (var i = 0; i < 600; i++) {
        spring.update(0, 1 / 120);
      }
      expect(spring.value.abs(), lessThan(0.01));
    });

    test('stays put without impulse', () {
      final spring = Spring1D();
      for (var i = 0; i < 120; i++) {
        spring.update(0, 1 / 60);
      }
      expect(spring.value, 0);
    });
  });

  group('Ease', () {
    test('outBack hits 0 and 1 at the ends', () {
      expect(Ease.outBack(0), closeTo(0, 1e-9));
      expect(Ease.outBack(1), closeTo(1, 1e-9));
    });

    test('outBack overshoots above 1 mid-way', () {
      expect(Ease.outBack(0.7), greaterThan(1.0));
    });

    test('clamp01', () {
      expect(Ease.clamp01(-3), 0);
      expect(Ease.clamp01(0.4), 0.4);
      expect(Ease.clamp01(9), 1);
    });
  });
}

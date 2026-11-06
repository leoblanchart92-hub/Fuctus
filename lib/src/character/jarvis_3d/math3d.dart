/// math3d — minimal 3D math for the JARVIS software renderer.
///
/// World units are meters (character ≈ 1.75 units tall). Y is up, Z toward viewer.
/// Inspired by the projection helpers of louis-cfm/coucou (mRot3 / mProj) but
/// with a full perspective camera so the humanoid has real depth.
library;

import 'dart:math' as math;
import 'dart:ui';

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator -() => Vec3(-x, -y, -z);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  double distanceTo(Vec3 o) => (this - o).length;
  Vec3 normalized() {
    final l = length;
    return l < 1e-9 ? Vec3.zero : this * (1 / l);
  }

  Vec3 lerp(Vec3 o, double t) => Vec3(
        x + (o.x - x) * t,
        y + (o.y - y) * t,
        z + (o.z - z) * t,
      );

  @override
  String toString() => 'Vec3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// Damped spring (Coucou: stiffness 60, damping 9) — used for head follow-through.
class Spring1D {
  double value = 0;
  double velocity = 0;
  double stiffness;
  double damping;

  Spring1D({this.stiffness = 60, this.damping = 9});

  void impulse(double v) => velocity += v;

  double update(double target, double dt) {
    final force = -stiffness * (value - target) - damping * velocity;
    velocity += force * dt;
    value += velocity * dt;
    return value;
  }

  void reset() {
    value = 0;
    velocity = 0;
  }
}

/// Rotate p around Y (yaw), then X (pitch), then Z (roll). Right-handed.
Vec3 rotateYawPitchRoll(Vec3 p, double yaw, double pitch, double roll) {
  // yaw around Y
  final cy = math.cos(yaw), sy = math.sin(yaw);
  var x = p.x * cy + p.z * sy;
  var z = -p.x * sy + p.z * cy;
  var y = p.y;
  // pitch around X
  final cp = math.cos(pitch), sp = math.sin(pitch);
  final y1 = y * cp - z * sp;
  final z1 = y * sp + z * cp;
  y = y1;
  z = z1;
  // roll around Z
  final cr = math.cos(roll), sr = math.sin(roll);
  final x2 = x * cr - y * sr;
  final y2 = x * sr + y * cr;
  return Vec3(x2, y2, z);
}

/// Result of projecting a world point onto the screen plane.
class ProjectedPoint {
  final Offset screen; // pixels
  final double depth; // view-space distance (larger = farther)
  final double scale; // perspective scale factor (1 = camera plane)
  const ProjectedPoint(this.screen, this.depth, this.scale);
}

/// Simple perspective camera that always looks at [target] from [position].
class Camera3D {
  final Vec3 position;
  final Vec3 target;
  final double fovY; // vertical field of view, radians
  final double near;

  Camera3D({
    required this.position,
    required this.target,
    this.fovY = 0.56, // ~32°
    this.near = 0.05,
  });

  /// Camera basis: forward (view direction), right, up.
  late final Vec3 forward = (target - position).normalized();
  late final Vec3 right = forward.cross(const Vec3(0, 1, 0)).normalized();
  late final Vec3 up = right.cross(forward).normalized();

  double focalLength(double viewportHeightPx) =>
      (viewportHeightPx / 2) / math.tan(fovY / 2);

  /// Project a world point. [viewport] is the paint size in pixels.
  ProjectedPoint project(Vec3 world, Size viewport) {
    final rel = world - position;
    var zc = rel.dot(forward); // distance along forward
    if (zc < near) zc = near;
    final xc = rel.dot(right);
    final yc = rel.dot(up);
    final f = focalLength(viewport.height);
    final cx = viewport.width / 2;
    // Headroom: camera is slightly above the target, leaving HUD space below.
    final cy = viewport.height * 0.46;
    return ProjectedPoint(
      Offset(cx + xc * f / zc, cy - yc * f / zc),
      zc,
      f / zc,
    );
  }
}

/// Smooth easing used by gestures (Coucou uses Ease.back for entrances).
class Ease {
  static double outBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final u = t - 1;
    return 1 + c3 * u * u * u + c1 * u * u;
  }

  static double inOut(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

  static double outCubic(double t) {
    final u = 1 - t;
    return 1 - u * u * u;
  }

  static double clamp01(double t) => t.clamp(0.0, 1.0);
}

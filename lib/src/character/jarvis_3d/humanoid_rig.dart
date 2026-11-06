/// humanoid rig — forward kinematics for the JARVIS android skeleton.
///
/// Joints are defined in a tree with rest offsets (meters, y up).
/// Each joint can add Euler offsets (x=pitch, y=yaw, z=roll, radians) relative to
/// its rest pose. Used by the animator to pose the android every frame.
library;

import 'dart:math' as math;

import 'math3d.dart';

/// Column-major 4x4 matrix (minimal, dependency-free).
class Mat4 {
  final List<double> m;
  Mat4._(this.m);

  factory Mat4.identity() => Mat4._([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  factory Mat4.translation(Vec3 t) => Mat4._([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        t.x, t.y, t.z, 1,
      ]);

  factory Mat4.rotationX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Mat4._([1, 0, 0, 0, 0, c, s, 0, 0, -s, c, 0, 0, 0, 0, 1]);
  }

  factory Mat4.rotationY(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Mat4._([c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1]);
  }

  factory Mat4.rotationZ(double a) {
    final c = math.cos(a), s = math.sin(a);
    return Mat4._([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  }

  Mat4 operator *(Mat4 o) {
    final a = m, b = o.m, out = List<double>.filled(16, 0);
    for (var col = 0; col < 4; col++) {
      for (var row = 0; row < 4; row++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[k * 4 + row] * b[col * 4 + k];
        }
        out[col * 4 + row] = sum;
      }
    }
    return Mat4._(out);
  }

  Vec3 transformPoint(Vec3 p) {
    final a = m;
    return Vec3(
      a[0] * p.x + a[4] * p.y + a[8] * p.z + a[12],
      a[1] * p.x + a[5] * p.y + a[9] * p.z + a[13],
      a[2] * p.x + a[6] * p.y + a[10] * p.z + a[14],
    );
  }

  /// Rotation part only (translation ignored).
  Vec3 transformDirection(Vec3 p) {
    final a = m;
    return Vec3(
      a[0] * p.x + a[4] * p.y + a[8] * p.z,
      a[1] * p.x + a[5] * p.y + a[9] * p.z,
      a[2] * p.x + a[6] * p.y + a[10] * p.z,
    );
  }
}

class JointFrame {
  final Vec3 position;
  final Vec3 xAxis, yAxis, zAxis;
  const JointFrame(this.position, this.xAxis, this.yAxis, this.zAxis);
}

/// Per-joint Euler offset from rest pose (radians): x = pitch, y = yaw, z = roll.
class JointRotation {
  final double pitch, yaw, roll;
  const JointRotation({this.pitch = 0, this.yaw = 0, this.roll = 0});
  static const zero = JointRotation();
}

class _JointDef {
  final String name;
  final String? parent;
  final Vec3 restOffset; // in parent's rest frame
  const _JointDef(this.name, this.parent, this.restOffset);
}

/// Skeleton definition (rest pose). Pelvis at y=0.98m, character ≈ 1.61m tall.
const List<_JointDef> kHumanoidJoints = [
  _JointDef('pelvis', null, Vec3(0, 0.98, 0)),
  _JointDef('spine', 'pelvis', Vec3(0, 0.10, 0)),
  _JointDef('chest', 'spine', Vec3(0, 0.16, 0)),
  _JointDef('neck', 'chest', Vec3(0, 0.135, 0)),
  _JointDef('head', 'neck', Vec3(0, 0.115, 0)),
  _JointDef('shoulderR', 'chest', Vec3(0.205, 0.085, 0)),
  _JointDef('elbowR', 'shoulderR', Vec3(0.048, -0.265, 0.012)),
  _JointDef('wristR', 'elbowR', Vec3(0.022, -0.245, 0.012)),
  _JointDef('handR', 'wristR', Vec3(0.004, -0.068, 0.002)),
  _JointDef('shoulderL', 'chest', Vec3(-0.205, 0.085, 0)),
  _JointDef('elbowL', 'shoulderL', Vec3(-0.048, -0.265, 0.012)),
  _JointDef('wristL', 'elbowL', Vec3(-0.022, -0.245, 0.012)),
  _JointDef('handL', 'wristL', Vec3(-0.004, -0.068, 0.002)),
  _JointDef('hipR', 'pelvis', Vec3(0.095, -0.03, 0)),
  _JointDef('kneeR', 'hipR', Vec3(0.012, -0.43, 0.012)),
  _JointDef('ankleR', 'kneeR', Vec3(0.012, -0.425, -0.005)),
  _JointDef('footR', 'ankleR', Vec3(0, -0.045, 0.055)),
  _JointDef('hipL', 'pelvis', Vec3(-0.095, -0.03, 0)),
  _JointDef('kneeL', 'hipL', Vec3(-0.012, -0.43, 0.012)),
  _JointDef('ankleL', 'kneeL', Vec3(-0.012, -0.425, -0.005)),
  _JointDef('footL', 'ankleL', Vec3(0, -0.045, 0.055)),
];

class Skeleton {
  final Map<String, JointFrame> joints;
  const Skeleton(this.joints);

  JointFrame operator [](String name) {
    final j = joints[name];
    if (j == null) {
      throw ArgumentError('Unknown joint: $name');
    }
    return j;
  }
}

/// Forward kinematics. [pose] maps joint name -> Euler offset.
Skeleton buildSkeleton(Map<String, JointRotation> pose) {
  final frames = <String, Mat4>{};
  final result = <String, JointFrame>{};

  // kHumanoidJoints is ordered parent-before-child, safe for one pass.
  for (final def in kHumanoidJoints) {
    final rot = pose[def.name] ?? JointRotation.zero;
    final local = Mat4.translation(def.restOffset) *
        Mat4.rotationY(rot.yaw) *
        Mat4.rotationX(rot.pitch) *
        Mat4.rotationZ(rot.roll);

    final world = def.parent == null ? local : frames[def.parent]! * local;
    frames[def.name] = world;

    // Joint origin in world space:
    final origin = world.transformPoint(Vec3.zero);
    result[def.name] = JointFrame(
      origin,
      world.transformDirection(const Vec3(1, 0, 0)),
      world.transformDirection(const Vec3(0, 1, 0)),
      world.transformDirection(const Vec3(0, 0, 1)),
    );
  }
  return Skeleton(result);
}

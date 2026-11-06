/// animator — turns clock time into a living android.
///
/// Combines procedural idle motion (breathing, sway, gaze wander, blinking),
/// speech-synced visemes, expression blending and one-shot gestures
/// (wave / nod / bow). Pure Dart, fully unit-testable without Flutter.
library;

import 'dart:math' as math;

import 'humanoid_rig.dart';
import 'math3d.dart';

enum JarvisExpression { neutral, smile, thinking, listening, success }

enum JarvisGesture { none, wave, nod, bow }

class HumanoidAnimator {
  // ---- tunables ---------------------------------------------------------
  static const double breathPeriod = 4.6; // seconds
  static const double swayPeriod = 7.3;
  static const double blinkDuration = 0.30;

  double time = 0;

  // ---- eyes / blink ------------------------------------------------------
  double eyeOpen = 1.0; // 0 = closed
  double _blinkClock = -1; // <0 means not blinking
  double _nextBlinkIn = 2.2;

  // ---- head springs (follow-through on impulses) -------------------------
  final Spring1D headYaw = Spring1D(stiffness: 60, damping: 9);
  final Spring1D headPitch = Spring1D(stiffness: 60, damping: 9);

  // ---- gaze ---------------------------------------------------------------
  double gazeYaw = 0.18;
  double gazePitch = 0.02;
  double _gazeTargetYaw = 0.18;
  double _gazeTargetPitch = 0.02;
  double _gazeTimer = 2.0;

  // ---- speech ---------------------------------------------------------------
  bool speaking = false;
  double mouthOpen = 0; // 0 closed .. 1 fully open
  double _speechClock = 0;

  // ---- expressions -----------------------------------------------------------
  JarvisExpression expression = JarvisExpression.neutral;
  final Map<JarvisExpression, double> _weights = {
    for (final e in JarvisExpression.values) e: e == JarvisExpression.neutral ? 1.0 : 0.0,
  };

  double weightOf(JarvisExpression e) => _weights[e] ?? 0;

  // ---- gestures --------------------------------------------------------------
  JarvisGesture _gesture = JarvisGesture.none;
  double _gestureClock = 0;
  bool _nodImpulsed0 = false;
  bool _nodImpulsed1 = false;

  JarvisGesture get currentGesture => _gesture;

  // ---- derived render state --------------------------------------------------
  double breath = 0; // -1..1
  double glowPulse = 0; // listening pulse 0..1

  final math.Random _rng;

  HumanoidAnimator({int? seed}) : _rng = math.Random(seed);

  // ==========================================================================
  // External events
  // ==========================================================================

  void playGesture(JarvisGesture gesture) {
    _gesture = gesture;
    _gestureClock = 0;
    _nodImpulsed0 = false;
    _nodImpulsed1 = false;
    if (gesture == JarvisGesture.nod) {
      headPitch.impulse(2.6);
      _nodImpulsed0 = true;
    }
  }

  void setExpression(JarvisExpression e) => expression = e;

  void startSpeaking() {
    speaking = true;
    _speechClock = 0;
  }

  void stopSpeaking() => speaking = false;

  /// Called by the UI when the user sends a message / Jarvis "notices" them.
  void nudgeHead({double yawImpulse = 0, double pitchImpulse = 0}) {
    headYaw.impulse(yawImpulse);
    headPitch.impulse(pitchImpulse);
  }

  // ==========================================================================
  // Tick
  // ==========================================================================

  void tick(double dt) {
    dt = dt.clamp(0.0, 0.05); // avoid huge steps after app pause
    time += dt;

    // Breathing
    breath = math.sin(time * 2 * math.pi / breathPeriod);

    // Sway + listening glow pulse
    glowPulse = 0.5 + 0.5 * math.sin(time * 2 * math.pi / 1.6);

    // ---- blink state machine ----
    if (_blinkClock >= 0) {
      _blinkClock += dt;
      final u = _blinkClock / blinkDuration;
      if (u >= 1) {
        _blinkClock = -1;
        eyeOpen = 1.0;
        _nextBlinkIn = 2.4 + _rng.nextDouble() * 3.6;
      } else {
        // triangle: close fast, open slightly slower
        eyeOpen = u < 0.38 ? u / 0.38 : 1 - (u - 0.38) / 0.62;
        eyeOpen = 1 - eyeOpen; // 1 -> 0 -> 1
      }
    } else {
      _nextBlinkIn -= dt;
      if (_nextBlinkIn <= 0) {
        _blinkClock = 0;
      }
    }

    // ---- head springs ----
    headYaw.update(0, dt);
    headPitch.update(0, dt);

    // ---- gaze wander ----
    _gazeTimer -= dt;
    if (_gazeTimer <= 0) {
      _gazeTimer = 1.8 + _rng.nextDouble() * 2.4;
      _gazeTargetYaw = (_rng.nextDouble() - 0.5) * 0.66;
      _gazeTargetPitch = (_rng.nextDouble() - 0.5) * 0.30;
    }
    if (expression == JarvisExpression.thinking) {
      _gazeTargetPitch = 0.26; // thoughtful look upward
    } else if (expression == JarvisExpression.listening) {
      _gazeTargetYaw *= 0.4; // focused forward
    }
    final gazeLerp = 1 - math.exp(-3.2 * dt);
    gazeYaw += (_gazeTargetYaw - gazeYaw) * gazeLerp;
    gazePitch += (_gazeTargetPitch - gazePitch) * gazeLerp;

    // ---- mouth / visemes ----
    if (speaking) {
      _speechClock += dt;
      final t = _speechClock;
      final env = (0.62 + 0.38 * math.sin(t * 3.1 + 1.2)) *
          (0.55 + 0.45 * math.sin(t * 7.3 + 0.4));
      final osc = 0.5 + 0.5 * math.sin(t * 13.0);
      final target = (osc * env).clamp(0.0, 1.0);
      mouthOpen += (target - mouthOpen) * (1 - math.exp(-18 * dt));
    } else {
      final smile = _weights[JarvisExpression.smile] ?? 0;
      mouthOpen += ((0.05 + 0.10 * smile) - mouthOpen) * (1 - math.exp(-8 * dt));
    }

    // ---- expression blending ----
    for (final e in JarvisExpression.values) {
      final target = e == expression ? 1.0 : 0.0;
      final cur = _weights[e] ?? 0;
      _weights[e] = cur + (target - cur) * (1 - math.exp(-6 * dt));
    }

    // ---- gesture clock ----
    if (_gesture != JarvisGesture.none) {
      _gestureClock += dt;
      _advanceGesture();
    }
  }

  void _advanceGesture() {
    switch (_gesture) {
      case JarvisGesture.wave:
        if (_gestureClock > 1.9) {
          _gesture = JarvisGesture.none;
        }
      case JarvisGesture.nod:
        if (!_nodImpulsed1 && _gestureClock > 0.26) {
          headPitch.impulse(2.0);
          _nodImpulsed1 = true;
        }
        if (_gestureClock > 1.1) {
          _gesture = JarvisGesture.none;
        }
      case JarvisGesture.bow:
        if (_gestureClock > 1.7) {
          _gesture = JarvisGesture.none;
        }
      case JarvisGesture.none:
        break;
    }
  }

  double get _gestureU => _gestureClock;

  // ==========================================================================
  // Pose building (input for the FK rig)
  // ==========================================================================

  Map<String, JointRotation> buildPose() {
    // --- idle sway ---
    final pelvisYaw = math.sin(time * 2 * math.pi / swayPeriod) * 0.05;
    final pelvisRoll = math.sin(time * 2 * math.pi / (swayPeriod * 0.83) + 0.7) * 0.022;
    final spineYaw = math.sin(time * 2 * math.pi / 5.1 + 1.3) * 0.03;
    final breathPitch = breath * 0.014;
    final chestRise = breath * 0.010; // applied as chest pitch offset

    // --- bow gesture ---
    var spinePitch = breathPitch + 0.012;
    var chestPitch = chestRise;
    if (_gesture == JarvisGesture.bow) {
      const dur = 1.7;
      final u = (_gestureU / dur).clamp(0.0, 1.0);
      final bowCurve = u < 0.5
          ? Ease.inOut(u * 2)
          : Ease.inOut((1 - u) * 2);
      spinePitch += bowCurve * 0.42;
      chestPitch += bowCurve * 0.30;
    }

    // --- head: gaze + springs + micro drift ---
    final headYawTotal = gazeYaw * 0.55 + headYaw.value * 0.35 +
        math.sin(time * 2 * math.pi / 9.0) * 0.02;
    final headPitchTotal = -gazePitch * 0.55 + headPitch.value * 0.35 - 0.02;
    final headRoll = math.sin(time * 2 * math.pi / 6.7 + 0.4) * 0.018;

    // --- thinking pose: head tilt ---
    var thinkRoll = 0.0;
    var thinkPitch = 0.0;
    final think = _weights[JarvisExpression.thinking] ?? 0;
    if (think > 0.01) {
      thinkRoll = 0.10 * think;
      thinkPitch = -0.06 * think;
    }

    // --- wave gesture ---
    var shoulderR = JointRotation.zero;
    var elbowR = JointRotation(pitch: 0.0);
    var wristR = JointRotation.zero;
    if (_gesture == JarvisGesture.wave) {
      const dur = 1.9;
      final u = (_gestureU / dur).clamp(0.0, 1.0);
      double raise;
      if (u < 0.18) {
        raise = Ease.outBack(u / 0.18);
      } else if (u < 0.80) {
        raise = 1.0;
      } else {
        raise = Ease.inOut(1 - (u - 0.80) / 0.20);
      }
      final osc = (u > 0.18 && u < 0.80)
          ? math.sin((u - 0.18) / 0.62 * math.pi * 6) * 0.42
          : 0.0;
      shoulderR = JointRotation(roll: raise * 2.05, pitch: -raise * 0.25, yaw: -raise * 0.2);
      elbowR = JointRotation(pitch: -raise * 1.15 + osc * 0.35, roll: osc);
      wristR = JointRotation(roll: osc * 0.6);
    } else {
      // relaxed arms with subtle breathing motion
      shoulderR = JointRotation(roll: 0.06 + breath * 0.008);
      shoulderR = JointRotation(roll: shoulderR.roll, pitch: 0.02);
    }

    final shoulderL = JointRotation(roll: -0.06 - breath * 0.008, pitch: 0.02);
    final elbowL = JointRotation(pitch: -0.12);

    // right arm resting bend when not waving
    if (_gesture != JarvisGesture.wave) {
      elbowR = JointRotation(pitch: -0.14);
      wristR = JointRotation.zero;
    }

    // --- legs: mostly planted, tiny weight shift ---
    final hipRoll = pelvisRoll * 0.5;

    return {
      'pelvis': JointRotation(yaw: pelvisYaw, roll: pelvisRoll),
      'spine': JointRotation(yaw: spineYaw, pitch: spinePitch),
      'chest': JointRotation(yaw: spineYaw * 0.6, pitch: chestPitch),
      'neck': JointRotation(yaw: headYawTotal * 0.4, pitch: 0.01 + chestPitch * 0.5),
      'head': JointRotation(yaw: headYawTotal * 0.75, pitch: headPitchTotal + thinkPitch, roll: headRoll + thinkRoll),
      'shoulderR': shoulderR,
      'elbowR': elbowR,
      'wristR': wristR,
      'shoulderL': shoulderL,
      'elbowL': elbowL,
      'hipR': JointRotation(roll: -hipRoll),
      'hipL': JointRotation(roll: -hipRoll),
    };
  }
}

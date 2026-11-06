import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/character/jarvis_3d/animator.dart';
import 'package:jarvis_ai/src/character/jarvis_3d/humanoid_rig.dart';

void main() {
  group('FK rig — rest pose', () {
    final sk = buildSkeleton(const {});

    test('pelvis near the design height', () {
      expect(sk['pelvis'].position.y, closeTo(0.98, 1e-9));
    });

    test('head above chest above pelvis', () {
      expect(sk['head'].position.y, greaterThan(sk['chest'].position.y));
      expect(sk['chest'].position.y, greaterThan(sk['pelvis'].position.y));
    });

    test('feet at ground level and below knees', () {
      expect(sk['ankleR'].position.y, lessThan(sk['kneeR'].position.y));
      expect(sk['footR'].position.y, lessThan(0.09));
      expect(sk['footL'].position.y, lessThan(0.09));
    });

    test('wrists below elbows below shoulders', () {
      expect(sk['wristR'].position.y, lessThan(sk['elbowR'].position.y));
      expect(sk['elbowR'].position.y, lessThan(sk['shoulderR'].position.y));
      expect(sk['handR'].position.y, lessThan(sk['wristR'].position.y));
    });

    test('left and right sides are symmetric', () {
      expect(sk['shoulderL'].position.x, closeTo(-sk['shoulderR'].position.x, 1e-9));
      expect(sk['hipL'].position.x, closeTo(-sk['hipR'].position.x, 1e-9));
    });

    test('unknown joint throws', () {
      expect(() => sk['nope'], throwsArgumentError);
    });
  });

  group('FK rig — posed', () {
    test('raising the right shoulder (roll 2.0) lifts the hand above the shoulder', () {
      final rest = buildSkeleton(const {});
      final posed = buildSkeleton(const {'shoulderR': JointRotation(roll: 2.0)});
      expect(posed['handR'].position.y, greaterThan(rest['handR'].position.y + 0.35));
    });

    test('pelvis yaw rotates children around the pelvis', () {
      final posed = buildSkeleton(const {'pelvis': JointRotation(yaw: 1.0)});
      // chest must swing around z≈0 axis through pelvis origin
      expect(posed['chest'].position.x.abs(), greaterThan(0.05));
    });
  });

  group('HumanoidAnimator', () {
    test('tick advances time and keeps eyeOpen inside [0, 1]', () {
      final a = HumanoidAnimator(seed: 1);
      for (var i = 0; i < 1200; i++) {
        a.tick(1 / 60);
        expect(a.eyeOpen, inInclusiveRange(0.0, 1.0));
      }
      expect(a.time, closeTo(20.0, 0.1));
    });

    test('a blink is eventually triggered', () {
      final a = HumanoidAnimator(seed: 2);
      var sawBlink = false;
      for (var i = 0; i < 60 * 10; i++) {
        a.tick(1 / 60);
        if (a.eyeOpen < 0.55) {
          sawBlink = true;
          break;
        }
      }
      expect(sawBlink, isTrue);
    });

    test('speaking opens the mouth; stopping closes it again', () {
      final a = HumanoidAnimator(seed: 3);
      a.startSpeaking();
      for (var i = 0; i < 90; i++) {
        a.tick(1 / 60);
      }
      expect(a.mouthOpen, greaterThan(0.08));
      a.stopSpeaking();
      for (var i = 0; i < 600; i++) {
        a.tick(1 / 60);
      }
      expect(a.mouthOpen, lessThan(0.15));
    });

    test('expression weight converges toward 1 for the active expression', () {
      final a = HumanoidAnimator(seed: 4);
      a.setExpression(JarvisExpression.thinking);
      for (var i = 0; i < 600; i++) {
        a.tick(1 / 60);
      }
      expect(a.weightOf(JarvisExpression.thinking), greaterThan(0.9));
    });

    test('wave gesture auto-completes back to idle', () {
      final a = HumanoidAnimator(seed: 5);
      a.playGesture(JarvisGesture.wave);
      expect(a.currentGesture, JarvisGesture.wave);
      for (var i = 0; i < 60 * 3; i++) {
        a.tick(1 / 60);
      }
      expect(a.currentGesture, JarvisGesture.none);
    });

    test('buildPose produces all core joints', () {
      final a = HumanoidAnimator(seed: 6);
      a.tick(1 / 60);
      final pose = a.buildPose();
      for (final joint in [
        'pelvis', 'spine', 'chest', 'neck', 'head',
        'shoulderR', 'elbowR', 'wristR', 'shoulderL', 'elbowL',
        'hipR', 'hipL',
      ]) {
        expect(pose.containsKey(joint), isTrue, reason: 'missing joint $joint');
      }
    });
  });
}

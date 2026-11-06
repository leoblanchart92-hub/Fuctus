import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/core/calculator_engine.dart';

void main() {
  double eval(String s) => CalculatorEngine.evaluate(s);

  group('CalculatorEngine', () {
    test('basic arithmetic & precedence', () {
      expect(eval('2+3*4'), 14);
      expect(eval('(2+3)*4'), 20);
      expect(eval('100/4'), 25);
      expect(eval('7%3'), 1);
    });

    test('unary minus and French decimals', () {
      expect(eval('-5+3'), -2);
      expect(eval('3,5+1'), 4.5);
      expect(eval('--7'), 7);
    });

    test('power is right-associative', () {
      expect(eval('2^3^2'), 512);
      expect(eval('2^10'), 1024);
    });

    test('constants and functions', () {
      expect(eval('sqrt(16)'), 4);
      expect(eval('abs(-9)'), 9);
      expect(eval('sin(90)'), closeTo(1, 1e-9));
      expect(eval('cos(0)'), closeTo(1, 1e-9));
      expect(eval('log(100)'), closeTo(2, 1e-9));
      expect(eval('pi'), closeTo(3.14159, 1e-4));
    });

    test('unicode operators', () {
      expect(eval('6×7'), 42);
      expect(eval('84÷2'), 42);
      expect(eval('10−4'), 6);
    });

    test('division by zero throws', () {
      expect(() => eval('1/0'), throwsA(isA<CalculatorException>()));
    });

    test('garbage throws', () {
      expect(() => eval('hello world'), throwsA(isA<CalculatorException>()));
      expect(() => eval('2+'), throwsA(isA<CalculatorException>()));
    });
  });
}

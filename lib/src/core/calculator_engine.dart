/// Tiny, safe arithmetic evaluator (recursive descent).
/// Supports: + - * / % ^ ( ) , unary minus, decimals with . or ,,
/// constants pi & e, functions sqrt, abs, sin, cos, tan, exp, ln, log, floor, ceil.
/// No eval, no injection risk.
library;

import 'dart:math' as math;

class CalculatorException implements Exception {
  final String message;
  const CalculatorException(this.message);
  @override
  String toString() => message;
}

class CalculatorEngine {
  static double evaluate(String rawInput) {
    final input = _normalize(rawInput);
    final parser = _Parser(input);
    final value = parser.parseExpression();
    parser.expectEnd();
    if (value.isNaN || value.isInfinite) {
      throw const CalculatorException('Résultat non défini (division par zéro ?)');
    }
    return value;
  }

  static String _normalize(String s) {
    var out = s
        .replaceAll('×', '*')
        .replaceAll('⋅', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')   // −
        .replaceAll('–', '-')   // –
        .replaceAll('^', '^')
        .replaceAll(',', '.'); // French decimals
    // strip common French wrappers
    out = out.replaceAll(RegExp(r'\s+'), '');
    return out;
  }
}

class _Parser {
  final String s;
  int pos = 0;
  _Parser(this.s);

  void expectEnd() {
    if (pos < s.length) {
      throw CalculatorException('Symbole inattendu « ${s[pos]} » en position $pos');
    }
  }

  double parseExpression() {
    var value = parseTerm();
    while (_peek('+') || _peek('-')) {
      if (_take('+')) {
        value += parseTerm();
      } else {
        _take('-');
        value -= parseTerm();
      }
    }
    return value;
  }

  double parseTerm() {
    var value = parseUnary();
    while (true) {
      if (_take('*')) {
        value *= parseUnary();
      } else if (_take('/')) {
        final divisor = parseUnary();
        if (divisor == 0) throw const CalculatorException('Division par zéro');
        value /= divisor;
      } else if (_take('%')) {
        final divisor = parseUnary();
        if (divisor == 0) throw const CalculatorException('Modulo par zéro');
        value %= divisor;
      } else {
        break;
      }
    }
    return value;
  }

  double parseUnary() {
    if (_take('-')) return -parseUnary();
    if (_take('+')) return parseUnary();
    return parsePower();
  }

  double parsePower() {
    final base = parsePrimary();
    if (_take('^')) {
      final exponent = parseUnary(); // right-associative
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double parsePrimary() {
    if (_take('(')) {
      final value = parseExpression();
      if (!_take(')')) {
        throw const CalculatorException('Parenthèse fermante manquante');
      }
      return value;
    }

    final func = _tryParseFunctionName();
    if (func != null) {
      if (!_take('(')) {
        throw CalculatorException('« $func » attend des parenthèses');
      }
      final arg = parseExpression();
      if (!_take(')')) {
        throw const CalculatorException('Parenthèse fermante manquante après $func');
      }
      switch (func) {
        case 'sqrt':
          if (arg < 0) throw const CalculatorException('Racine carrée d’un nombre négatif');
          return math.sqrt(arg);
        case 'abs':
          return arg.abs();
        case 'sin':
          return math.sin(arg * math.pi / 180); // degrés, plus naturel à l'oral
        case 'cos':
          return math.cos(arg * math.pi / 180);
        case 'tan':
          return math.tan(arg * math.pi / 180);
        case 'exp':
          return math.exp(arg);
        case 'ln':
          if (arg <= 0) throw const CalculatorException('ln d’un nombre ≤ 0');
          return math.log(arg);
        case 'log':
          if (arg <= 0) throw const CalculatorException('log d’un nombre ≤ 0');
          return math.log(arg) / math.ln10;
        case 'floor':
          return arg.floorToDouble();
        case 'ceil':
          return arg.ceilToDouble();
        default:
          throw CalculatorException('Fonction inconnue « $func »');
      }
    }

    return _parseNumberOrConstant();
  }

  String? _tryParseFunctionName() {
    const functions = ['sqrt', 'abs', 'sin', 'cos', 'tan', 'exp', 'ln', 'log', 'floor', 'ceil'];
    for (final f in functions) {
      if (s.startsWith(f, pos)) {
        pos += f.length;
        return f;
      }
    }
    return null;
  }

  double _parseNumberOrConstant() {
    if (s.startsWith('pi', pos)) {
      pos += 2;
      return math.pi;
    }
    if (s.startsWith('e', pos)) {
      final next = pos + 1 < s.length ? s.codeUnitAt(pos + 1) : 0;
      final isLetter = (next >= 97 && next <= 122) || (next >= 65 && next <= 90);
      if (!isLetter) {
        pos += 1;
        return math.e;
      }
    }

    final match = RegExp(r'^\d+(\.\d+)?([eE][+-]?\d+)?').firstMatch(s.substring(pos));
    if (match == null) {
      final rest = s.substring(pos);
      throw CalculatorException('Nombre attendu, trouvé « ${rest.isEmpty ? "fin de l’expression" : rest} »');
    }
    pos += match.end;
    return double.parse(match.group(0)!);
  }

  bool _peek(String c) => pos < s.length && s[pos] == c;

  bool _take(String c) {
    if (_peek(c)) {
      pos++;
      return true;
    }
    return false;
  }
}

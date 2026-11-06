/// CalculatorSkill — évaluation sécurisée d'expressions arithmétiques.
library;

import '../core/calculator_engine.dart';
import 'skill.dart';

class CalculatorSkill extends JarvisSkill {
  @override
  String get id => 'calculator';

  @override
  String get name => 'Calculatrice';

  @override
  String get description => 'Évalue des expressions : +, −, ×, ÷, ^, %, parenthèses, pi, sqrt, sin/cos/tan (degrés).';

  @override
  List<String> get examplePhrases =>
      const ['Combien font 17 fois 23 ?', 'Calcule sqrt(2) * 10', '2^10', '15% de 240'];

  @override
  bool canHandle(String utterance) {
    if (RegExp(r'(calcul|calcule|combien font|resultat de|how much is|compute)').hasMatch(utterance)) {
      return true;
    }
    // bare expression
    return RegExp(r'^[\d\s+\-*/×÷x^%().,piseqrtablnoacefloorcil]+$').hasMatch(utterance) &&
        RegExp(r'\d').hasMatch(utterance) &&
        RegExp(r'[+\-*/×÷^%]').hasMatch(utterance);
  }

  @override
  Future<SkillResult> handle(String utterance, SkillContext context) async {
    var expr = utterance;
    // strip French lead-ins: "calcule ...", "combien font ..."
    expr = expr.replaceAll(
      RegExp(r'^(calcule|calcul(e)?|combien font|combien fait|r[eé]sultat de|how much is|compute)\s*:?\s*',
          caseSensitive: false),
      '',
    );
    // "15% de 240" → "15% * 240" (interpreted as percent-of)
    expr = expr.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*%\s*(de|of|x|\*)\s*(\d+(?:[.,]\d+)?)'),
      (m) => '${m.group(1)} / 100 * ${m.group(3)}',
    );
    // French multiplication word "fois": "17 fois 23" → "17 * 23"
    expr = expr.replaceAllMapped(
      RegExp(r'(\d+(?:[.,]\d+)?)\s*fois\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      (m) => '${m.group(1)} * ${m.group(2)}',
    );
    // "x" as multiplication when surrounded by digits
    expr = expr.replaceAllMapped(
      RegExp(r'(\d)\s*[xX]\s*(\d)'),
      (m) => '${m.group(1)} * ${m.group(2)}',
    );
    // drop anything that is not math (question marks, quotes…)
    expr = expr.replaceAll(RegExp(r'[^0-9a-zA-Z+\-*/×÷^%()., ]'), ' ');
    expr = expr.trim();
    if (expr.isEmpty) {
      return const SkillResult('Quelle expression souhaitez-vous que je calcule ?', isError: true);
    }
    try {
      final value = CalculatorEngine.evaluate(expr);
      final formatted = value == value.roundToDouble() && value.abs() < 1e15
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'[.,]$'), '');
      return SkillResult('Le résultat est $formatted.');
    } on CalculatorException catch (e) {
      return SkillResult('Je ne parviens pas à évaluer cela : ${e.message}', isError: true);
    }
  }
}

/// TimeSkill — heure & date locales.
library;

import 'skill.dart';

class TimeSkill extends JarvisSkill {
  @override
  String get id => 'time';

  @override
  String get name => 'Heure & date';

  @override
  String get description => 'Donne l’heure et la date locales avec élégance.';

  @override
  List<String> get examplePhrases => const ['Quelle heure est-il ?', 'Quel jour sommes-nous ?', 'On est le combien ?'];

  static const _days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  @override
  bool canHandle(String utterance) =>
      RegExp(r'(quelle heure|il est quelle heure|heure est.il|quel jour|on est (le )?combien|quelle est la date|la date du jour|the time|what day)').hasMatch(utterance);

  @override
  Future<SkillResult> handle(String utterance, SkillContext context) async {
    final now = DateTime.now();
    final time = '${now.hour}h${now.minute.toString().padLeft(2, '0')}';
    final date = '${_days[now.weekday - 1]} ${now.day} ${_months[now.month - 1]} ${now.year}';
    return SkillResult('Il est $time, nous sommes le $date.');
  }
}

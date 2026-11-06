/// MemoryQuerySkill — « Que sais-tu de moi ? »
library;

import 'skill.dart';

class MemoryQuerySkill extends JarvisSkill {
  @override
  String get id => 'memory';

  @override
  String get name => 'Mémoire';

  @override
  String get description => 'Récite ce que JARVIS sait durablement sur vous.';

  @override
  List<String> get examplePhrases => const ['Que sais-tu de moi ?', 'Qu’as-tu en mémoire ?'];

  @override
  bool canHandle(String utterance) =>
      RegExp(r'(que sais.tu de moi|qu as.tu en memoire|ta memoire|what do you know about me|qu\'as tu retenu)').hasMatch(utterance);

  @override
  Future<SkillResult> handle(String utterance, SkillContext context) async {
    final memories = await context.memory.all(limit: 25);
    if (memories.isEmpty) {
      return const SkillResult(
        'Ma mémoire est encore vierge, monsieur. Dites « souviens-toi que … » et je n’oublierai plus rien.',
      );
    }
    final buffer = StringBuffer('Voici ce que je sais de vous :\n');
    for (var i = 0; i < memories.length; i++) {
      buffer.writeln('${i + 1}. ${memories[i].content}');
    }
    return SkillResult(buffer.toString().trim());
  }
}

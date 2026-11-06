/// NotesSkill — « Note : acheter du lait » / « Mes notes ».
/// Notes are stored as kind='note' in persistent memory.
library;

import 'skill.dart';

class NotesSkill extends JarvisSkill {
  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

  @override
  String get description => 'Enregistre et restitue des notes rapides, persistées sur l’appareil.';

  @override
  List<String> get examplePhrases => const ['Note : appeler le plombier demain', 'Mes notes', 'Efface mes notes'];

  @override
  bool canHandle(String utterance) =>
      RegExp(r'^(note\b|note:|note :|prends note|enregistre( cette note)?|mes notes|liste mes notes|affiche mes notes|efface mes notes|supprime mes notes)').hasMatch(utterance);

  @override
  Future<SkillResult> handle(String utterance, SkillContext context) async {
    if (RegExp(r'(mes notes|liste mes notes|affiche mes notes)').hasMatch(utterance)) {
      final notes = await context.memory.search('note', limit: 50);
      final actual = notes.where((n) => n.kind == 'note').take(10).toList();
      if (actual.isEmpty) {
        return const SkillResult('Aucune note enregistrée pour l’instant. Dites « Note : … » pour commencer.');
      }
      final buffer = StringBuffer('Voici vos ${actual.length} dernière(s) note(s) :\n');
      for (var i = 0; i < actual.length; i++) {
        buffer.writeln('${i + 1}. ${actual[i].content}');
      }
      return SkillResult(buffer.toString().trim());
    }

    if (RegExp(r'(efface|supprime) mes notes').hasMatch(utterance)) {
      final notes = await context.memory.search('note', limit: 100);
      var deleted = 0;
      for (final n in notes.where((n) => n.kind == 'note')) {
        final id = n.id;
        if (id != null) {
          await context.memory.delete(id);
          deleted++;
        }
      }
      return SkillResult('$deleted note(s) effacée(s). La mémoire est propre.');
    }

    // capture: strip the lead-in
    var content = utterance.replaceFirst(
      RegExp(r'^(note|prends note|enregistre cette note|enregistre)\s*:?\s*', caseSensitive: false),
      '',
    ).trim();
    if (content.isEmpty) {
      return const SkillResult('Que souhaitez-vous que je retienne ?', isError: true);
    }
    await context.memory.remember(content: content, kind: 'note', importance: 2);
    return SkillResult('Bien noté : « $content ». C’est dans ma mémoire persistante.');
  }
}

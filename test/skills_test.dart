import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/memory/memory_repository.dart';
import 'package:jarvis_ai/src/memory/memory_store.dart';
import 'package:jarvis_ai/src/skills/skill.dart';
import 'package:jarvis_ai/src/skills/skill_registry.dart';
import 'package:jarvis_ai/src/skills/time_skill.dart';
import 'package:jarvis_ai/src/skills/calculator_skill.dart';
import 'package:jarvis_ai/src/skills/weather_skill.dart';
import 'package:jarvis_ai/src/skills/notes_skill.dart';
import 'package:jarvis_ai/src/skills/memory_query_skill.dart';

void main() {
  late MemoryRepository memory;
  late SkillContext context;

  setUp(() async {
    memory = MemoryRepository(InMemoryMemoryStore());
    await memory.init();
    context = SkillContext(memory: memory, defaultCity: 'Strasbourg', languageCode: 'fr');
  });

  group('TimeSkill', () {
    test('claims time questions', () {
      expect(TimeSkill().canHandle('quelle heure est-il'), isTrue);
      expect(TimeSkill().canHandle('quel jour sommes-nous'), isTrue);
      expect(TimeSkill().canHandle('raconte une blague'), isFalse);
    });

    test('answers with time and date', () async {
      final result = await TimeSkill().handle('quelle heure est-il', context);
      expect(result.text, contains('h'));
      expect(result.text.toLowerCase(), contains(RegExp(r'janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre')));
    });
  });

  group('CalculatorSkill', () {
    test('handles « combien font »', () async {
      final result = await CalculatorSkill().handle('combien font 25*4 ?', context);
      expect(result.text, contains('100'));
      expect(result.isError, isFalse);
    });

    test('handles « 17 fois 23 »', () async {
      final result = await CalculatorSkill().handle('combien font 17 fois 23', context);
      expect(result.text, contains('391'));
    });

    test('handles percent-of phrasing', () async {
      final result = await CalculatorSkill().handle('calcule 15% de 240', context);
      expect(result.text, contains('36'));
    });

    test('garbage yields a polite error, not a crash', () async {
      final result = await CalculatorSkill().handle('calcule blablabla', context);
      expect(result.isError, isTrue);
    });
  });

  group('WeatherSkill', () {
    test('claims meteo utterances and extracts the city', () async {
      final skill = WeatherSkill();
      expect(skill.canHandle('meteo a strasbourg'), isTrue);
      expect(skill.canHandle('quel temps fait-il a paris'), isTrue);
      expect(skill.canHandle('donne-moi joke'), isFalse);
    });
  });

  group('NotesSkill', () {
    test('stores a note and lists it back', () async {
      final skill = NotesSkill();
      final added = await skill.handle('Note : acheter du lait', context);
      expect(added.text, contains('acheter du lait'));

      final list = await skill.handle('Mes notes', context);
      expect(list.text, contains('acheter du lait'));
    });

    test('deleting notes empties the list', () async {
      final skill = NotesSkill();
      await skill.handle('Note : truc indispensable', context);
      await skill.handle('Efface mes notes', context);
      final list = await skill.handle('Mes notes', context);
      expect(list.text.toLowerCase(), contains('aucune note'));
    });
  });

  group('MemoryQuerySkill', () {
    test('empty memory produces the blank-page message', () async {
      final result = await MemoryQuerySkill().handle('que sais-tu de moi', context);
      expect(result.text.toLowerCase(), contains('vierge'));
    });

    test('known facts are recited', () async {
      await memory.remember(content: 'Louis aime le thé à la menthe', kind: 'fact', importance: 4);
      final result = await MemoryQuerySkill().handle('que sais-tu de moi', context);
      expect(result.text, contains('thé à la menthe'));
    });
  });

  group('SkillRegistry', () {
    test('finds a skill for a time question', () {
      final registry = SkillRegistry();
      expect(registry.findFor('quelle heure est-il'), isA<TimeSkill>());
    });

    test('dispatch returns null when nothing matches', () async {
      final registry = SkillRegistry();
      final result = await registry.dispatch('explique la relativité générale', context);
      expect(result, isNull);
    });

    test('dispatch routes calculator questions end to end', () async {
      final registry = SkillRegistry();
      final result = await registry.dispatch('combien font 6*7', context);
      expect(result, isNotNull);
      expect(result!.text, contains('42'));
    });
  });
}

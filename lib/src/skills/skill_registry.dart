/// Skill registry — routes an utterance to the first skill that claims it.
library;

import 'skill.dart';
import 'time_skill.dart';
import 'calculator_skill.dart';
import 'weather_skill.dart';
import 'notes_skill.dart';
import 'memory_query_skill.dart';
import '../memory/memory_store.dart' show normalizeForSearch;

class SkillRegistry {
  final List<JarvisSkill> skills;

  SkillRegistry([List<JarvisSkill>? skills])
      : skills = skills ?? builtins();

  static List<JarvisSkill> builtins() => [
        TimeSkill(),
        CalculatorSkill(),
        WeatherSkill(),
        NotesSkill(),
        MemoryQuerySkill(),
      ];

  /// Returns the skill that can handle [utterance], or null.
  JarvisSkill? findFor(String utterance) {
    final norm = normalizeForSearch(utterance);
    for (final skill in skills) {
      if (skill.canHandle(norm)) return skill;
    }
    return null;
  }

  /// Runs the matching skill, or returns null when no skill applies.
  Future<SkillResult?> dispatch(String utterance, SkillContext context) async {
    final norm = normalizeForSearch(utterance);
    for (final skill in skills) {
      if (!skill.canHandle(norm)) continue;
      try {
        return await skill.handle(utterance, context);
      } catch (e) {
        return SkillResult('Le module « ${skill.name} » a trébuché : $e', isError: true);
      }
    }
    return null;
  }
}

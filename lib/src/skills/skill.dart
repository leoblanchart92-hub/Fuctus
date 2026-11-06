/// Skills — JARVIS's extensible capability system.
///
/// To add a new skill:
///   1. subclass [JarvisSkill]
///   2. register it in SkillRegistry.builtins (or your own registry)
/// No other wiring required — the conversation engine consults the registry
/// before falling back to the AI provider.
library;

import '../memory/memory_repository.dart';

class SkillContext {
  final MemoryRepository memory;
  final String defaultCity;
  final String languageCode; // 'fr' | 'en'

  const SkillContext({
    required this.memory,
    this.defaultCity = 'Strasbourg',
    this.languageCode = 'fr',
  });
}

class SkillResult {
  final String text;
  final String? detail; // optional structured payload (list of lines etc.)
  final bool isError;

  const SkillResult(this.text, {this.detail, this.isError = false});
}

abstract class JarvisSkill {
  /// Stable machine identifier (e.g. 'weather').
  String get id;

  /// Display name (e.g. 'Météo').
  String get name;

  /// One-line description of what the skill does.
  String get description;

  /// Example utterances shown in the Compétences screen.
  List<String> get examplePhrases;

  /// Must be cheap (no network) — used to route the utterance.
  bool canHandle(String utterance);

  Future<SkillResult> handle(String utterance, SkillContext context);
}

import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/memory/memory_entry.dart';
import 'package:jarvis_ai/src/persona/jarvis_persona.dart';

void main() {
  final memories = [
    MemoryEntry(
      id: 1,
      kind: 'fact',
      content: 'Louis aime le thé à la menthe',
      keywords: 'louis,aime,the,menthe',
      importance: 4,
      createdAt: DateTime.now(),
    ),
  ];

  test('system prompt includes identity, date anchor and memory facts', () {
    final prompt = JarvisPersona.buildSystemPrompt(
      userName: 'Louis',
      userTitle: 'monsieur',
      memories: memories,
    );
    expect(prompt, contains('JARVIS'));
    expect(prompt, contains('Louis'));
    expect(prompt, contains('thé à la menthe'));
    expect(prompt.toLowerCase(), contains('date et heure'));
  });

  test('empty memory yields the blank-slate hint', () {
    final prompt = JarvisPersona.buildSystemPrompt(
      userName: '',
      userTitle: 'monsieur',
      memories: const [],
    );
    expect(prompt, contains('mémoire ne contient encore rien'));
  });

  test('persona enforces French and brevity defaults', () {
    final prompt = JarvisPersona.buildSystemPrompt(
      userName: 'Ada',
      userTitle: 'madame',
      memories: const [],
    );
    expect(prompt.toLowerCase(), contains('français'));
    expect(prompt.toLowerCase(), contains('courtes'));
  });
}

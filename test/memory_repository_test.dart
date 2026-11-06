import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/memory/memory_repository.dart';
import 'package:jarvis_ai/src/memory/memory_store.dart';

void main() {
  late MemoryRepository memory;

  setUp(() async {
    memory = MemoryRepository(InMemoryMemoryStore());
    await memory.init();
  });

  test('remember stores and counts entries', () async {
    await memory.remember(content: 'Louis aime le thé à la menthe', importance: 4);
    await memory.remember(content: 'Louis travaille chez Acme', importance: 3);
    expect(await memory.count(), 2);
  });

  test('keywords of strips stopwords and accents', () {
    final kw = MemoryRepository.keywordsOf('J’aime beaucoup le thé à la menthe');
    final tokens = kw.split(',');
    expect(tokens.any((t) => t.contains('menthe')), isTrue);
    expect(tokens.length, lessThanOrEqualTo(24));
  });

  test('search is accent-insensitive', () async {
    await memory.remember(content: 'Préfère les pâtes à la carbonara');
    final hits = await memory.search('pates carbonara');
    expect(hits, isNotEmpty);
    expect(hits.first.content, contains('carbonara'));
  });

  test('relevant ranks keyword matches above unrelated memories', () async {
    await memory.remember(content: 'Louis aime le jazz et le piano', importance: 3);
    await memory.remember(content: 'Louis déteste les épinards', importance: 3);
    await memory.remember(content: 'Louis habite à Strasbourg', importance: 3);

    final hits = await memory.relevant('parle-moi de son goût pour la musique et le jazz', limit: 2);
    expect(hits.map((h) => h.content).join(' '), contains('jazz'));
  });

  test('delete and clear work', () async {
    final entry = await memory.remember(content: 'souvenir à oublier');
    final id = entry.id!;
    await memory.delete(id);
    expect(await memory.count(), 0);

    await memory.remember(content: 'un autre');
    await memory.clear();
    expect(await memory.count(), 0);
  });

  test('normalizeForSearch strips accents and punctuation', () {
    expect(normalizeForSearch('Éléphant, ça!'), 'elephant ca');
    expect(normalizeForSearch('  Plusieurs   espaces '), 'plusieurs espaces');
  });
}

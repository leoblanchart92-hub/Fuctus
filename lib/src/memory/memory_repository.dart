/// MemoryRepository — domain-level memory operations used by the conversation
/// engine and the UI. Retrieval blends keyword overlap, importance and recency.
library;

import 'memory_entry.dart';
import 'memory_store.dart';

class MemoryRepository {
  final MemoryStore store;
  MemoryRepository(this.store);

  Future<void> init() => store.open();

  static const _stopWords = {
    // français
    'le', 'la', 'les', 'un', 'une', 'des', 'de', 'du', 'et', 'en', 'est',
    'a', 'au', 'aux', 'que', 'qui', 'quoi', 'dont', 'dans', 'sur', 'pour',
    'par', 'avec', 'sans', 'sous', 'chez', 'entre', 'vers', 'je', 'tu',
    'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'mon', 'ma', 'mes',
    'ton', 'ta', 'tes', 'son', 'sa', 'ses', 'notre', 'nos', 'votre', 'vos',
    'leur', 'leurs', 'ce', 'cet', 'cette', 'ces', 'se', 'me', 'te', 'y',
    'j', 'n', 'qu', 'l', 'c', 's', 'd', 'm', 't', 'pas', 'plus', 'tres',
    // anglais
    'the', 'a', 'an', 'of', 'to', 'in', 'on', 'at', 'for', 'with', 'is',
    'are', 'was', 'were', 'my', 'your', 'his', 'her', 'our', 'their', 'it',
  };

  /// Extracts up to 24 meaningful keywords from free text.
  static String keywordsOf(String content) {
    final normalized = normalizeForSearch(content);
    final seen = <String>{};
    for (final token in normalized.split(' ')) {
      if (token.length < 3 || _stopWords.contains(token)) continue;
      seen.add(token);
      if (seen.length >= 24) break;
    }
    return seen.join(',');
  }

  Future<MemoryEntry> remember({
    required String content,
    String kind = 'fact',
    int importance = 3,
  }) async {
    final entry = MemoryEntry(
      kind: kind,
      content: content.trim(),
      keywords: keywordsOf(content),
      importance: importance.clamp(1, 5),
      createdAt: DateTime.now(),
    );
    final id = await store.insert(entry);
    return entry.copyWith(id: id);
  }

  Future<List<MemoryEntry>> all({int limit = 200}) => store.all(limit: limit);

  Future<List<MemoryEntry>> search(String query, {int limit = 20}) =>
      store.search(normalizeForSearch(query), limit: limit);

  Future<int> count() => store.count();
  Future<void> delete(int id) => store.delete(id);
  Future<void> clear() => store.clear();

  /// Picks the most relevant memories for a user utterance.
  Future<List<MemoryEntry>> relevant(String userText, {int limit = 6}) async {
    final normalized = normalizeForSearch(userText);
    final tokens = normalized.split(' ').where((t) => t.length > 2 && !_stopWords.contains(t)).toList();
    final candidates = <MemoryEntry>{};

    if (tokens.isNotEmpty) {
      final hits = await store.search(tokens.join(' '), limit: 20);
      candidates.addAll(hits);
    }
    // always blend in recent & high-importance entries
    final recent = await store.all(limit: 12);
    candidates.addAll(recent);

    final now = DateTime.now();
    final scored = candidates.map((m) {
      var score = m.importance * 1.6;
      final ageDays = now.difference(m.createdAt).inHours / 24.0;
      score += (30 - ageDays).clamp(0, 30) / 30.0 * 2.0; // recency ≤ +2
      for (final t in tokens) {
        if (m.keywordList.any((k) => k.contains(t))) score += 3.0;
        if (normalizeForSearch(m.content).contains(t)) score += 1.5;
      }
      return MapEntry(m, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }
}

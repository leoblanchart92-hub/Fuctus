/// Memory store — abstraction + in-memory implementation (used by unit tests
/// and as a safe fallback if SQLite fails to open).
library;

import 'memory_entry.dart';

abstract class MemoryStore {
  Future<void> open();
  Future<int> insert(MemoryEntry entry);
  Future<List<MemoryEntry>> all({int limit = 200});
  Future<List<MemoryEntry>> search(String normalizedQuery, {int limit = 20});
  Future<void> delete(int id);
  Future<void> clear();
  Future<int> count();
  Future<void> close();
}

/// Deterministic, accent-insensitive normaliser shared by all stores.
String normalizeForSearch(String input) {
  const accents = 'àâäáãåèêëéìîïíòôöóõùûüúçñ';
  const replace = 'aaaaaaeeeeiiiiooooouuuucn';
  var s = input.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    s = s.replaceAll(accents[i], replace[i]);
  }
  return s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class InMemoryMemoryStore implements MemoryStore {
  final List<MemoryEntry> _items = [];

  @override
  Future<void> open() async {}

  @override
  Future<int> insert(MemoryEntry entry) async {
    final id = (_items.isEmpty ? 0 : _items.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
    _items.add(entry.copyWith(id: id));
    return id;
  }

  @override
  Future<List<MemoryEntry>> all({int limit = 200}) async {
    final sorted = [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<MemoryEntry>> search(String normalizedQuery, {int limit = 20}) async {
    if (normalizedQuery.isEmpty) return all(limit: limit);
    final tokens = normalizedQuery.split(' ').where((t) => t.length > 2).toList();
    final scored = <MapEntry<MemoryEntry, int>>[];
    for (final item in _items) {
      final hay = '${item.keywords} ${normalizeForSearch(item.content)}';
      var score = 0;
      for (final t in tokens) {
        if (hay.contains(t)) score += 2;
      }
      if (score > 0) scored.add(MapEntry(item, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<int> count() async => _items.length;

  @override
  Future<void> close() async {}
}

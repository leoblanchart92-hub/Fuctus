/// SQLite-backed persistent memory (table `jarvis_memory`).
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'memory_entry.dart';
import 'memory_store.dart';

class SqfliteMemoryStore implements MemoryStore {
  Database? _db;

  @override
  Future<void> open() async {
    if (_db != null) return;
    final base = await getDatabasesPath();
    final path = p.join(base, 'jarvis_memory.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jarvis_memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL DEFAULT 'fact',
            content TEXT NOT NULL,
            keywords TEXT NOT NULL DEFAULT '',
            importance INTEGER NOT NULL DEFAULT 2,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_memory_created ON jarvis_memory(created_at DESC)');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('SqfliteMemoryStore.open() must be called first');
    }
    return db;
  }

  @override
  Future<int> insert(MemoryEntry entry) => _database.insert('jarvis_memory', entry.toMap());

  @override
  Future<List<MemoryEntry>> all({int limit = 200}) async {
    final rows = await _database.query('jarvis_memory',
        orderBy: 'created_at DESC', limit: limit);
    return rows.map(MemoryEntry.fromMap).toList();
  }

  @override
  Future<List<MemoryEntry>> search(String normalizedQuery, {int limit = 20}) async {
    if (normalizedQuery.isEmpty) return all(limit: limit);
    final tokens = normalizedQuery.split(' ').where((t) => t.length > 2).toList();
    if (tokens.isEmpty) return all(limit: limit);
    final where = tokens.map((_) => '(content LIKE ? OR keywords LIKE ?)').join(' OR ');
    final args = <Object?>[];
    for (final t in tokens) {
      args.add('%$t%');
      args.add('%$t%');
    }
    final rows = await _database.query(
      'jarvis_memory',
      where: where,
      whereArgs: args,
      orderBy: 'importance DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  @override
  Future<void> delete(int id) async {
    await _database.delete('jarvis_memory', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async => _database.delete('jarvis_memory');

  @override
  Future<int> count() async {
    final rows = await _database.rawQuery('SELECT COUNT(*) AS c FROM jarvis_memory');
    return (rows.first['c'] as int?) ?? 0;
  }

  @override
  Future<void> close() async => _db?.close();
}

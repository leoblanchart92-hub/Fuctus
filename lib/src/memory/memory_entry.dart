/// Memory — persistent store of facts, preferences and notes about the user.
library;

class MemoryEntry {
  final int? id;
  final String kind; // 'fact' | 'preference' | 'note' | 'identity'
  final String content;
  final String keywords; // comma-separated, lowercase, no accents
  final int importance; // 1..5
  final DateTime createdAt;

  const MemoryEntry({
    this.id,
    required this.kind,
    required this.content,
    required this.keywords,
    this.importance = 2,
    required this.createdAt,
  });

  factory MemoryEntry.fromMap(Map<String, dynamic> map) => MemoryEntry(
        id: map['id'] as int?,
        kind: (map['kind'] as String?) ?? 'fact',
        content: (map['content'] as String?) ?? '',
        keywords: (map['keywords'] as String?) ?? '',
        importance: (map['importance'] as int?) ?? 2,
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as int?) ?? 0),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'kind': kind,
        'content': content,
        'keywords': keywords,
        'importance': importance,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  MemoryEntry copyWith({int? id}) => MemoryEntry(
        id: id ?? this.id,
        kind: kind,
        content: content,
        keywords: keywords,
        importance: importance,
        createdAt: createdAt,
      );

  List<String> get keywordList => keywords
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

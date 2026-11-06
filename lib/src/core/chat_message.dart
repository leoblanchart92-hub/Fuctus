/// Chat message model for the conversation transcript.
library;

enum MessageSource { user, claude, offline, skill, system, memory }

class ChatMessage {
  final String id;
  final String text;
  final MessageSource source;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.source,
    required this.timestamp,
  });

  bool get isUser => source == MessageSource.user;
}

/// AI layer — provider abstraction so JARVIS can be powered by Claude (API)
/// or by the built-in offline brain, transparently.
library;

class AiMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  const AiMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiException implements Exception {
  final String message;
  final int? statusCode;
  const AiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

abstract class AiProvider {
  /// Human-readable provider name (shown in the HUD badge).
  String get name;

  /// True when the provider can actually serve requests right now
  /// (e.g. an API key is configured).
  bool get isAvailable;

  Future<String> complete({
    required String systemPrompt,
    required List<AiMessage> messages,
    int maxTokens = 1024,
  });
}

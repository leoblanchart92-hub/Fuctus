/// Anthropic Messages API provider — powers JARVIS with Claude.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

class AnthropicProvider implements AiProvider {
  final String apiKey;
  final String model;
  final Duration timeout;
  final http.Client _client;

  AnthropicProvider({
    required this.apiKey,
    this.model = 'claude-sonnet-4-5',
    this.timeout = const Duration(seconds: 45),
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  @override
  String get name => 'Claude ($model)';

  @override
  bool get isAvailable => apiKey.trim().length > 10;

  @override
  Future<String> complete({
    required String systemPrompt,
    required List<AiMessage> messages,
    int maxTokens = 1024,
  }) async {
    if (!isAvailable) {
      throw const AiException('Clé API Anthropic manquante ou invalide.');
    }

    final body = jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'temperature': 0.7,
      'system': systemPrompt,
      'messages': messages.map((m) => m.toJson()).toList(),
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'x-api-key': apiKey.trim(),
              'anthropic-version': _apiVersion,
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiException('Délai dépassé : le serveur Claude ne répond pas.');
    } catch (e) {
      throw AiException('Réseau indisponible : $e');
    }

    final decoded = _tryDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final content = decoded['content'];
        if (content is List) {
          final texts = content
              .whereType<Map<String, dynamic>>()
              .where((c) => c['type'] == 'text')
              .map((c) => (c['text'] as String?) ?? '')
              .where((t) => t.trim().isNotEmpty);
          if (texts.isNotEmpty) return texts.join('\n').trim();
        }
      }
      throw const AiException('Réponse Claude inattendue (format inconnu).');
    }

    String message = 'Erreur Claude (HTTP ${response.statusCode})';
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        message = error['message'] as String;
      }
    }
    throw AiException(message, statusCode: response.statusCode);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}

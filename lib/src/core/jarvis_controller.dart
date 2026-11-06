/// JarvisController — the central nervous system.
/// Owns the android animator, the conversation, memory, skills and voice,
/// and exposes a single ChangeNotifier to the UI.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../ai/ai_provider.dart';
import '../ai/anthropic_provider.dart';
import '../ai/offline_brain.dart';
import '../character/jarvis_3d/animator.dart';
import '../memory/memory_repository.dart';
import '../memory/memory_store.dart';
import '../persona/jarvis_persona.dart';
import '../settings/settings_controller.dart';
import '../skills/skill.dart';
import '../skills/skill_registry.dart';
import '../voice/voice_service.dart';
import 'chat_message.dart';

class JarvisController extends ChangeNotifier {
  final SettingsController settings;
  final MemoryRepository memory;
  final SkillRegistry skills;
  final HumanoidAnimator animator = HumanoidAnimator(seed: 42);
  final VoiceService voice = VoiceService();

  final List<ChatMessage> messages = [];
  bool busy = false;
  bool voiceReady = false;
  String? lastNotice;

  int _msgCounter = 0;
  String get _nextId => 'm${DateTime.now().microsecondsSinceEpoch}_${_msgCounter++}';

  JarvisController({required this.settings, MemoryStore? memoryStore})
      : memory = MemoryRepository(memoryStore ?? InMemoryMemoryStore()),
        // NOTE: production wires a SqfliteMemoryStore before init() — see main.dart
        skills = SkillRegistry() {
    voice.onFinalSpeech = (text) => sendText(text);
    voice.onSpeakingStart = () {
      animator.startSpeaking();
      notifyListeners();
    };
    voice.onSpeakingEnd = () {
      animator.stopSpeaking();
      notifyListeners();
    };
    voice.onListeningStart = () {
      animator.setExpression(JarvisExpression.listening);
      notifyListeners();
    };
  }

  // ------------------------------------------------------------------ init
  Future<void> init() async {
    await memory.init();
    await settings.load();
    voiceReady = await voice.init(
      locale: settings.sttLocale,
      ttsLanguage: settings.ttsLanguage,
      rate: settings.speechRate,
      pitch: settings.pitch,
    );
    animator.setExpression(JarvisExpression.neutral);
    if (messages.isEmpty) {
      _addSystem(_welcomeLine());
    }
    notifyListeners();
  }

  String _welcomeLine() {
    final online = _provider().isAvailable;
    final name = settings.userName.isEmpty ? '' : ' ${settings.userTitle} ${settings.userName}';
    return online
        ? 'Tous mes systèmes sont en ligne. Bon retour,$name. Comment puis-je vous assister ?'
        : 'Tous mes systèmes sont en ligne, $name. Mode autonome actif : renseignez une clé API Claude dans les réglages pour débloquer mon plein potentiel.';
  }

  AiProvider _provider() => AnthropicProvider(apiKey: settings.apiKey, model: settings.model);

  bool get claudeAvailable => _provider().isAvailable;
  bool get isSpeaking => voice.isSpeaking;

  // ------------------------------------------------------------- messages
  void _addMessage(String text, MessageSource source) {
    messages.add(ChatMessage(
      id: _nextId,
      text: text,
      source: source,
      timestamp: DateTime.now(),
    ));
    // keep the transcript lean
    if (messages.length > 120) {
      messages.removeRange(0, messages.length - 120);
    }
    notifyListeners();
  }

  void _addSystem(String text) => _addMessage(text, MessageSource.system);

  Future<void> clearConversation() async {
    messages.clear();
    _addSystem(_welcomeLine());
  }

  // --------------------------------------------------------- send pipeline
  Future<void> sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || busy) return;

    _addMessage(text, MessageSource.user);
    busy = true;
    animator.setExpression(JarvisExpression.thinking);
    animator.nudgeHead(yawImpulse: 0.6);
    HapticFeedback.lightImpact();
    notifyListeners();

    try {
      // 1) memory commands
      final memoryReply = await _tryMemoryCommand(text);
      if (memoryReply != null) {
        await _finishReply(memoryReply, MessageSource.memory, speak: true);
        return;
      }

      // 2) skills (time, calculator, weather, notes, memory)
      final context = SkillContext(
        memory: memory,
        defaultCity: settings.city,
        languageCode: settings.languageCode,
      );
      final skillResult = await skills.dispatch(text, context);
      if (skillResult != null) {
        await _finishReply(skillResult.text, MessageSource.skill, speak: true);
        return;
      }

      // 3) Claude API
      final provider = _provider();
      if (provider.isAvailable) {
        try {
          final memories = await memory.relevant(text, limit: 6);
          final systemPrompt = JarvisPersona.buildSystemPrompt(
            userName: settings.userName,
            userTitle: settings.userTitle,
            memories: memories,
          );
          final history = messages
              .where((m) => m.source == MessageSource.user || m.source == MessageSource.claude || m.source == MessageSource.offline)
              .toList();
          final window = history.length > 12 ? history.sublist(history.length - 12) : history;
          final aiMessages = window
              .map((m) => AiMessage(m.isUser ? 'user' : 'assistant', m.text))
              .toList();
          final reply = await provider.complete(systemPrompt: systemPrompt, messages: aiMessages);
          _maybeExtractMemory(text); // fire-and-forget heuristic
          await _finishReply(reply, MessageSource.claude, speak: true);
          return;
        } catch (e) {
          lastNotice = 'Claude indisponible ($e). Bascule en mode autonome.';
        }
      }

      // 4) offline brain
      final reply = OfflineBrain(userName: settings.userName).reply(text);
      await _finishReply(reply, MessageSource.offline, speak: true);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('JarvisController.sendText failed: $e\n$stack');
      }
      await _finishReply(
        'Une anomalie est survenue dans mes circuits : $e',
        MessageSource.system,
        speak: false,
      );
    }
  }

  Future<void> _finishReply(String text, MessageSource source, {required bool speak}) async {
    _addMessage(text, source);
    busy = false;
    animator.setExpression(source == MessageSource.memory ? JarvisExpression.smile : JarvisExpression.smile);
    if (speak && settings.ttsEnabled) {
      await voice.speak(text);
    }
    notifyListeners();
  }

  /// Lightweight heuristic: "j'aime / je préfère / j'habite / je travaille …"
  /// statements get remembered automatically (importance 2).
  void _maybeExtractMemory(String text) {
    final norm = text.toLowerCase();
    final patterns = [
      RegExp(r'^(j.aime|j.adore|je prefere|je préfère|je deteste|je déteste|j.habite|je travaille|je suis)\b'),
    ];
    if (text.length < 12 || text.length > 220) return;
    for (final p in patterns) {
      if (p.hasMatch(norm)) {
        memory.remember(content: text, kind: 'preference', importance: 2);
        return;
      }
    }
  }

  // ------------------------------------------------------- memory commands
  Future<String?> _tryMemoryCommand(String raw) async {
    final text = raw.trim();

    final remember = RegExp(
      r'^(souviens[- ]toi que|retiens (que|bien que)|rappelle[- ]toi que|memorise que|mémorise que|keep in mind that|remember that)\s+(.+)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (remember != null) {
      final content = remember.group(3)!.trim();
      await memory.remember(content: content, kind: 'fact', importance: 4);
      return 'C’est gravé dans ma mémoire, ${_address()} : « $content ». Vous n’aurez pas besoin de me le répéter.';
    }

    final forget = RegExp(
      r'^(oublie que|oublie|forget that|forget)\s+(.+)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    if (forget != null) {
      final query = forget.group(2)!.trim();
      final hits = await memory.search(query, limit: 1);
      if (hits.isEmpty) {
        return 'Je n’ai rien trouvé de tel dans ma mémoire, ${_address()}.';
      }
      final target = hits.first;
      final id = target.id;
      if (id != null) await memory.delete(id);
      return 'Effacé : « ${target.content} ». Comme si ce souvenir n’avait jamais existé.';
    }

    if (RegExp(r'(efface toute ta memoire|efface toute ta mémoire|oublie tout|wipe your memory|erase your memory)', caseSensitive: false).hasMatch(text)) {
      await memory.clear();
      return 'Mémoire intégralement effacée. Nous repartons d’une page blanche, ${_address()}.';
    }

    return null;
  }

  String _address() => settings.userName.isEmpty ? settings.userTitle : settings.userName;

  // ------------------------------------------------------------------ voice
  Future<void> toggleListening() async {
    if (busy) return;
    await voice.toggleListening();
    notifyListeners();
  }

  Future<void> stopEverything() async {
    await voice.stopListening();
    await voice.stopSpeaking();
    busy = false;
    animator.setExpression(JarvisExpression.neutral);
    notifyListeners();
  }

  @override
  void dispose() {
    voice.dispose();
    super.dispose();
  }
}

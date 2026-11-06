/// JarvisScreen — the main HUD: android, transcript and voice/text input.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../character/character_view.dart';
import '../../core/chat_message.dart';
import '../../core/jarvis_controller.dart';
import '../hud_theme.dart';
import '../widgets/arc_reactor.dart';
import '../widgets/hud_panel.dart';

class JarvisScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;
  const JarvisScreen({super.key, required this.onOpenSettings});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    context.read<JarvisController>().sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JarvisController>();
    final messages = controller.messages;

    // auto-scroll when new messages arrive
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.65),
          radius: 1.15,
          colors: [Color(0xFF0A1A28), HudPalette.background],
        ),
      ),
      child: Column(
        children: [
          _StatusBar(onOpenSettings: widget.onOpenSettings),
          Expanded(
            flex: 5,
            child: CharacterView(animator: controller.animator, live: true),
          ),
          _QuickActions(onSend: controller.sendText),
          Expanded(
            flex: 4,
            child: _Transcript(scrollController: _scroll, messages: messages, busy: controller.busy),
          ),
          _InputBar(
            input: _input,
            onSubmit: _submit,
            onMic: controller.toggleListening,
            listening: controller.voice.isListening,
            speaking: controller.isSpeaking,
            busy: controller.busy,
          ),
        ],
      ),
    );
  }
}

// ====================================================================== status
class _StatusBar extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _StatusBar({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JarvisController>();
    final online = controller.claudeAvailable;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
      child: Row(
        children: [
          const ArcReactor(size: 36),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'J.A.R.V.I.S.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 5,
                  color: HudPalette.cyan,
                  shadows: [Shadow(color: HudPalette.cyan, blurRadius: 12)],
                ),
              ),
              Text(
                'JUST A RATHER VERY INTELLIGENT SYSTEM',
                style: TextStyle(fontSize: 7.4, letterSpacing: 1.4, color: HudPalette.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          const HudClock(),
          const SizedBox(width: 8),
          _ModeChip(online: online),
          IconButton(
            tooltip: 'Réglages',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, color: HudPalette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class HudClock extends StatefulWidget {
  const HudClock({super.key});

  @override
  State<HudClock> createState() => _HudClockState();
}

class _HudClockState extends State<HudClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
    return Text(
      time,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        letterSpacing: 2,
        color: HudPalette.textPrimary,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final bool online;
  const _ModeChip({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? HudPalette.cyan : HudPalette.amber;
    final label = online ? 'CLAUDE' : 'HORS LIGNE';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================= quick actions
class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onSend;
  const _QuickActions({required this.onSend});

  static const _actions = [
    ('👋', 'Bonjour JARVIS'),
    ('🧠', 'Que sais-tu de moi ?'),
    ('🌤️', 'Météo à Strasbourg'),
    ('🧮', 'Combien font 137 fois 42 ?'),
    ('📝', 'Note : revoir le code de JARVIS'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return ActionChip(
            backgroundColor: HudPalette.panelSolid,
            side: const BorderSide(color: HudPalette.panelBorder),
            avatar: Text(action.$1, style: const TextStyle(fontSize: 13)),
            label: Text(action.$2, style: const TextStyle(fontSize: 10.5, color: HudPalette.textPrimary)),
            onPressed: () => onSend(action.$2),
          );
        },
      ),
    );
  }
}

// ==================================================================== transcript
class _Transcript extends StatelessWidget {
  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool busy;

  const _Transcript({required this.scrollController, required this.messages, required this.busy});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      cornerRadius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 13, color: HudPalette.cyanDim),
              const SizedBox(width: 6),
              const Text(
                'TRANSCRIPTION',
                style: TextStyle(fontSize: 9, letterSpacing: 2.4, color: HudPalette.textSecondary),
              ),
              const Spacer(),
              if (busy)
                const Text(
                  '● JARVIS réfléchit…',
                  style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: HudPalette.cyan),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 450.ms).fadeOut(duration: 450.ms),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) => _MessageBubble(messages[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble(this.message);

  @override
  Widget build(BuildContext context) {
    if (message.source == MessageSource.system || message.source == MessageSource.memory) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '— ${message.text}',
          style: const TextStyle(fontSize: 10, color: HudPalette.textFaint, fontStyle: FontStyle.italic),
        ),
      );
    }

    final isUser = message.isUser;
    final (label, icon, tint) = switch (message.source) {
      MessageSource.user => ('VOUS', Icons.person_outline, HudPalette.textSecondary),
      MessageSource.claude => ('JARVIS · CLAUDE', Icons.bolt, HudPalette.cyan),
      MessageSource.offline => ('JARVIS · AUTONOME', Icons.memory, HudPalette.amber),
      MessageSource.skill => ('JARVIS · MODULE', Icons.extension_outlined, HudPalette.cyanDim),
      MessageSource.memory => ('JARVIS · MÉMOIRE', Icons.save_outlined, HudPalette.cyan),
      MessageSource.system => ('SYSTÈME', Icons.info_outline, HudPalette.textFaint),
    };

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF12242F) : const Color(0xFF0B1B28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isUser ? HudPalette.panelBorder : HudPalette.cyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: tint),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 8, letterSpacing: 1.6, color: tint)),
            ],
          ),
          const SizedBox(height: 3),
          Text(message.text, style: const TextStyle(fontSize: 12.5, height: 1.35, color: HudPalette.textPrimary)),
        ],
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble.animate().fadeIn(duration: 220.ms).slideY(begin: 0.15, end: 0, duration: 220.ms),
    );
  }
}

// ====================================================================== input
class _InputBar extends StatelessWidget {
  final TextEditingController input;
  final VoidCallback onSubmit;
  final VoidCallback onMic;
  final bool listening;
  final bool speaking;
  final bool busy;

  const _InputBar({
    required this.input,
    required this.onSubmit,
    required this.onMic,
    required this.listening,
    required this.speaking,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final active = listening || speaking;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: const BoxDecoration(
        color: HudPalette.backgroundAlt,
        border: Border(top: BorderSide(color: HudPalette.panelBorder)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: listening ? 'Arrêter l’écoute' : 'Parler à JARVIS',
            child: Semantics(
              button: true,
              label: 'Microphone',
              child: InkWell(
                onTap: busy ? null : onMic,
                borderRadius: BorderRadius.circular(34),
                child: ArcReactor(size: 58, firing: active),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: input,
              enabled: !busy,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(color: HudPalette.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: listening ? 'J’écoute…' : 'Parlez ou tapez votre demande…',
                suffixIcon: IconButton(
                  tooltip: 'Envoyer',
                  onPressed: busy ? null : onSubmit,
                  icon: Icon(Icons.send_rounded, color: busy ? HudPalette.textFaint : HudPalette.cyan),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SettingsScreen — profil, cerveau IA, voix, mémoire, à propos.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ai/ai_provider.dart';
import '../../ai/anthropic_provider.dart';
import '../../core/jarvis_controller.dart';
import '../../settings/settings_controller.dart';
import '../hud_theme.dart';
import '../widgets/hud_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  bool _testingConnection = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>();
    _name = TextEditingController(text: s.userName);
    _city = TextEditingController(text: s.city);
    _apiKey = TextEditingController(text: s.apiKey);
    _model = TextEditingController(text: s.model);
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final jarvis = context.watch<JarvisController>();

    return Scaffold(
      backgroundColor: HudPalette.background,
      appBar: AppBar(title: const Text('RÉGLAGES')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          // ------------------------------------------------ profil
          const _SectionHeader('PROFIL'),
          HudPanel(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  style: const TextStyle(color: HudPalette.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Votre nom',
                    prefixIcon: Icon(Icons.person_outline, color: HudPalette.textSecondary),
                  ),
                  onSubmitted: (v) => settings.save(userName: v),
                  onChanged: (v) => settings.save(userName: v),
                ),
                const SizedBox(height: 10),
                _DropdownRow(
                  label: 'Formule d’adresse',
                  value: settings.userTitle,
                  items: const ['monsieur', 'madame', 'capitaine', 'docteur', 'commandeur'],
                  onChanged: (v) => settings.save(userTitle: v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _city,
                  style: const TextStyle(color: HudPalette.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Ville (météo par défaut)',
                    prefixIcon: Icon(Icons.location_city_outlined, color: HudPalette.textSecondary),
                  ),
                  onChanged: (v) => settings.save(city: v),
                ),
                const SizedBox(height: 10),
                _DropdownRow(
                  label: 'Langue / voix',
                  value: settings.language,
                  items: const ['fr_FR', 'en_US'],
                  itemLabels: const {'fr_FR': 'Français (FR)', 'en_US': 'English (US)'},
                  onChanged: (v) async {
                    await settings.save(language: v);
                    await jarvis.voice.updateVoiceParams(
                      ttsLanguage: settings.ttsLanguage,
                      rate: settings.speechRate,
                      pitch: settings.pitch,
                      locale: settings.sttLocale,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // --------------------------------------------- cerveau IA
          const _SectionHeader('CERVEAU IA · CLAUDE'),
          HudPanel(
            glow: settings.apiKey.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clé API Anthropic (stockée chiffrée sur l’appareil, jamais dans le dépôt). '
                  'Sans clé, JARVIS fonctionne en mode autonome hors-ligne.',
                  style: TextStyle(fontSize: 10.5, height: 1.5, color: HudPalette.textSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKey,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: HudPalette.textPrimary, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: 'sk-ant-…',
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: HudPalette.textSecondary),
                    suffixIcon: _apiKey.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer la clé',
                            icon: const Icon(Icons.backspace_outlined, color: HudPalette.amber),
                            onPressed: () {
                              _apiKey.clear();
                              settings.save(apiKey: '');
                            },
                          ),
                  ),
                  onChanged: (v) => settings.save(apiKey: v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _model,
                  autocorrect: false,
                  style: const TextStyle(color: HudPalette.textPrimary, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                    prefixIcon: Icon(Icons.smart_toy_outlined, color: HudPalette.textSecondary),
                  ),
                  onChanged: (v) => settings.save(model: v),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: SettingsController.modelPresets
                      .map((preset) => GestureDetector(
                            onTap: () {
                              setState(() => _model.text = preset);
                              settings.save(model: preset);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: settings.model == preset ? HudPalette.cyanFaint : HudPalette.backgroundAlt,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: settings.model == preset ? HudPalette.cyan : HudPalette.panelBorder,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    color: settings.model == preset ? HudPalette.cyan : HudPalette.textSecondary,
                                  ),
                                ),
                              ),
                            ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: HudPalette.cyanFaint,
                        foregroundColor: HudPalette.cyan,
                        side: const BorderSide(color: HudPalette.cyan),
                      ),
                      icon: _testingConnection
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: HudPalette.cyan))
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: const Text('Tester la liaison'),
                      onPressed: _testingConnection ? null : () => _testConnection(settings),
                    ),
                    const SizedBox(width: 10),
                    if (settings.apiKey.isNotEmpty)
                      const Icon(Icons.verified_outlined, color: HudPalette.cyan, size: 18),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ------------------------------------------------------ voix
          const _SectionHeader('VOIX'),
          HudPanel(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: HudPalette.cyanFaint,
                  activeThumbColor: HudPalette.cyan,
                  title: const Text('Réponses vocales', style: TextStyle(color: HudPalette.textPrimary, fontSize: 13)),
                  subtitle: const Text('JARVIS lit ses réponses à voix haute', style: TextStyle(color: HudPalette.textFaint, fontSize: 10)),
                  value: settings.ttsEnabled,
                  onChanged: (v) => settings.save(ttsEnabled: v),
                ),
                _SliderRow(
                  label: 'Débit',
                  value: settings.speechRate,
                  min: 0.2,
                  max: 0.9,
                  onChanged: (v) async {
                    await settings.save(speechRate: v);
                    if (mounted) {
                      await jarvis.voice.updateVoiceParams(
                        ttsLanguage: settings.ttsLanguage,
                        rate: v,
                        pitch: settings.pitch,
                        locale: settings.sttLocale,
                      );
                    }
                  },
                ),
                _SliderRow(
                  label: 'Tonalité',
                  value: settings.pitch,
                  min: 0.6,
                  max: 1.6,
                  onChanged: (v) async {
                    await settings.save(pitch: v);
                    if (mounted) {
                      await jarvis.voice.updateVoiceParams(
                        ttsLanguage: settings.ttsLanguage,
                        rate: settings.speechRate,
                        pitch: v,
                        locale: settings.sttLocale,
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HudPalette.cyan,
                      side: const BorderSide(color: HudPalette.cyanDim),
                    ),
                    icon: const Icon(Icons.record_voice_over_outlined, size: 17),
                    label: const Text('Test vocal'),
                    onPressed: () => jarvis.voice.speak(
                      settings.userTitle.isEmpty
                          ? 'Tous mes systèmes sont opérationnels.'
                          : 'Tous mes systèmes sont opérationnels, ${settings.userTitle}. En quoi puis-je vous être utile ?',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      jarvis.voiceReady ? Icons.mic_outlined : Icons.mic_off_outlined,
                      size: 14,
                      color: jarvis.voiceReady ? HudPalette.cyan : HudPalette.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      jarvis.voiceReady ? 'Micro & reconnaissance vocale prêts' : 'Micro indisponible — le mode texte reste actif',
                      style: TextStyle(fontSize: 10, color: jarvis.voiceReady ? HudPalette.textSecondary : HudPalette.amber),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---------------------------------------------------- système
          const _SectionHeader('SYSTÈME'),
          HudPanel(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: HudPalette.textSecondary),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Effacer la conversation', style: TextStyle(color: HudPalette.textPrimary, fontSize: 13))),
                    TextButton(
                      onPressed: () => context.read<JarvisController>().clearConversation(),
                      child: const Text('EFFACER', style: TextStyle(color: HudPalette.amber)),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Icon(Icons.cleaning_services_outlined, size: 18, color: HudPalette.textSecondary),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Oublier toute la mémoire', style: TextStyle(color: HudPalette.textPrimary, fontSize: 13))),
                    TextButton(
                      onPressed: () => context.read<JarvisController>().memory.clear(),
                      child: const Text('OUBLIER', style: TextStyle(color: HudPalette.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---------------------------------------------------- à propos
          const _SectionHeader('À PROPOS'),
          const HudPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('J.A.R.V.I.S.  v1.0.0', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: HudPalette.cyan)),
                SizedBox(height: 6),
                Text(
                  'Just A Rather Very Intelligent System.\n'
                  'Androïde procédural 3D rendu en Canvas — aucun asset binaire.\n'
                  'IA conversationnelle : API Anthropic (Claude) + cerveau autonome hors-ligne.\n'
                  'Mémoire persistante SQLite · Voix : speech_to_text + flutter_tts.\n'
                  'Architecture inspirée de l’analyse de « Coucou » (louis-cfm/coucou).',
                  style: TextStyle(fontSize: 10.5, height: 1.6, color: HudPalette.textSecondary),
                ),
                SizedBox(height: 8),
                Text('Built with Flutter & Dart · MIT License', style: TextStyle(fontSize: 9, color: HudPalette.textFaint, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection(SettingsController settings) async {
    setState(() => _testingConnection = true);
    try {
      final provider = AnthropicProvider(apiKey: settings.apiKey, model: settings.model);
      final answer = await provider.complete(
        systemPrompt: 'Réponds exactement par le mot: OK',
        messages: const [AiMessage('user', 'ping')],
        maxTokens: 8,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Liaison établie — réponse de Claude : ${answer.trim()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la liaison : $e'), backgroundColor: const Color(0xFF3A1016)),
        );
      }
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: HudPalette.cyan),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 11, letterSpacing: 2.6, color: HudPalette.cyan, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String>? itemLabels;
  final ValueChanged<String> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    this.itemLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: HudPalette.textPrimary)),
        ),
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: HudPalette.panelBorder),
              color: HudPalette.backgroundAlt,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                dropdownColor: HudPalette.panelSolid,
                borderRadius: BorderRadius.circular(10),
                icon: const Icon(Icons.keyboard_arrow_down, color: HudPalette.cyan),
                items: items
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              itemLabels?[i] ?? i,
                              style: const TextStyle(color: HudPalette.textPrimary, fontSize: 12),
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12, color: HudPalette.textPrimary))),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: HudPalette.textSecondary, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

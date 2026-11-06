/// SkillsScreen — catalogue of JARVIS's extensible skill modules.
library;

import 'package:flutter/material.dart';

import '../../skills/skill_registry.dart';
import '../hud_theme.dart';
import '../widgets/hud_panel.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  static const _icons = {
    'time': Icons.schedule_outlined,
    'calculator': Icons.calculate_outlined,
    'weather': Icons.cloud_outlined,
    'notes': Icons.sticky_note_2_outlined,
    'memory': Icons.psychology_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final registry = SkillRegistry.builtins();
    return Scaffold(
      backgroundColor: HudPalette.background,
      appBar: AppBar(title: const Text('COMPÉTENCES')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          HudPanel(
            glow: true,
            child: Row(
              children: [
                const Icon(Icons.extension_outlined, color: HudPalette.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARCHITECTURE EXTENSIBLE',
                        style: TextStyle(fontSize: 10, letterSpacing: 2.2, color: HudPalette.cyan),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chaque compétence est un module JarvisSkill autonome, déclaré dans le '
                        'SkillRegistry. Ajoutez une classe, enregistrez-la, et elle est aussitôt '
                        'disponible à la voix comme au clavier.',
                        style: TextStyle(fontSize: 11, height: 1.5, color: HudPalette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...registry.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HudPanel(
                  cornerRadius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _icons[skill.id] ?? Icons.power_outlined,
                            color: HudPalette.cyan,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            skill.name.toUpperCase(),
                            style: const TextStyle(fontSize: 13, letterSpacing: 2, color: HudPalette.textPrimary, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: HudPalette.cyanFaint,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: HudPalette.cyan.withValues(alpha: 0.5)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text('EN LIGNE', style: TextStyle(fontSize: 8, letterSpacing: 1.4, color: HudPalette.cyan)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(skill.description, style: const TextStyle(fontSize: 11.5, height: 1.45, color: HudPalette.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skill.examplePhrases
                            .map((p) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: HudPalette.backgroundAlt,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: HudPalette.panelBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text('« $p »', style: const TextStyle(fontSize: 9.5, color: HudPalette.textFaint)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 6),
          const Text(
            'Le pipeline : voix/texte → SkillRegistry → sinon Claude API → sinon cerveau autonome. '
            'La mémoire persistante est injectée dans le contexte de Claude à chaque échange.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, height: 1.6, color: HudPalette.textFaint),
          ),
        ],
      ),
    );
  }
}

# JARVIS AI

**Just A Rather Very Intelligent System** — un assistant personnel vocal, animé par un
**androïde 3D procédural** rendu dans Flutter, une **IA conversationnelle** (API Claude ou
cerveau hors-ligne intégré), la **mémoire persistante**, et une **interface HUD futuriste**
inspirée de JARVIS (Iron Man).

> Android · Flutter · Dart · Architecture modulaire et extensible

![CI](https://github.com/leoblanchart92-hub/Fuctus/actions/workflows/android-apk.yml/badge.svg)

## ✨ Fonctionnalités

- 🤖 **Androïde humanoïde 3D** dessiné en pur Dart (tête, corps, bras, mains, jambes, pieds) —
  moteur 3D logiciel intégré (projection perspective, tri par profondeur, shading volumétrique)
- 😊 **Expressions faciales** : clignement, sourire, réflexion, parole (visemes), écoute, succès
- 🚶 **Animations naturelles** : respiration procédurale, balancement, geste « salut », suivi de tête par ressort amorti
- 🎙️ **Reconnaissance vocale** (speech_to_text, fr-FR) et **voix naturelle** (flutter_tts)
- 🧠 **IA conversationnelle** via l'API Anthropic (Claude) — avec **cerveau hors-ligne** intégré sans clé API
- 💾 **Mémoire persistante** (SQLite) : faits, préférences, notes — injectés dans le contexte de l'IA
- 🧩 **Compétences extensibles** : heure/date, calculatrice, météo (open-meteo, sans clé), notes — architecture `JarvisSkill`
- 🖥️ **HUD futuriste** : réacteur Arc animé, anneaux HUD, scanlines, panneaux translucides

## 🚀 Démarrage rapide

```bash
git clone https://github.com/leoblanchart92-hub/Fuctus.git
cd Fuctus
# Le dossier android/ est généré par Flutter (voir docs/APK_BUILD.md)
flutter create --platforms=android --org com.jarvisai --project-name jarvis_ai .
python3 tool/ci/patch_android.py        # permissions Android (INTERNET, RECORD_AUDIO)
flutter pub get
flutter run
```

L'**APK** est construit automatiquement par GitHub Actions à chaque push —
téléchargez-le dans l'onglet *Actions → android-apk → Artifacts*, ou voyez
**[docs/APK_BUILD.md](docs/APK_BUILD.md)** pour la génération locale.

## 🏗️ Architecture

Voir **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** et le
**[docs/COUCOU_ANALYSIS.md](docs/COUCOU_ANALYSIS.md)** (analyse du projet de référence
[louis-cfm/coucou](https://github.com/louis-cfm/coucou) dont l'architecture inspire ce projet).

## 📍 État du projet

Voir **[PROJECT_STATUS.md](PROJECT_STATUS.md)** — étapes terminées, en cours et à venir.

## 📄 Licence

MIT — voir [LICENSE](LICENSE).

# PROJECT_STATUS — JARVIS AI

> Fichier de reprise : lire ceci pour reprendre le travail exactement où il s'est arrêté.
> Dernière mise à jour : 2026-11-06 (session 1)

## 🎯 Mission

Application Android **JARVIS AI** (assistant personnel futuriste) en **Flutter/Dart**, développée
dans ce dépôt (`leoblanchart92-hub/Fuctus`, branche `arena/7f8dc3dc-fuctus`) :
personnage humanoïde 3D réaliste + animations + expressions, IA conversationnelle (type Claude),
voix naturelle, reconnaissance vocale, mémoire persistante, interface HUD JARVIS, fonctionnalités extensibles.

## ✅ Terminé (session 1)

- [x] Analyse du projet de référence Coucou (`docs/COUCOU_ANALYSIS.md`) — lessons learned intégrées
- [x] `.gitignore` (android/ régénéré par `flutter create` + patch → zéro binaire dans git)
- [x] `README.md` racine
- [x] `pubspec.yaml` + `analysis_options.yaml`
- [x] Moteur 3D logiciel `lib/src/character/jarvis_3d/` (Vec3/3D math, caméra perspective,
      particules corps humanoïde, shading volumétrique, expressions, spring physics, animations)
- [x] Androïde procédural complet : tête (visage d'androïde : visor, yeux lumineux), cou, torse,
      bassin, 2 bras (épaule→coude→poignet→mains 4 doigts), 2 jambes, pieds
- [x] IA : abstraction `AiProvider`, `AnthropicProvider` (API Claude), `OfflineBrain` (cerveau
      hors-ligne FR/EN : salutations, heure, date, calculatrice, blagues, Q/R génériques)
- [x] Mémoire persistante SQLite (`jarvis_memory.db`) + repli en mémoire pour les tests
- [x] Voix : STT (speech_to_text, fr-FR) + TTS (flutter_tts) avec visemes pendant la parole
- [x] Compétences extensibles `JarvisSkill` : météo (open-meteo), notes/mémoire, système
- [x] UI HUD futuriste : réacteur Arc animé, panneaux, écran principal, mémoire, compétences, réglages
- [x] Entry point `main.dart` + `jarvis_app.dart` + DI manuelle
- [x] Tests unitaires (`test/`) : math3d, moteur d'expression, calculatrice, offline brain, skills, memory, rig FK
- [x] CI GitHub Actions `.github/workflows/android-apk.yml` → build APK release + artifact
- [x] `tool/ci/patch_android.py` (permissions RECORD_AUDIO/INTERNET dans le manifest généré)
- [x] `docs/APK_BUILD.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PRIVACY.md`
- [x] LICENSE (MIT) (README racine)

## 🟡 En cours / prochaine session

- [ ] **CI verte** : pousser, surveiller `gh run watch`, corriger les erreurs de compilation/analyze (non testable en local — pas de SDK Flutter dans le sandbox)
- [ ] Télécharger l'APK depuis l'artifact Actions et le tester sur appareil
- [ ] Itération visuelle sur l'androïde (proportions, visagé, animations)

## 🔴 Limites connues de la session 1

1. Pas de SDK Flutter dans l'environnement de dev : le code n'a **pas** été compilé localement.
   La vérification se fait via la CI (analyze + test + build APK). Prévoir 1-3 itérations de correctifs.
2. `android/` n'est pas versionné : généré par `flutter create` (voir `docs/APK_BUILD.md`).
3. APK signé avec clé debug par défaut (signable avec une clé release — instructions dans `docs/APK_BUILD.md`).
4. Météo : nécessite le réseau (open-meteo, gratuit, sans clé).
5. Personnage : rendu logiciel — élégant mais pas photoréaliste ; une vraie peau/un vrai PBR
   nécessiterait un moteur GPU (voir `docs/ROADMAP.md`).

## 🗂️ Ordre de lecture pour reprendre

1. Ce fichier → 2. `docs/ROADMAP.md` → 3. `docs/ARCHITECTURE.md` (carte modules) → 4. `git log --oneline`

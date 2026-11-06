# Analyse du projet « Coucou » de Louis-CFM

Référence analysée : https://github.com/louis-cfm/coucou (branche `main`, ~1 121 commits, ~30 Mo)
Date d'analyse : 2026-11-06

## 1. Ce qu'est Coucou

Un compagnon de bureau : un petit personnage « Mochi » vit dans l'encoche (notch) du Mac / à l'écran,
et surveille les sessions d'agents IA (Claude Code, Codex, Cursor, Gemini CLI…). Il approuve/refuse
des actions, affiche l'état des agents, et réagit avec humour.

- **macOS** : Swift, dessiné **intégralement en code** (Canvas / CoreGraphics) — aucun asset binaire pour Mochi.
- **Windows / Linux** : ports, même principe.
- **Android** : `android/` en Kotlin + Jetpack (build Gradle, CI dédiée `android.yml`).
- **iOS** : `NotchBuddy`, même moteur de rendu.
- **design/** : prototypes HTML + le **moteur de rendu de référence en JavaScript** (`design/outfits/mochi-outfits.js`),
  planche de référence PNG, prototype HTML 85 Ko.

## 2. Choix d'architecture remarquables (et réutilisables pour JARVIS)

| Coucou | JARVIS AI |
|---|---|
| Personnage dessiné par code, pas par assets | **Moteur 3D logiciel en Dart** (`lib/src/character/jarvis_3d/`) — zéro asset binaire, personnage humanoïde procède |
| Projection 3D maison (`mRingR`, `mRot3`, `mProj`, `surf`, yaw/pitch/roll, `VIEW_TILT = -0.30`) | `math3d.dart` : vecteurs, rotations, caméra perspective, projection écran, painter's algorithm |
| Shading par gradients (radial/linear) superellipses | Shading corps : gradients radiaux décalés vers la lumière + cylindres projetés avec gradient transversal (ombre sur les bords, reflet central) |
| Physique par ressort amorti (raideur 60, amortissement 9) pour les accessoires | `Spring1D` dans `rig.dart` : tête/épaules avec ressort suivant l'impulsion de parole |
| Système d'expressions / emotes (blink, emotes, « presence » avec easing `Ease.back` 350 ms / 180 ms) | `ExpressionState` : neutre, sourire, réflexion, parole (visemes synchronisés TTS), écoute, succès — easings mêmes valeurs que Coucou |
| Modules séparés : `BotEngine` (état/physique) ≠ dessin ≠ `AppState` (état global) ≠ UI | Séparation stricte : `jarvis3d/` (moteur) / `character/jarvis_controller.dart` (état) / `ui/` (widgets) / `core/jarvis_controller.dart` (orchestration) |
| Planche de tests visuels rendus hors écran (`scripts/render-outfits.sh`, planches de poses) | harnais de test manuel `tool/preview_harness` prévu ; tests unitaires du moteur 3D dans `test/` |
| Clé de signature Android **hors du dépôt** (PR #794, CI build via secrets) | idem : APK signé avec la clé debug par défaut en CI ; clé release propre documentée (voir `docs/APK_BUILD.md`) |
| CI GitHub Actions obligatoire avant merge (`android.yml`, `build.yml`) | `.github/workflows/android-apk.yml` : analyze + test + build APK + artifact |
| Attribution de permissions et politique claires (PERMISSION.md) | `docs/PRIVACY.md` + permissions minimales (INTERNET, RECORD_AUDIO) |

## 3. Leçons retenues

1. **Un personnage en code est maintenable et testable** — pas de GLB/blend à versionner, les expressions
   et animations sont des fonctions de l'état. C'est le choix retenu pour JARVIS (voir `docs/ARCHITECTURE.md`).
2. **Isoler la physique du rendu** (spring vs draw) permet des animations naturelles (follow-through) sans effort.
3. **Un easing « back » pour les transitions d'apparition** donne la personnalité ; on reprend `Ease.back`.
4. **Une seule source de vérité pour l'état** (`AppState` chez Coucou → `JarvisController` chez JARVIS).
5. **La CI construit l'APK** — le dépôt ne contient pas de binaire, l'artefact sort du pipeline.
6. **Référence visuelle exportée** (planche PNG) : pour JARVIS, on fournit `docs/PREVIEW.md` + harnais Flutter.

## 4. Ce qu'on ne reprend PAS de Coucou

- Le concept « agent de codage » (notch, approbation de commandes) : JARVIS est un **assistant personnel généraliste**.
- Les outfits saisonniers : remplacés par un système de **humeurs/expressions** (visage d'androïde).
- Le dessin Canvas 2D plat : remplacé par un vrai modèle 3D procédural (projection perspective + tri par profondeur).

## 5. Structure Coucou à garder en tête

```
NotchBuddy/ (Swift, moteur)  design/ (référence JS + planches)  android/ (Kotlin)
relay/ (sync)  scripts/ (render, release)  docs/ (SPEC, VOICE, ANDROID_LINK)
tests/ (57 tests Mochi)  .github/workflows/ (12 pipelines)
```

Le découpage `docs/` riche + `tests/` + `workflows/` est repris à l'identique dans l'esprit pour JARVIS.

# Architecture — JARVIS AI

Flux d'une requête utilisateur :

```
   voix ──STT──┐
               ▼
   clavier ──► JarvisController.sendText
                 │
                 ├─ 1) commande mémoire (« souviens-toi que… », « oublie… », « efface ta mémoire »)
                 ├─ 2) SkillRegistry  (temps · calculatrice · météo · notes · mémoire)
                 ├─ 3) Claude API     (JarvisPersona + mémoire SQLite injectée dans le system prompt)
                 └─ 4) OfflineBrain   (cerveau autonome FR/EN, zéro réseau)
                 │
                 ▼
         ChatMessage → transcript HUD → flutter_tts (visemes pilotés en retour)
```

## Modules

| Chemin | Rôle |
|---|---|
| `lib/main.dart` | Boot : orientation portrait, barre système sombre, DI manuelle, `SqfliteMemoryStore` |
| `lib/jarvis_app.dart` | `MultiProvider` (Settings, JarvisController), thème HUD |
| `lib/src/character/jarvis_3d/math3d.dart` | Vec3, caméra perspective, ressort amorti, easings (`outBack`, Coucou) |
| `lib/src/character/jarvis_3d/humanoid_rig.dart` | Squelette 21 articulations + FK (matrices 4×4 minimales) |
| `lib/src/character/jarvis_3d/animator.dart` | Respiration, balancement, regard, clignement, visemes, gestes (salut, salutation, révérence) |
| `lib/src/character/jarvis_3d/renderer.dart` | **Moteur 3D logiciel** : capsules ombragées (gradient transversal), ellipsoïdes (gradient radial lumière), visor, réacteur Arc, paumes à répulseurs, painter's algorithm |
| `lib/src/character/character_view.dart` | Widget CustomPaint temps réel (Ticker) + décor HUD (grille sol, halo socle, vignette) |
| `lib/src/core/jarvis_controller.dart` | Façade : messages, pipeline sendText, commandes mémoire, voix ↔ animateur |
| `lib/src/ai/` | `AiProvider` (interface), `AnthropicProvider` (API Messages, TLS, gestion erreurs), `OfflineBrain` |
| `lib/src/memory/` | `MemoryStore` (SQLite / in-memory), `MemoryRepository` (scoring pertinence : mots-clés × récence × importance) |
| `lib/src/skills/` | `JarvisSkill` (interface extensible), `SkillRegistry`, 5 compétences intégrées |
| `lib/src/voice/voice_service.dart` | STT (`speech_to_text`, fr-FR) + TTS (`flutter_tts`), défensif (texte OK si micro absent) |
| `lib/src/settings/` | `shared_preferences` (réglages) + `flutter_secure_storage` (clé API, chiffrée) |
| `lib/src/ui/` | HUD : réacteur Arc (CustomPainter), panneaux à coins, écran principal, mémoire, modules, réglages |

## Choix majeurs & compromis

1. **Rendu logiciel plutôt que GLB/GPU.** Un personnage procédural en Canvas est 100 % portable,
   testable, sans assets fragiles ni pipeline d'import — la leçon n°1 de l'analyse Coucou.
   Contrepartie : look « android premium » stylisé, pas photoréaliste. Un vrai PBR est planifié
   (voir `docs/ROADMAP.md`, piste `flutter_scene`/GLB animé fourni séparément).
2. **Mémoire injectée, jamais fine-tunée.** Les faits SQLite sont injectés dans le system prompt
   Claude (top 6, scorés). Coût maîtrisé (max 1024 tokens de réponse), fonctionnement identique
   en mode hors-ligne via `OfflineBrain`.
3. **Skills avant LLM.** Ce qui est déterministe reste déterministe (heure, calcul, météo, notes) :
   zéro hallucination, zéro coût, hors-ligne OK.
4. **Zéro binaire dans git.** `android/` régénéré + patché (voir `docs/APK_BUILD.md`).

## Étendre JARVIS

### Nouvelle compétence
```dart
class TaxiSkill extends JarvisSkill { … }
// puis dans SkillRegistry.builtins() : return [ ..., TaxiSkill() ];
```
Aucune autre modification. `canHandle` doit être synchrone et bon marché (regex sur texte normalisé).

### Nouveau cerveau IA
Implémentez `AiProvider` (ex. Gemini, OpenAI, Ollama local), exposez-le dans
`JarvisController._provider()` (sélection via réglages).

### Nouveau geste / expression
`JarvisGesture` / `JarvisExpression` dans `animator.dart`, logique dans `_advanceGesture()` /
`buildPose()`, rendu dans `renderer.dart::_drawFace`.

## Tests

`flutter test` — 8 fichiers couvrant math 3D, FK du rig, animateur, calculatrice,
cerveau autonome, compétences (sans réseau), mémoire (SQLite mocké en in-memory), persona.

## Confidentialité

Voir `docs/PRIVACY.md`. En résumé : tout vit sur l'appareil, sauf (a) vos appels Claude
(API Anthropic, avec votre clé), (b) la météo (open-meteo, sans clé, requête ville → coordonnées).

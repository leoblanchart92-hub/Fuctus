# ROADMAP — JARVIS AI

Légende : ✅ fait · 🟡 en cours · ⬜ prévu

## v1.0 — Fondation (session 1) ✅
- ✅ Analyse Coucou → leçons transférées moteur 3D logiciel
- ✅ Androïde procédural complet (19 articulations FK, mains 5 doigts, pieds, visor, réacteur Arc)
- ✅ Animations procédurales : respiration, balancement, regard errant, clignements, gestes (salut, nod, révérence)
- ✅ Expressions : neutre / sourire / réflexion / écoute / succès (visemes pendant la parole)
- ✅ IA : Claude API (configurable) + cerveau autonome hors-ligne (FR/EN)
- ✅ Mémoire persistante SQLite (faits, préférences, notes) injectée dans le contexte
- ✅ Voix : STT fr-FR + TTS, permission micro, mode texte défensif
- ✅ HUD futuriste : arc reactor animé, panneaux, 4 écrans
- ✅ CI GitHub Actions : analyze + test + build APK release (artifact)
- ✅ Tests unitaires (8 suites)

## v1.1 — Qualité de présence
- ⬜ CI verte : corriger erreurs analyse/build (le sandbox n'a pas de SDK Flutter)
- ⬜ Profilage FrameTime (Impeller) + degrés de détail selon la taille d'écran
- ⬜ Itération visuelle sur l'androïde (proportions, visagé, équipements) avec planches de rendu (coucou-style)
- ⬜ Bleep/bloop UI discrets (générés au runtime, pas d'assets)
- ⬜ Haptique synchronisée sur les réponses (léger tap)

## v1.2 — Intelligence continue
- ⬜ Extraction de mémoire via Claude (au lieu du heuristique local) + dédoublonnage sémantique
- ⬜ Résumé de conversation à la fermeture (« voici ce que j'ai retenu »)
- ⬜ Wake word (« Hey JARVIS ») via `porcupine` ou service on-device
- ⬜ Historique de conversations persistant (SQLite `messages`) + recherche plein texte

## v1.3 — Corps plus réel
- ⬜ Option GPU : personnage GLB/GLTF skinné chargé via `flutter_scene` (ou `three_dart` + `flutter_gl`),
      gardé en asset séparé du dépôt (LFS ou release assets) — voir discussion moteur dans `docs/ARCHITECTURE.md`
- ⬜ Visemes plus fins (a/e/i/o/u) pilotés par formants TTS
- ⬜ Idle animations variées (étirement, hochement d'observation), transitions Ease.back (déjà dans `Ease`)

## v1.4 — Extensions
- ⬜ Compétences : rappels planifiés (`flutter_local_notifications`), contrôle domotique (Home Assistant),
      recherche web, agenda local, minuteur/Pomodoro (reprise du concept Coucou doro de Coucou)
- ⬜ Widget Android + mode « écran verrouillé » / always-on
- ⬜ Raccourci Quick Settings & assistant système (falls back si rôle assistant non disponible)
- ⬜ Multi-langue complet (UI EN/FR/ES/DE)

## v2.0 — JARVIS compagnon
- ⬜ Profils multiples (famille), mémoire cloisonnée
- ⬜ Mode embarqué voiture / écran externe (MediaProjection ou dock)
- ⬜ Synchronisation multi-appareils via le `relay/` (inspiration Coucou : relais de présence)
- ⬜ Signing release officiel (keystore en GitHub secrets) + distribution Play Store interne

## Décisions d'architecture ouvertes
- Moteur 3D : conserver le rendu Canvas (robuste) **ou** migrer vers `flutter_scene` une fois
  l'API stable (exigerait un GLB skinné ~5–15 Mo, animations clip-based).
- Mémoire : passer d'un LIKE SQLite à un scoring ANN (sqlite-vec) si > 5 000 souvenirs.

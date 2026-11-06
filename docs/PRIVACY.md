# Confidentialité — JARVIS AI

**En résumé : tout ce que vous dites et écrivez reste sur votre appareil**, à deux exceptions près.

## Données traitées localement (jamais transmises)

- Mémoire persistante (faits, préférences, notes) : SQLite `jarvis_memory.db` dans le stockage privé de l'application.
- Réglages : `shared_preferences`.
- Clé API Anthropic : **stockage chiffré** (`flutter_secure_storage` / Android EncryptedSharedPreferences).
  Jamais dans le code, jamais dans git, jamais dans les logs.
- Conversation affichée : mémoire vive uniquement (effacée à la fermeture / via Réglages → « Effacer la conversation »).

## Données transmises à des tiers (uniquement sur votre action)

1. **API Anthropic (Claude)** — uniquement si vous avez renseigné une clé API et posé une question
   hors compétences locales. Le system prompt inclut jusqu'à 6 souvenirs pertinents (c'est le but :
   des réponses personnalisées). Consultez les conditions d'Anthropic pour le traitement côté serveur.
   Sans clé, ces échanges n'existent pas.
2. **open-meteo (météo)** — uniquement quand vous demandez la météo ; la ville est envoyée au
   service de géocodage d'open-meteo (gratuit, sans clé, sans cookie) puis les coordonnées au service de prévisions.

## Permissions Android

| Permission | Pourquoi | Sans elle |
|---|---|---|
| `RECORD_AUDIO` | Reconnaissance vocale (speech_to_text → service Google de l'appareil) | Mode texte uniquement |
| `INTERNET` | Claude API + météo | Mode autonome uniquement (plus météo) |
| Micro (feature, non requise) | Déclaré `required="false"` pour tenir compte des appareils sans micro | — |

Aucune permission : localisation précise, contacts, fichiers, appareil photo, analytics/crash SDKs.

## Capteur reco vocale

`speech_to_text` s'appuie sur le service de reconnaissance **de l'appareil** (généralement Google).
La dictée peut transiter par les serveurs de cet éditeur — c'est une propriété du service système,
configurable dans les paramètres Android au choix de l'utilisateur.

## Vos droits / contrôle

- Exporter : copiez les éléments depuis l'écran Mémoire (affichage texte).
- Supprimer : « Oublier » par souvenir, « Effacer » par note, ou tout effacer (Réglages → Système).
- Désinstaller supprime l'intégralité des données locales.

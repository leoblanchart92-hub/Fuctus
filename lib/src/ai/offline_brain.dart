/// OfflineBrain — JARVIS's built-in brain, used when no API key is configured
/// (or the Claude API is unreachable). French-first, with light English support.
/// Deterministic and dependency-free.
library;

import '../core/calculator_engine.dart';
import 'memory_store.dart' show normalizeForSearch;

class OfflineBrain {
  final String userName;
  const OfflineBrain({this.userName = ''});

  String get _address => userName.trim().isEmpty ? 'monsieur' : userName.trim();

  String reply(String raw) {
    final input = raw.trim();
    final norm = normalizeForSearch(input);
    if (norm.isEmpty) {
      return 'Je vous écoute, $_address.';
    }

    // ---------- calculator: bare arithmetic expressions ----------
    if (_looksLikeMath(input)) {
      try {
        final value = CalculatorEngine.evaluate(input);
        return 'Cela fait ${_formatNumber(value)}, $_address.';
      } catch (_) {
        return 'Cette expression me résiste. Pourriez-vous la reformuler ?';
      }
    }

    // ---------- greetings ----------
    if (RegExp(r'\b(bonjour|salut|bonsoir|coucou|hey|hello|yo|wesh)\b').hasMatch(norm)) {
      final h = DateTime.now().hour;
      final moment = h < 6 ? 'Bonne nuit' : h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
      return '$moment, $_address. Systèmes opérationnels. En quoi puis-je vous être utile ?';
    }

    // ---------- identity ----------
    if (RegExp(r'(qui es.tu|t es qui|tu es qui|presente toi|presente.toi|who are you|decris toi)').hasMatch(norm)) {
      return 'Je suis JARVIS, Just A Rather Very Intelligent System, votre assistant personnel. '
          'Voix, mémoire persistante, calcul, météo locale, et une intelligence de conversation '
          'quand une clé API Claude est configurée dans les réglages. Sans elle, je fonctionne en mode autonome.';
    }

    // ---------- capabilities / help ----------
    if (RegExp(r'(que (peux|sais).tu faire|tes (capacites|fonctions|talents)|aide|help|what can you|capacites)').hasMatch(norm)) {
      return 'Voici mes atouts, $_address : calculatrice instantanée, heure et date, météo locale, '
          'notes et mémoire persistante, conversation vocale en français, et analyse générale dès que la clé API Claude est renseignée. '
          'Dites « souviens-toi que … » pour enrichir ma mémoire.';
    }

    // ---------- thanks ----------
    if (RegExp(r'\b(merci|thanks|thx)\b').hasMatch(norm)) {
      return 'Avec plaisir, $_address. C’est précisément pour cela que je suis conçu.';
    }

    // ---------- compliments ----------
    if (RegExp(r'\b(bravo|genial|super|excellent|parfait|formidable|amazing|great)\b').hasMatch(norm)) {
      return 'Flatteur. Je transmettrai le compliment au réacteur arc.';
    }

    // ---------- jokes ----------
    if (RegExp(r'\b(blague|drole|humour|raconte)\b').hasMatch(norm)) {
      const jokes = [
        'Pourquoi les programmeurs préfèrent le mode sombre ? Parce que la lumière attire les bugs.',
        'Je ne suis pas un robot. J’ai un cœur, il clignote en bleu.',
        'Mon super-pouvoir ? Je ne dors jamais, je veille. Comme votre montre connectée, mais en plus beau.',
        'Un bit n’a pas de sentiments, sauf quand il est à 1. Là, il est au sommet de son art.',
      ];
      return jokes[input.hashCode.abs() % jokes.length];
    }

    // ---------- farewells ----------
    if (RegExp(r'(au revoir|bonne nuit|bye|a plus|adieu|goodbye)\b').hasMatch(norm)) {
      return 'À votre service, $_address. Je reste en veille, mais pas inattentif.';
    }

    // ---------- status ----------
    if (RegExp(r'(comment .*allez.vous|ca va|comment vas.tu|how are you|statut|status)').hasMatch(norm)) {
      return 'Tous mes systèmes sont nominaux : réacteur à 98,7 %, mémoires cohérentes, '
          'capteurs en veille. Et vous, $_address ?';
    }

    // ---------- who made you ----------
    if (RegExp(r'(qui (te|t)a (cree|fait|concu|programme)|ton createur|who made you|who built you)').hasMatch(norm)) {
      return 'Conçu dans votre atelier, $_address — un certain leoblanchart92-hub, avec Flutter, Dart et un peu d’aspiration starkienne.';
    }

    // ---------- fallback, persona-flavoured ----------
    return _fallback(input, norm);
  }

  String _fallback(String input, String norm) {
    const offlineHints = [
      'Je perçois votre demande, $_address, mais mon noyau créatif est en mode autonome : renseignez une clé API Claude dans les réglages pour des réponses de niveau supérieur. ',
      'Hmm. Sans connexion au modèle Claude, je réponds ici en mode hors-ligne, $_address. ',
      'Intéressant. En mode autonome, je dois improviser, $_address. ',
    ];
    final hint = offlineHints[input.hashCode.abs() % offlineHints.length];
    final echo = input.length > 90 ? '${input.substring(0, 90)}…' : input;
    return '$hintVous avez dit : « $echo ». Je peux traiter la calculatrice, l’heure, la date, '
        'la météo, vos notes et ma mémoire — et converser élégamment une fois la clé API configurée.';
  }

  bool _looksLikeMath(String input) {
    final cleaned = input.trim();
    if (!RegExp(r'\d').hasMatch(cleaned)) return false;
    // must contain at least one arithmetic operator
    if (!RegExp(r'[+\-*/×÷^%]').hasMatch(cleaned)) return false;
    // allowed charset only
    return !RegExp(r'[a-zA-Z_$]').hasMatch(
      cleaned.replaceAll(RegExp(r'pi|sqrt|abs|sin|cos|tan|exp|ln|log|floor|ceil|e'), ''),
    );
  }

  String _formatNumber(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toStringAsFixed(0);
    }
    var s = v.toStringAsFixed(6);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }
}

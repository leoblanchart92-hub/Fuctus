/// WeatherSkill — météo via open-meteo (gratuit, sans clé API).
/// Géocodage : https://geocoding-api.open-meteo.com · Prévisions : https://api.open-meteo.com
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'skill.dart';

class WeatherSkill extends JarvisSkill {
  @override
  String get id => 'weather';

  @override
  String get name => 'Météo';

  @override
  String get description => 'Météo actuelle d’une ville (open-meteo, sans clé).';

  @override
  List<String> get examplePhrases => const ['Météo à Strasbourg', 'Quel temps fait-il à Paris ?', 'Wetter in Lyon'];

  @override
  bool canHandle(String utterance) =>
      RegExp(r'(meteo|meteo a|quel temps|weather|wetter|meteo pour|temps fait.il)').hasMatch(utterance);

  static const _weatherCodes = <int, String>{
    0: 'ciel dégagé',
    1: 'plutôt dégagé',
    2: 'partiellement nuageux',
    3: 'couvert',
    45: 'brouillard',
    48: 'brouillard givrant',
    51: 'bruine légère',
    53: 'bruine modérée',
    55: 'bruine dense',
    56: 'bruine verglaçante légère',
    57: 'bruine verglaçante dense',
    61: 'pluie faible',
    63: 'pluie modérée',
    65: 'pluie forte',
    66: 'pluie verglaçante légère',
    67: 'pluie verglaçante forte',
    71: 'neige faible',
    73: 'neige modérée',
    75: 'neige forte',
    77: 'grains de neige',
    80: 'averses faibles',
    81: 'averses modérées',
    82: 'averses violentes',
    85: 'averses de neige faibles',
    86: 'averses de neige fortes',
    95: 'orage',
    96: 'orage avec grêle légère',
    99: 'orage avec grêle forte',
  };

  @override
  Future<SkillResult> handle(String utterance, SkillContext context) async {
    var city = _extractCity(utterance);
    if (city.isEmpty) city = context.defaultCity;

    try {
      final geoUri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(city)}&count=1&language=fr&format=json',
      );
      final geoResp = await http.get(geoUri).timeout(const Duration(seconds: 12));
      if (geoResp.statusCode != 200) {
        return SkillResult('Service de géocodage indisponible (HTTP ${geoResp.statusCode}).', isError: true);
      }
      final geo = jsonDecode(geoResp.body) as Map<String, dynamic>;
      final results = geo['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return SkillResult('Je ne localise pas « $city ». Essayez avec l’orthographe exacte.', isError: true);
      }
      final place = results.first as Map<String, dynamic>;
      final lat = (place['latitude'] as num).toDouble();
      final lon = (place['longitude'] as num).toDouble();
      final displayName = (place['name'] as String?) ?? city;
      final country = (place['country'] as String?) ?? '';

      final wxUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m'
        '&temperature_unit=celsius&wind_speed_unit=kmh&timezone=auto',
      );
      final wxResp = await http.get(wxUri).timeout(const Duration(seconds: 12));
      if (wxResp.statusCode != 200) {
        return SkillResult('Service météo indisponible (HTTP ${wxResp.statusCode}).', isError: true);
      }
      final wx = jsonDecode(wxResp.body) as Map<String, dynamic>;
      final current = wx['current'] as Map<String, dynamic>;
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final feels = (current['apparent_temperature'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt() ?? -1;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble();
      final humidity = (current['relative_humidity_2m'] as num?)?.toDouble();
      final description = _weatherCodes[code] ?? 'conditions indéterminées';

      return SkillResult(
        'À $displayName${country.isNotEmpty ? ' ($country)' : ''} : $description, '
        '${temp?.toStringAsFixed(1)} °C (ressenti ${feels?.toStringAsFixed(1)} °C), '
        'vent ${wind?.toStringAsFixed(0)} km/h, humidité ${humidity?.toStringAsFixed(0)} %.',
      );
    } catch (e) {
      return SkillResult('Météo inaccessible pour l’instant : $e', isError: true);
    }
  }

  String _extractCity(String utterance) {
    // « météo à Strasbourg », « quel temps fait-il à paris », « weather in Lyon »
    final match = RegExp(r'(?:a|à|à la|au|aux|in|pour|sur)\s+([a-zA-Zàâäéèêëîïôöùûüç\- ]+)$', caseSensitive: false)
        .firstMatch(utterance.trim());
    if (match != null) {
      var city = match.group(1)!.trim();
      // strip trailing filler words
      city = city.replaceAll(RegExp(r'\s+(aujourd.hui|ce soir|maintenant|svp|steuplait|please)$'), '');
      if (city.isNotEmpty) return city;
    }
    return '';
  }
}

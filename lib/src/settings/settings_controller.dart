/// SettingsController — persisted user preferences.
/// Secrets (API key) go to flutter_secure_storage; the rest to shared_preferences.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _secureKey = 'anthropic_api_key';

  // persisted keys
  static const _kUserName = 'user_name';
  static const _kUserTitle = 'user_title';
  static const _kCity = 'city';
  static const _kLanguage = 'language'; // 'fr_FR' | 'en_US'
  static const _kModel = 'model';
  static const _kTtsEnabled = 'tts_enabled';
  static const _kSpeechRate = 'speech_rate';
  static const _kPitch = 'pitch';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String userName = '';
  String userTitle = 'monsieur';
  String city = 'Strasbourg';
  String language = 'fr_FR';
  String model = 'claude-sonnet-4-5';
  bool ttsEnabled = true;
  double speechRate = 0.48;
  double pitch = 1.0;
  String apiKey = '';

  bool _loaded = false;
  bool get loaded => _loaded;

  static const List<String> modelPresets = [
    'claude-sonnet-4-5',
    'claude-opus-4-1',
    'claude-haiku-4-5',
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString(_kUserName) ?? '';
    userTitle = prefs.getString(_kUserTitle) ?? 'monsieur';
    city = prefs.getString(_kCity) ?? 'Strasbourg';
    language = prefs.getString(_kLanguage) ?? 'fr_FR';
    model = prefs.getString(_kModel) ?? 'claude-sonnet-4-5';
    ttsEnabled = prefs.getBool(_kTtsEnabled) ?? true;
    speechRate = prefs.getDouble(_kSpeechRate) ?? 0.48;
    pitch = prefs.getDouble(_kPitch) ?? 1.0;
    try {
      apiKey = await _secure.read(key: _secureKey) ?? '';
    } catch (_) {
      apiKey = '';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({
    String? userName,
    String? userTitle,
    String? city,
    String? language,
    String? model,
    bool? ttsEnabled,
    double? speechRate,
    double? pitch,
    String? apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      this.userName = userName.trim();
      await prefs.setString(_kUserName, this.userName);
    }
    if (userTitle != null) {
      this.userTitle = userTitle;
      await prefs.setString(_kUserTitle, this.userTitle);
    }
    if (city != null) {
      this.city = city.trim().isEmpty ? 'Strasbourg' : city.trim();
      await prefs.setString(_kCity, this.city);
    }
    if (language != null) {
      this.language = language;
      await prefs.setString(_kLanguage, this.language);
    }
    if (model != null) {
      this.model = model.trim();
      await prefs.setString(_kModel, this.model);
    }
    if (ttsEnabled != null) {
      this.ttsEnabled = ttsEnabled;
      await prefs.setBool(_kTtsEnabled, this.ttsEnabled);
    }
    if (speechRate != null) {
      this.speechRate = speechRate;
      await prefs.setDouble(_kSpeechRate, this.speechRate);
    }
    if (pitch != null) {
      this.pitch = pitch;
      await prefs.setDouble(_kPitch, this.pitch);
    }
    if (apiKey != null) {
      this.apiKey = apiKey.trim();
      try {
        if (this.apiKey.isEmpty) {
          await _secure.delete(key: _secureKey);
        } else {
          await _secure.write(key: _secureKey, value: this.apiKey);
        }
      } catch (_) {
        // secure storage unavailable — keep in memory only
      }
    }
    notifyListeners();
  }

  String get ttsLanguage => language == 'en_US' ? 'en-US' : 'fr-FR';
  String get sttLocale => language == 'en_US' ? 'en_US' : 'fr_FR';
  String get languageCode => language == 'en_US' ? 'en' : 'fr';
}

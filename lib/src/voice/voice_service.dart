/// VoiceService — speech recognition (speech_to_text) + natural voice (flutter_tts).
/// All plugin calls are defensive: the UI keeps working in text mode if the
/// microphone or TTS engine is unavailable.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool sttReady = false;
  bool ttsReady = false;
  bool isListening = false;
  bool isSpeaking = false;
  String? lastError;
  String liveTranscript = '';

  // callbacks wired by the controller
  void Function(String finalText)? onFinalSpeech;
  void Function()? onListeningStart;
  void Function()? onSpeakingStart;
  void Function()? onSpeakingEnd;

  String _locale = 'fr_FR';
  double _rate = 0.48;
  double _pitch = 1.0;

  Future<bool> init({
    required String locale,
    required String ttsLanguage,
    double rate = 0.48,
    double pitch = 1.0,
  }) async {
    _locale = locale;
    _rate = rate;
    _pitch = pitch;

    // microphone permission (required by speech_to_text on Android)
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        lastError = 'Permission microphone refusée';
        notifyListeners();
      }
    } catch (e) {
      lastError = 'Permission microphone indisponible : $e';
      notifyListeners();
    }

    // speech recognition
    try {
      sttReady = await _stt.initialize(
        onStatus: _onSttStatus,
        onError: _onSttError,
      );
    } catch (e) {
      sttReady = false;
      lastError = 'Reconnaissance vocale indisponible : $e';
    }

    // text to speech
    try {
      await _tts.setLanguage(ttsLanguage);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);
      _tts.setStartHandler(_handleSpeakStart);
      _tts.setCompletionHandler(_handleSpeakEnd);
      _tts.setCancelHandler(_handleSpeakEnd);
      _tts.setErrorHandler((_) => _handleSpeakEnd());
      ttsReady = true;
    } catch (e) {
      ttsReady = false;
      lastError = 'Synthèse vocale indisponible : $e';
    }

    notifyListeners();
    return sttReady;
  }

  Future<void> updateVoiceParams({required String ttsLanguage, required double rate, required double pitch, required String locale}) async {
    _locale = locale;
    _rate = rate;
    _pitch = pitch;
    try {
      await _tts.setLanguage(ttsLanguage);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
    } catch (_) {}
    notifyListeners();
  }

  // ------------------------------------------------------------- listening
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
      return;
    }
    await startListening();
  }

  Future<void> startListening() async {
    if (!sttReady) {
      lastError = 'Reconnaissance vocale non initialisée';
      notifyListeners();
      return;
    }
    liveTranscript = '';
    try {
      await _tts.stop();
      _handleSpeakEnd(); // make sure visemes stop if we were speaking
      await _stt.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: _locale,
      );
      isListening = true;
      onListeningStart?.call();
      notifyListeners();
    } catch (e) {
      isListening = false;
      lastError = 'Écoute impossible : $e';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    isListening = false;
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    liveTranscript = result.recognizedWords;
    if (result.finalResult) {
      isListening = false;
      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        onFinalSpeech?.call(text);
      }
    }
    notifyListeners();
  }

  void _onSttStatus(String status) {
    final listening = status == 'listening';
    if (!listening && isListening) {
      isListening = false;
    }
    notifyListeners();
  }

  void _onSttError(SpeechRecognitionError error) {
    isListening = false;
    lastError = 'Erreur micro : ${error.errorMsg}';
    notifyListeners();
  }

  // ------------------------------------------------------------- speaking
  Future<void> speak(String text) async {
    if (!ttsReady) return;
    final clean = _stripForSpeech(text);
    if (clean.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(clean);
    } catch (e) {
      lastError = 'Lecture vocale échouée : $e';
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _handleSpeakEnd();
  }

  void _handleSpeakStart() {
    isSpeaking = true;
    onSpeakingStart?.call();
    notifyListeners();
  }

  void _handleSpeakEnd() {
    if (!isSpeaking) return;
    isSpeaking = false;
    onSpeakingEnd?.call();
    notifyListeners();
  }

  static String _stripForSpeech(String text) {
    var s = text
        .replaceAll(RegExp(r'\*\*|__|`+'), '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'$1') // markdown links
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.length > 600) {
      s = '${s.substring(0, 600)}…';
    }
    return s;
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}

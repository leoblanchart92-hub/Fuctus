/// JARVIS AI — entry point.
/// Boots settings, persistent memory, voice, then the HUD.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jarvis_app.dart';
import 'src/core/jarvis_controller.dart';
import 'src/memory/sqflite_memory_store.dart';
import 'src/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // immersive, HUD-like presentation
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF04080E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final settings = SettingsController();
  await settings.load();

  final jarvis = JarvisController(
    settings: settings,
    memoryStore: SqfliteMemoryStore(),
  );

  try {
    await jarvis.init();
  } catch (e) {
    debugPrint('JARVIS boot warning: $e');
    // continue with whatever initialized — text mode always works
  }

  runApp(JarvisApp(settings: settings, jarvis: jarvis));
}

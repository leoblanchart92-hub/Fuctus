/// JarvisApp — root widget, providers, theme, routing.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/core/jarvis_controller.dart';
import 'src/settings/settings_controller.dart';
import 'src/ui/hud_theme.dart';
import 'src/ui/home_shell.dart';

class JarvisApp extends StatelessWidget {
  final SettingsController settings;
  final JarvisController jarvis;

  const JarvisApp({super.key, required this.settings, required this.jarvis});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<JarvisController>.value(value: jarvis),
      ],
      child: MaterialApp(
        title: 'JARVIS AI',
        debugShowCheckedModeBanner: false,
        theme: HudTheme.build(),
        home: const HomeShell(),
      ),
    );
  }
}

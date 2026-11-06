/// HomeShell — HUD navigation shell (bottom bar, futuristic styling).
library;

import 'package:flutter/material.dart';

import 'hud_theme.dart';
import 'screens/jarvis_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/skills_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      JarvisScreen(onOpenSettings: () => setState(() => _index = 3)),
      const MemoryScreen(),
      const SkillsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: HudPalette.backgroundAlt,
          border: Border(top: BorderSide(color: HudPalette.panelBorder)),
          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: HudPalette.cyanFaint,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 8.5,
                letterSpacing: 1.6,
                fontFamily: 'monospace',
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
                color: states.contains(WidgetState.selected) ? HudPalette.cyan : HudPalette.textSecondary,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 22,
                color: states.contains(WidgetState.selected) ? HudPalette.cyan : HudPalette.textSecondary,
              ),
            ),
            elevation: 0,
            height: 64,
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.blur_circular), label: 'JARVIS'),
              NavigationDestination(icon: Icon(Icons.memory_outlined), label: 'MÉMOIRE'),
              NavigationDestination(icon: Icon(Icons.extension_outlined), label: 'MODULES'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'RÉGLAGES'),
            ],
          ),
        ),
      ),
    );
  }
}

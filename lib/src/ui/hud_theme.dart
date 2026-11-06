/// HUD theme — futuristic JARVIS interface (deep space + arc-reactor cyan).
library;

import 'package:flutter/material.dart';

class HudPalette {
  static const Color background = Color(0xFF04080E);
  static const Color backgroundAlt = Color(0xFF050D16);
  static const Color panel = Color(0xCC0A1622);
  static const Color panelSolid = Color(0xFF0B1824);
  static const Color panelBorder = Color(0xFF1E4254);
  static const Color cyan = Color(0xFF5CE8FF);
  static const Color cyanDim = Color(0xFF2BB8D8);
  static const Color cyanFaint = Color(0x332BD8FF);
  static const Color amber = Color(0xFFFFC35C);
  static const Color red = Color(0xFFFF5C6A);
  static const Color textPrimary = Color(0xFFE6F4FA);
  static const Color textSecondary = Color(0xFF7FA8B8);
  static const Color textFaint = Color(0xFF4A6470);
}

class HudTheme {
  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: HudPalette.cyan,
      onPrimary: Color(0xFF032530),
      secondary: HudPalette.cyanDim,
      onSecondary: Color(0xFF032530),
      surface: HudPalette.panelSolid,
      onSurface: HudPalette.textPrimary,
      error: HudPalette.red,
      onError: Color(0xFF2B0508),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: HudPalette.background,
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: HudPalette.cyan,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 17,
          letterSpacing: 4,
          fontWeight: FontWeight.w700,
          color: HudPalette.cyan,
        ),
      ),
      iconTheme: const IconThemeData(color: HudPalette.cyan),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: HudPalette.cyan,
        selectionColor: HudPalette.cyanFaint,
        selectionHandleColor: HudPalette.cyan,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HudPalette.panelSolid,
        contentTextStyle: const TextStyle(color: HudPalette.cyan, fontFamily: 'monospace'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: HudPalette.panelBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HudPalette.panelSolid,
        hintStyle: const TextStyle(color: HudPalette.textFaint, fontFamily: 'monospace'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HudPalette.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HudPalette.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: HudPalette.cyan, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      dividerColor: HudPalette.panelBorder,
      sliderTheme: SliderThemeData(
        activeTrackColor: HudPalette.cyan,
        inactiveTrackColor: HudPalette.panelBorder,
        thumbColor: HudPalette.cyan,
        overlayColor: HudPalette.cyanFaint,
        valueIndicatorColor: HudPalette.panelSolid,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? HudPalette.cyan : HudPalette.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? HudPalette.cyanFaint : HudPalette.panelBorder),
      ),
    );
  }
}

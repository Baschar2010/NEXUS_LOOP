import 'package:flutter/material.dart';

class NexusColors {
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF181818);
  static const surface2 = Color(0xFF282828);
  static const elevated = Color(0xFF2A2A2A);
  static const green = Color(0xFF1DB954);
  static const greenLight = Color(0xFF1ED760);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFB3B3B3);
  static const dim = Color(0xFF535353);
  static const border = Color(0xFF2A2A2A);
}

ThemeData nexusTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NexusColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: NexusColors.green,
      secondary: NexusColors.greenLight,
      surface: NexusColors.surface,
      onPrimary: Colors.black,
      onSurface: NexusColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NexusColors.bg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: NexusColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: NexusColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: NexusColors.text),
      bodyMedium: TextStyle(color: NexusColors.text),
      bodySmall: TextStyle(color: NexusColors.muted),
      titleLarge: TextStyle(color: NexusColors.text, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: NexusColors.text, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(color: NexusColors.muted, fontWeight: FontWeight.w600),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: NexusColors.green,
      inactiveTrackColor: NexusColors.surface2,
      thumbColor: NexusColors.greenLight,
      overlayColor: NexusColors.green.withValues(alpha: 0.2),
    ),
    iconTheme: const IconThemeData(color: NexusColors.text),
  );
}
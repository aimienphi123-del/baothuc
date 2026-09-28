import 'package:flutter/material.dart';

/// Light and dark [ThemeData] for the app. Both derive from the same
/// seed color so component styling (buttons, chips, cards) stays
/// consistent between the two — only the surface/text tones invert.
class AppTheme {
  static const _seed = Color(0xFF2F6F4E);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  );
}

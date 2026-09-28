import 'package:flutter/material.dart';

/// Holds the app's current [ThemeMode]. Starts following the device
/// setting; the toggle button in the app bar switches between
/// explicit light and dark from there.
class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  void toggle() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  bool get isDark => mode == ThemeMode.dark;
}

import 'package:flutter/foundation.dart';

enum AppLang { vi, en }

/// Holds which language the app is currently showing. A plain
/// [ChangeNotifier], same as every other controller in this app —
/// no localization package needed for the app's own text, since a
/// small fixed dictionary (see [Strings]) is far simpler than
/// generated ARB-based localization for an app this size.
class AppLocaleController extends ChangeNotifier {
  AppLang lang = AppLang.vi;

  void toggle() {
    lang = lang == AppLang.vi ? AppLang.en : AppLang.vi;
    notifyListeners();
  }
}

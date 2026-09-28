import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/task/task_controller.dart';
import 'core/localization/app_locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'ui/task_list/task_list_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _themeController = ThemeController();
  final _localeController = AppLocaleController();
  final _taskController = TaskController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onChanged);
    _localeController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _themeController.removeListener(_onChanged);
    _localeController.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaoKhongNgu',
      debugShowCheckedModeBanner: false,
      themeMode: _themeController.mode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Localizes Flutter's own widgets (date picker, time picker,
      // "Cancel"/"OK" buttons, etc). The app's own text is handled
      // separately by Strings/AppLocaleController.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      locale: Locale(_localeController.lang.name),
      home: TaskListScreen(
        controller: _taskController,
        themeController: _themeController,
        localeController: _localeController,
      ),
    );
  }
}

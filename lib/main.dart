import 'dart:async';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'services/firebase_app_service.dart';
import 'services/notification_service.dart';
import 'services/server_time_service.dart';
import 'views/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseAppService.initialize();
  await NotificationService().initialize();
  await ThemeController.instance.init();
  unawaited(ServerTimeService.instance.sync());

  runApp(const PointSpendApp());
}

class PointSpendApp extends StatelessWidget {
  const PointSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PointSpend',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const MainShell(),
        );
      },
    );
  }
}

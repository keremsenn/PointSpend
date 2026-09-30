import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/main_shell.dart';

void main() {
  runApp(const PointSpendApp());
}

class PointSpendApp extends StatelessWidget {
  const PointSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PointSpend',
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

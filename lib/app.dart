import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

class ChapriApp extends StatelessWidget {
  const ChapriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chapri',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
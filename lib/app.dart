import 'package:flutter/material.dart';
import 'package:moneytrail/core/theme.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/screens/splash_screen.dart';
import 'package:provider/provider.dart';

class MoneyTrailApp extends StatelessWidget {
  const MoneyTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'MoneyTrail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}

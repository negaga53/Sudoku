import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sudoku_app/l10n/app_localizations.dart';
import 'package:sudoku_app/providers/settings_provider.dart';
import 'package:sudoku_app/screens/home_screen.dart';
import 'package:sudoku_app/theme/app_theme.dart';

class SudokuApp extends ConsumerWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final ThemeMode themeMode;
    if (settings.followSystem) {
      themeMode = ThemeMode.system;
    } else {
      themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }

    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(false, settings.accentColorIndex),
      darkTheme: AppTheme.getTheme(true, settings.accentColorIndex),
      themeMode: themeMode,
      locale: Locale(settings.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_pagination/pagination.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PaginationExampleApp());
}

class PaginationExampleApp extends StatefulWidget {
  const PaginationExampleApp({super.key});

  /// Global key to access app state for theme switching
  static final GlobalKey<_PaginationExampleAppState> appKey =
      GlobalKey<_PaginationExampleAppState>();

  /// Toggle between light and dark theme
  static void toggleTheme() {
    appKey.currentState?.toggleTheme();
  }

  /// Get current theme mode
  static ThemeMode get themeMode =>
      appKey.currentState?._themeMode ?? ThemeMode.light;

  @override
  State<PaginationExampleApp> createState() => _PaginationExampleAppState();
}

class _PaginationExampleAppState extends State<PaginationExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: PaginationExampleApp.appKey,
      routerConfig: appRouter,
      title: 'Smart Pagination Examples',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        extensions: [SmartSearchTheme.light()],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        extensions: [SmartSearchTheme.dark()],
      ),
    );
  }
}

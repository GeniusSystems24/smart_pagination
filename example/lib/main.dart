import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PaginationExampleApp());
}

class PaginationExampleApp extends StatelessWidget {
  const PaginationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pagination Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

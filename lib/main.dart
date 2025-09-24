import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const NartyApp());
}

class NartyApp extends StatelessWidget {
  const NartyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asystent Doboru Nart',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

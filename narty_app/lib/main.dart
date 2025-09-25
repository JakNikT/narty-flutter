import 'package:flutter/material.dart';
import 'screens/frame_demo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FrameDemoApp());
}

class FrameDemoApp extends StatelessWidget {
  const FrameDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frame Demo - Figma-like Layout',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FrameDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

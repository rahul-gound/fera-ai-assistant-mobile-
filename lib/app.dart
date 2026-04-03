// lib/app.dart

import 'package:flutter/material.dart';
import 'package:fera_ai_assistant/ui/screens/chat_screen.dart';

class FeraApp extends StatelessWidget {
  const FeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fera AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }

  // ---------------------------------------------------------------------------
  // Themes
  // ---------------------------------------------------------------------------

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4), // Purple — Fera brand colour
    brightness: Brightness.light,
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF6750A4),
    brightness: Brightness.dark,
  );
}

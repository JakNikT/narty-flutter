import 'package:flutter/material.dart';

/// Nowoczesny motyw kolorów - niebieski jak logo
class AppTheme {
  // Główne kolory - różne odcienie niebieskiego
  static const Color primary = Color(
    0xFFF0F8FF,
  ); // Bardzo jasny niebieski (główne tło)
  static const Color secondary = Color(
    0xFFDCEDFF,
  ); // Jasny niebieski (sekundarne tło)
  static const Color tertiary = Color(
    0xFFC8DCFF,
  ); // Średni jasny niebieski (ramki)

  // Akcenty - inspirowane niebieskim logo
  static const Color accent = Color(
    0xFF1E64AF,
  ); // Głęboki niebieski (główny akcent)
  static const Color accentHover = Color(
    0xFF14508C,
  ); // Ciemniejszy niebieski (hover)
  static const Color accentLight = Color(
    0xFF3B82F6,
  ); // Jaśniejszy niebieski (aktywne elementy)

  // Kolory funkcjonalne - kontrastowe na niebieskim tle
  static const Color success = Color(0xFF059669); // Zielony las (sukces)
  static const Color warning = Color(
    0xFFD97706,
  ); // Pomarańczowy zachód (ostrzeżenie)
  static const Color error = Color(0xFFDC2626); // Ciemny czerwony (błąd)
  static const Color info = Color(0xFF0284C7); // Niebieski lód (informacja)

  // Tekst - ciemny dla kontrastu na niebieskim tle
  static const Color textPrimary = Color(
    0xFF1F2937,
  ); // Prawie czarny (główny tekst)
  static const Color textSecondary = Color(
    0xFF374151,
  ); // Ciemny szary (drugorzędny tekst)

  /// Główny motyw aplikacji
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: accentLight,
        surface: primary,
        background: primary,
        error: error,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tertiary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: secondary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: tertiary, width: 2),
        ),
      ),
    );
  }

  /// Style dla przycisków z różnymi kolorami
  static ButtonStyle getButtonStyle(Color color, {Color? hoverColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  /// Style dla przycisków sukcesu
  static ButtonStyle get successButton => getButtonStyle(success);

  /// Style dla przycisków ostrzeżenia
  static ButtonStyle get warningButton => getButtonStyle(warning);

  /// Style dla przycisków błędu
  static ButtonStyle get errorButton => getButtonStyle(error);

  /// Style dla przycisków informacji
  static ButtonStyle get infoButton => getButtonStyle(info);

  /// Style dla przycisków akcentu
  static ButtonStyle get accentButton => getButtonStyle(accent);
}

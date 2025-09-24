import 'package:flutter/material.dart';

/// Motyw kolorów zgodny z projektem Figma
class AppTheme {
  // Kolory z projektu Figma
  static const Color primary = Color(0xFFFFFFFF); // Białe tło główne
  static const Color headerBackground = Color(0xFF386BB2); // Niebieski nagłówek
  static const Color resultsBackground = Color(
    0xFF386BB2,
  ); // Niebieski tło wyników
  static const Color formBackground = Color(
    0xFF194576,
  ); // Ciemny niebieski formularz
  static const Color sectionBackground = Color(
    0xFF2C699F,
  ); // Średni niebieski sekcje
  static const Color inputBackground = Color(
    0xFF194576,
  ); // Ciemny niebieski pola
  static const Color resultsInnerBackground = Color(
    0xFFA6C2EF,
  ); // Jasny niebieski wewnątrz wyników

  // Akcenty
  static const Color accent = Color(0xFF194576); // Główny akcent
  static const Color accentHover = Color(0xFF2C699F); // Hover
  static const Color accentLight = Color(0xFFA6C2EF); // Jaśniejszy akcent

  // Kolory funkcjonalne - kontrastowe na niebieskim tle
  static const Color success = Color(0xFF059669); // Zielony las (sukces)
  static const Color warning = Color(
    0xFFD97706,
  ); // Pomarańczowy zachód (ostrzeżenie)
  static const Color error = Color(0xFFDC2626); // Ciemny czerwony (błąd)
  static const Color info = Color(0xFF0284C7); // Niebieski lód (informacja)

  // Tekst - biały dla kontrastu na niebieskim tle
  static const Color textPrimary = Color(0xFFFFFFFF); // Biały tekst
  static const Color textSecondary = Color(0xFFE5E7EB); // Jasny szary tekst
  static const Color textDark = Color(0xFF000000); // Czarny tekst na jasnym tle

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
        error: error,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textPrimary,
        ),
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
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        filled: true,
        fillColor: inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: sectionBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white, width: 1),
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

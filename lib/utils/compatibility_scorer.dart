import 'dart:math';
import '../models/ski_match.dart';

/// Klasa do obliczania współczynnika idealności dopasowania nart
class CompatibilityScorer {
  // Domyślne wagi kryteriów (suma = 1.0)
  final Map<String, double> _wagiKryteriow = {
    'poziom': 0.35,      // 35% - Najważniejsze (bezpieczeństwo)
    'waga': 0.25,        // 25% - Bardzo ważne (kontrola nart)
    'wzrost': 0.20,      // 20% - Ważne (stabilność i zwrotność)
    'plec': 0.15,        // 15% - Mniej ważne (ergonomia)
    'przeznaczenie': 0.05 // 5% - Najmniej ważne (styl jazdy)
  };
  
  // Parametry funkcji gaussowskich dla różnych kryteriów
  final Map<String, double> _tolerancje = {
    'poziom': 1.0,       // Standardowe odchylenie dla poziomu
    'waga': 8.0,         // Standardowe odchylenie dla wagi (kg)
    'wzrost': 8.0,       // Standardowe odchylenie dla wzrostu (cm)
  };

  /// Oblicza wynik na podstawie funkcji gaussowskiej
  /// Zwraca wartość 0-1, gdzie 1 = idealne dopasowanie
  double _gaussianScore(double value, double target, double tolerance) {
    if (tolerance == 0) {
      return value == target ? 1.0 : 0.0;
    }
    
    final distance = (value - target).abs();
    return exp(-0.5 * pow(distance / tolerance, 2));
  }

  /// Ocenia dopasowanie poziomu umiejętności
  double _scorePoziom(int poziomKlienta, MatchCriteria poziomNartyInfo) {
    if (poziomNartyInfo.status == 'green' && poziomNartyInfo.opis.contains('OK')) {
      return 1.0; // Idealne dopasowanie
    } else if (poziomNartyInfo.status == 'orange') {
      if (poziomNartyInfo.opis.contains('jeden poziom')) {
        return 0.7; // Dobry wynik dla 1 poziom różnicy
      } else {
        return 0.4; // Słabszy wynik dla większych różnic
      }
    } else {
      return 0.1; // Bardzo słaby wynik
    }
  }

  /// Ocenia dopasowanie wagi
  double _scoreWaga(int wagaKlienta, MatchCriteria wagaNartyInfo) {
    if (wagaNartyInfo.status == 'green') {
      // Oblicz jak blisko środka zakresu jest klient
      final wagaMin = (int.tryParse(wagaNartyInfo.dodatkoweInfo1 ?? '0') ?? 0).toDouble();
      final wagaMax = (int.tryParse(wagaNartyInfo.dodatkoweInfo2 ?? '0') ?? 0).toDouble();
      final wagaSrodek = (wagaMin + wagaMax) / 2;
      return _gaussianScore(wagaKlienta.toDouble(), wagaSrodek, _tolerancje['waga']!);
    } else if (wagaNartyInfo.status == 'orange') {
      // Klient jest poza zakresem ale w tolerancji
      final wagaMin = (int.tryParse(wagaNartyInfo.dodatkoweInfo1 ?? '0') ?? 0).toDouble();
      final wagaMax = (int.tryParse(wagaNartyInfo.dodatkoweInfo2 ?? '0') ?? 0).toDouble();
      
      double distance;
      if (wagaKlienta > wagaMax) {
        distance = wagaKlienta - wagaMax;
      } else {
        distance = wagaMin - wagaKlienta;
      }
      
      // Im mniejsza odległość od zakresu, tym lepszy wynik
      return max(0.3, 0.8 - (distance / 10.0));
    } else {
      return 0.1;
    }
  }

  /// Ocenia dopasowanie wzrostu
  double _scoreWzrost(int wzrostKlienta, MatchCriteria wzrostNartyInfo) {
    if (wzrostNartyInfo.status == 'green') {
      // Oblicz jak blisko środka zakresu jest klient
      final wzrostMin = (int.tryParse(wzrostNartyInfo.dodatkoweInfo1 ?? '0') ?? 0).toDouble();
      final wzrostMax = (int.tryParse(wzrostNartyInfo.dodatkoweInfo2 ?? '0') ?? 0).toDouble();
      final wzrostSrodek = (wzrostMin + wzrostMax) / 2;
      return _gaussianScore(wzrostKlienta.toDouble(), wzrostSrodek, _tolerancje['wzrost']!);
    } else if (wzrostNartyInfo.status == 'orange') {
      // Klient jest poza zakresem ale w tolerancji
      final wzrostMin = (int.tryParse(wzrostNartyInfo.dodatkoweInfo1 ?? '0') ?? 0).toDouble();
      final wzrostMax = (int.tryParse(wzrostNartyInfo.dodatkoweInfo2 ?? '0') ?? 0).toDouble();
      
      double distance;
      if (wzrostKlienta > wzrostMax) {
        distance = wzrostKlienta - wzrostMax;
      } else {
        distance = wzrostMin - wzrostKlienta;
      }
      
      // Im mniejsza odległość od zakresu, tym lepszy wynik
      return max(0.3, 0.8 - (distance / 15.0));
    } else {
      return 0.1;
    }
  }

  /// Ocenia dopasowanie płci
  double _scorePlec(String plecKlienta, MatchCriteria plecNartyInfo) {
    if (plecNartyInfo.status == 'green' && plecNartyInfo.opis.contains('OK')) {
      return 1.0; // Idealne dopasowanie
    } else if (plecNartyInfo.status == 'orange') {
      if (plecNartyInfo.opis.contains('Narta męska') || plecNartyInfo.opis.contains('Narta kobieca')) {
        return 0.6; // Narta dla przeciwnej płci
      } else {
        return 0.8; // Inne problemy z płcią
      }
    } else {
      return 0.2;
    }
  }

  /// Ocenia dopasowanie przeznaczenia/stylu jazdy
  double _scorePrzeznaczenie(String? stylKlienta, MatchCriteria przeznaczenieNartyInfo) {
    if (stylKlienta == null || stylKlienta == "Wszystkie") {
      return 1.0; // Brak preferencji = pełny wynik
    }
    
    if (przeznaczenieNartyInfo.status == 'green' && przeznaczenieNartyInfo.opis.contains('OK')) {
      return 1.0; // Idealne dopasowanie stylu
    } else if (przeznaczenieNartyInfo.status == 'orange') {
      return 0.5; // Inne przeznaczenie
    } else {
      return 0.2;
    }
  }

  /// Główna funkcja obliczająca współczynnik idealności (0-100%)
  Map<String, dynamic> obliczWspolczynnikIdealnosci(
    Map<String, MatchCriteria> dopasowanie,
    int wzrostKlienta,
    int wagaKlienta,
    int poziomKlienta,
    String plecKlienta,
    String? stylKlienta,
  ) {
    final wynikiKryteriow = <String, double>{};
    
    // Oceń każde kryterium
    if (dopasowanie.containsKey('poziom')) {
      wynikiKryteriow['poziom'] = _scorePoziom(poziomKlienta, dopasowanie['poziom']!);
    }
    
    if (dopasowanie.containsKey('waga')) {
      wynikiKryteriow['waga'] = _scoreWaga(wagaKlienta, dopasowanie['waga']!);
    }
    
    if (dopasowanie.containsKey('wzrost')) {
      wynikiKryteriow['wzrost'] = _scoreWzrost(wzrostKlienta, dopasowanie['wzrost']!);
    }
    
    if (dopasowanie.containsKey('plec')) {
      wynikiKryteriow['plec'] = _scorePlec(plecKlienta, dopasowanie['plec']!);
    }
    
    if (dopasowanie.containsKey('przeznaczenie')) {
      wynikiKryteriow['przeznaczenie'] = _scorePrzeznaczenie(stylKlienta, dopasowanie['przeznaczenie']!);
    }
    
    // Oblicz ważoną średnią
    double sumaWazona = 0.0;
    double sumaWag = 0.0;
    
    for (final entry in wynikiKryteriow.entries) {
      final kryterium = entry.key;
      final wynik = entry.value;
      
      if (_wagiKryteriow.containsKey(kryterium)) {
        final waga = _wagiKryteriow[kryterium]!;
        sumaWazona += wynik * waga;
        sumaWag += waga;
      }
    }
    
    // Znormalizuj wynik do 0-100%
    double wspolczynnik = 0;
    if (sumaWag > 0) {
      wspolczynnik = (sumaWazona / sumaWag) * 100;
    }
    
    return {
      'wspolczynnik': wspolczynnik.roundToDouble(),
      'detale_oceny': wynikiKryteriow,
    };
  }

  /// Pozwala na dostosowanie wag kryteriów
  void ustawWagi(Map<String, double> noweWagi) {
    final suma = noweWagi.values.fold(0.0, (a, b) => a + b);
    if ((suma - 1.0).abs() > 0.01) {
      throw ArgumentError('Suma wag musi wynosić 1.0, a wynosi $suma');
    }
    
    _wagiKryteriow.addAll(noweWagi);
  }
}

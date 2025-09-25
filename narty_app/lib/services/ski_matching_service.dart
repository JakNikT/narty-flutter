import '../models/ski.dart';
import '../models/ski_match.dart';
import '../utils/level_parser.dart';
import '../utils/compatibility_scorer.dart';
import 'data_service.dart';

/// Serwis do dobierania nart
class SkiMatchingService {
  static final SkiMatchingService _instance = SkiMatchingService._internal();
  factory SkiMatchingService() => _instance;
  SkiMatchingService._internal();

  final DataService _dataService = DataService();
  final CompatibilityScorer _scorer = CompatibilityScorer();

  /// Sprawdza dopasowanie pojedynczej narty do kryteriów klienta
  SkiMatch? _checkSkiMatch(
    Ski ski,
    int wzrost,
    int waga,
    int poziom,
    String plec,
    String stylJazdy,
  ) {
    try {
      // Sprawdź czy wszystkie wymagane dane są dostępne
      if (ski.poziom.isEmpty ||
          ski.wagaMin == 0 ||
          ski.wagaMax == 0 ||
          ski.wzrostMin == 0 ||
          ski.wzrostMax == 0 ||
          ski.plec.isEmpty) {
        return null;
      }

      // Parsuj poziom w zależności od formatu
      final poziomResult = LevelParser.parseLevel(ski.poziom, plec);
      final poziomMin = poziomResult['poziom_min'] as int?;
      final poziomDisplay = poziomResult['poziom_display'] as String?;

      if (poziomMin == null) {
        return null;
      }

      // Sprawdź czy poziom nie jest o 2+ za niski - wyklucz całkowicie
      const int poziomTolerancjaWDol = 2;
      if (poziom < poziomMin - poziomTolerancjaWDol) {
        return null;
      }

      final dopasowanie = <String, MatchCriteria>{};
      int zielonePunkty = 0;
      bool poziomNizejKandydat = false;

      // Sprawdź poziom
      if (poziom == poziomMin) {
        dopasowanie['poziom'] = MatchCriteria(
          status: 'green',
          opis: 'OK',
          dodatkoweInfo1: poziomDisplay,
        );
        zielonePunkty++;
      } else if (poziom == poziomMin + 1) {
        dopasowanie['poziom'] = MatchCriteria(
          status: 'orange',
          opis: 'Narta słabsza o jeden poziom',
          dodatkoweInfo1: poziomDisplay,
        );
        poziomNizejKandydat = true;
      } else if (poziom > poziomMin + 1) {
        return null; // Wyklucz całkowicie
      } else {
        return null;
      }

      // Sprawdź płeć
      if (plec == "Wszyscy") {
        dopasowanie['plec'] = MatchCriteria(
          status: 'green',
          opis: 'OK',
          dodatkoweInfo1: ski.plec,
        );
        zielonePunkty++;
      } else if (plec == "Kobieta") {
        if (['K', 'D', 'U'].contains(ski.plec)) {
          dopasowanie['plec'] = MatchCriteria(
            status: 'green',
            opis: 'OK',
            dodatkoweInfo1: ski.plec,
          );
          zielonePunkty++;
        } else if (ski.plec == "M") {
          dopasowanie['plec'] = MatchCriteria(
            status: 'orange',
            opis: 'Narta męska',
            dodatkoweInfo1: ski.plec,
          );
        } else {
          dopasowanie['plec'] = MatchCriteria(
            status: 'orange',
            opis: 'Nieznana płeć',
            dodatkoweInfo1: ski.plec,
          );
        }
      } else if (plec == "Mężczyzna") {
        if (['M', 'U'].contains(ski.plec)) {
          dopasowanie['plec'] = MatchCriteria(
            status: 'green',
            opis: 'OK',
            dodatkoweInfo1: ski.plec,
          );
          zielonePunkty++;
        } else if (['K', 'D'].contains(ski.plec)) {
          dopasowanie['plec'] = MatchCriteria(
            status: 'orange',
            opis: 'Narta kobieca',
            dodatkoweInfo1: ski.plec,
          );
        } else {
          dopasowanie['plec'] = MatchCriteria(
            status: 'orange',
            opis: 'Nieznana płeć',
            dodatkoweInfo1: ski.plec,
          );
        }
      }

      // Sprawdź wagę
      const int wagaTolerancja = 5;
      if (waga >= ski.wagaMin && waga <= ski.wagaMax) {
        dopasowanie['waga'] = MatchCriteria(
          status: 'green',
          opis: 'OK',
          dodatkoweInfo1: ski.wagaMin.toString(),
          dodatkoweInfo2: ski.wagaMax.toString(),
        );
        zielonePunkty++;
      } else if (waga > ski.wagaMax && waga <= ski.wagaMax + wagaTolerancja) {
        dopasowanie['waga'] = MatchCriteria(
          status: 'orange',
          opis: 'O ${waga - ski.wagaMax} kg za duża (miększa)',
          dodatkoweInfo1: ski.wagaMin.toString(),
          dodatkoweInfo2: ski.wagaMax.toString(),
        );
      } else if (waga < ski.wagaMin && waga >= ski.wagaMin - wagaTolerancja) {
        dopasowanie['waga'] = MatchCriteria(
          status: 'orange',
          opis: 'O ${ski.wagaMin - waga} kg za mała (sztywniejsza)',
          dodatkoweInfo1: ski.wagaMin.toString(),
          dodatkoweInfo2: ski.wagaMax.toString(),
        );
      } else {
        dopasowanie['waga'] = MatchCriteria(
          status: 'red',
          opis: 'Niedopasowana',
          dodatkoweInfo1: ski.wagaMin.toString(),
          dodatkoweInfo2: ski.wagaMax.toString(),
        );
      }

      // Sprawdź wzrost
      const int wzrostTolerancja = 5;
      if (wzrost >= ski.wzrostMin && wzrost <= ski.wzrostMax) {
        dopasowanie['wzrost'] = MatchCriteria(
          status: 'green',
          opis: 'OK',
          dodatkoweInfo1: ski.wzrostMin.toString(),
          dodatkoweInfo2: ski.wzrostMax.toString(),
        );
        zielonePunkty++;
      } else if (wzrost > ski.wzrostMax &&
          wzrost <= ski.wzrostMax + wzrostTolerancja) {
        dopasowanie['wzrost'] = MatchCriteria(
          status: 'orange',
          opis: 'O ${wzrost - ski.wzrostMax} cm za duży (zwrotniejsza)',
          dodatkoweInfo1: ski.wzrostMin.toString(),
          dodatkoweInfo2: ski.wzrostMax.toString(),
        );
      } else if (wzrost < ski.wzrostMin &&
          wzrost >= ski.wzrostMin - wzrostTolerancja) {
        dopasowanie['wzrost'] = MatchCriteria(
          status: 'orange',
          opis: 'O ${ski.wzrostMin - wzrost} cm za mały (stabilniejsza)',
          dodatkoweInfo1: ski.wzrostMin.toString(),
          dodatkoweInfo2: ski.wzrostMax.toString(),
        );
      } else {
        dopasowanie['wzrost'] = MatchCriteria(
          status: 'red',
          opis: 'Niedopasowany',
          dodatkoweInfo1: ski.wzrostMin.toString(),
          dodatkoweInfo2: ski.wzrostMax.toString(),
        );
      }

      // Sprawdź przeznaczenie
      if (stylJazdy.isNotEmpty && stylJazdy != "Wszystkie") {
        if (ski.przeznaczenie.isNotEmpty) {
          final przeznaczenia = ski.przeznaczenie
              .split(',')
              .map((e) => e.trim())
              .toList();
          if (przeznaczenia.contains(stylJazdy)) {
            dopasowanie['przeznaczenie'] = MatchCriteria(
              status: 'green',
              opis: 'OK',
              dodatkoweInfo1: ski.przeznaczenie,
            );
            zielonePunkty++;
          } else {
            dopasowanie['przeznaczenie'] = MatchCriteria(
              status: 'orange',
              opis: 'Inne przeznaczenie (${ski.przeznaczenie})',
              dodatkoweInfo1: ski.przeznaczenie,
            );
          }
        } else {
          dopasowanie['przeznaczenie'] = MatchCriteria(
            status: 'orange',
            opis: 'Brak przeznaczenia',
            dodatkoweInfo1: '',
          );
        }
      } else {
        dopasowanie['przeznaczenie'] = MatchCriteria(
          status: 'green',
          opis: 'OK',
          dodatkoweInfo1: ski.przeznaczenie,
        );
      }

      // Wyklucz narty z czerwonymi kryteriami
      if (dopasowanie.values.any((v) => v.status == 'red')) {
        return null;
      }

      // Oblicz współczynnik idealności
      final wynik = _scorer.obliczWspolczynnikIdealnosci(
        dopasowanie,
        wzrost,
        waga,
        poziom,
        plec,
        stylJazdy,
      );

      return SkiMatch(
        ski: ski,
        dopasowanie: dopasowanie,
        wspolczynnikIdealnosci: wynik['wspolczynnik'] as double,
        zielonePunkty: zielonePunkty,
        poziomNizejKandydat: poziomNizejKandydat,
      );
    } catch (e) {
      print('Błąd podczas sprawdzania dopasowania narty: $e');
      return null;
    }
  }

  /// Znajduje narty z idealnym dopasowaniem
  List<SkiMatch> _findIdealMatches(
    List<Ski> skis,
    int wzrost,
    int waga,
    int poziom,
    String plec,
    String stylJazdy,
  ) {
    final idealne = <SkiMatch>[];
    final maxPunkty = (stylJazdy.isNotEmpty && stylJazdy != "Wszystkie")
        ? 5
        : 4;

    for (final ski in skis) {
      final match = _checkSkiMatch(ski, wzrost, waga, poziom, plec, stylJazdy);
      if (match != null && match.zielonePunkty == maxPunkty) {
        // Sprawdź czy to nie problem z płcią
        final plecStatus = match.dopasowanie['plec'];
        if (plecStatus != null && !plecStatus.opis.contains('OK')) {
          if (plecStatus.opis.contains('Narta męska') ||
              plecStatus.opis.contains('Narta kobieca')) {
            continue; // Pomiń - to będzie w "INNA PŁEĆ"
          }
        }
        idealne.add(match);
      }
    }

    return idealne;
  }

  /// Znajduje narty z poziomem za niskim
  List<SkiMatch> _findLevelTooLow(
    List<Ski> skis,
    int wzrost,
    int waga,
    int poziom,
    String plec,
    String stylJazdy,
  ) {
    final poziomZaNisko = <SkiMatch>[];
    final maxPunkty = (stylJazdy.isNotEmpty && stylJazdy != "Wszystkie")
        ? 5
        : 4;

    for (final ski in skis) {
      final match = _checkSkiMatch(ski, wzrost, waga, poziom, plec, stylJazdy);
      if (match != null && match.poziomNizejKandydat) {
        // Sprawdź czy reszta kryteriów jest OK
        final pozostalePunkty = match.zielonePunkty;
        final maxPozostalePunkty = maxPunkty - 1;

        if (pozostalePunkty == maxPozostalePunkty) {
          // Sprawdź czy to nie problem z płcią
          final plecStatus = match.dopasowanie['plec'];
          if (plecStatus != null && !plecStatus.opis.contains('OK')) {
            if (plecStatus.opis.contains('Narta męska') ||
                plecStatus.opis.contains('Narta kobieca')) {
              continue; // Pomiń - to będzie w "INNA PŁEĆ"
            }
          }
          poziomZaNisko.add(match);
        }
      }
    }

    return poziomZaNisko;
  }

  /// Znajduje narty alternatywne
  List<SkiMatch> _findAlternatives(
    List<Ski> skis,
    int wzrost,
    int waga,
    int poziom,
    String plec,
    String stylJazdy,
  ) {
    final alternatywy = <SkiMatch>[];
    final maxPunkty = (stylJazdy.isNotEmpty && stylJazdy != "Wszystkie")
        ? 5
        : 4;

    for (final ski in skis) {
      final match = _checkSkiMatch(ski, wzrost, waga, poziom, plec, stylJazdy);
      if (match != null &&
          !match.poziomNizejKandydat &&
          match.zielonePunkty < maxPunkty) {
        // Sprawdź czy to nie problem z płcią
        final plecStatus = match.dopasowanie['plec'];
        if (plecStatus != null && !plecStatus.opis.contains('OK')) {
          if (plecStatus.opis.contains('Narta męska') ||
              plecStatus.opis.contains('Narta kobieca')) {
            continue; // Pomiń - to będzie w "INNA PŁEĆ"
          }
        }
        alternatywy.add(match);
      }
    }

    return alternatywy;
  }

  /// Znajduje narty z niepasującą płcią
  List<SkiMatch> _findDifferentGender(
    List<Ski> skis,
    int wzrost,
    int waga,
    int poziom,
    String plec,
    String stylJazdy,
  ) {
    final innaPlec = <SkiMatch>[];
    final maxPunkty = (stylJazdy.isNotEmpty && stylJazdy != "Wszystkie")
        ? 5
        : 4;

    for (final ski in skis) {
      final match = _checkSkiMatch(ski, wzrost, waga, poziom, plec, stylJazdy);
      if (match != null && !match.poziomNizejKandydat) {
        // Sprawdź czy to problem z płcią
        final plecStatus = match.dopasowanie['plec'];
        if (plecStatus != null && !plecStatus.opis.contains('OK')) {
          if (plecStatus.opis.contains('Narta męska') ||
              plecStatus.opis.contains('Narta kobieca')) {
            // Sprawdź czy reszta kryteriów jest OK
            final pozostalePunkty = match.zielonePunkty;
            final maxPozostalePunkty =
                maxPunkty - 1; // Płeć nie liczy się do punktów

            if (pozostalePunkty == maxPozostalePunkty) {
              innaPlec.add(match);
            }
          }
        }
      }
    }

    return innaPlec;
  }

  /// Główna funkcja dobierania nart
  Future<Map<String, List<SkiMatch>>> findMatchingSkis(Client client) async {
    try {
      // Wczytaj wszystkie narty
      final wszystkieNarty = await _dataService.loadSkis();
      if (wszystkieNarty.isEmpty) {
        return {
          'idealne': [],
          'poziom_za_nisko': [],
          'alternatywy': [],
          'inna_plec': [],
        };
      }

      // Znajdź narty w każdej kategorii osobno
      final idealne = _findIdealMatches(
        wszystkieNarty,
        client.wzrost,
        client.waga,
        client.poziom,
        client.plec,
        client.stylJazdy,
      );
      final poziomZaNisko = _findLevelTooLow(
        wszystkieNarty,
        client.wzrost,
        client.waga,
        client.poziom,
        client.plec,
        client.stylJazdy,
      );
      final alternatywy = _findAlternatives(
        wszystkieNarty,
        client.wzrost,
        client.waga,
        client.poziom,
        client.plec,
        client.stylJazdy,
      );
      final innaPlec = _findDifferentGender(
        wszystkieNarty,
        client.wzrost,
        client.waga,
        client.poziom,
        client.plec,
        client.stylJazdy,
      );

      // Sortuj wyniki według współczynnika idealności
      idealne.sort(
        (a, b) => b.wspolczynnikIdealnosci.compareTo(a.wspolczynnikIdealnosci),
      );
      poziomZaNisko.sort(
        (a, b) => b.wspolczynnikIdealnosci.compareTo(a.wspolczynnikIdealnosci),
      );
      alternatywy.sort(
        (a, b) => b.wspolczynnikIdealnosci.compareTo(a.wspolczynnikIdealnosci),
      );
      innaPlec.sort(
        (a, b) => b.wspolczynnikIdealnosci.compareTo(a.wspolczynnikIdealnosci),
      );

      return {
        'idealne': idealne,
        'poziom_za_nisko': poziomZaNisko,
        'alternatywy': alternatywy,
        'inna_plec': innaPlec,
      };
    } catch (e) {
      print('Wystąpił błąd podczas dobierania nart: $e');
      return {
        'idealne': [],
        'poziom_za_nisko': [],
        'alternatywy': [],
        'inna_plec': [],
      };
    }
  }
}

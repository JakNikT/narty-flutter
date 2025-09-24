import 'package:flutter/services.dart';
import '../models/ski.dart';
import '../models/ski_match.dart';

/// Serwis do wczytywania i zarządzania danymi
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Ski> _allSkis = [];
  List<Reservation> _reservations = [];

  /// Wczytuje wszystkie narty z pliku CSV
  Future<List<Ski>> loadSkis() async {
    if (_allSkis.isNotEmpty) return _allSkis;

    try {
      final contents = await rootBundle.loadString(
        'assets/data/NOWABAZA_final.csv',
      );
      final lines = contents.split('\n');

      _allSkis = [];

      // Pomiń nagłówek (pierwszy wiersz)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length >= 14) {
          final ski = Ski.fromMap({
            'ID': values[0],
            'MARKA': values[1],
            'MODEL': values[2],
            'DLUGOSC': values[3],
            'ILOSC': values[4],
            'POZIOM': values[5],
            'PLEC': values[6],
            'WAGA_MIN': values[7],
            'WAGA_MAX': values[8],
            'WZROST_MIN': values[9],
            'WZROST_MAX': values[10],
            'PRZEZNACZENIE': values[11],
            'ROK': values[12],
            'UWAGI': values[13],
          });
          _allSkis.add(ski);
        }
      }

      return _allSkis;
    } catch (e) {
      print('Błąd podczas wczytywania nart: $e');
      return [];
    }
  }

  /// Parsuje linię CSV uwzględniając cudzysłowy
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString().trim());
    return result;
  }

  /// Wczytuje rezerwacje z pliku (symulacja - w prawdziwej aplikacji byłby to plik rez.csv)
  Future<List<Reservation>> loadReservations() async {
    if (_reservations.isNotEmpty) return _reservations;

    // Symulacja danych rezerwacji - w prawdziwej aplikacji wczytywałbyś z pliku rez.csv
    _reservations = [
      // Przykładowe rezerwacje
    ];

    return _reservations;
  }

  /// Sprawdza czy narta jest zarezerwowana w danym terminie
  Future<bool> isSkiReserved(
    String marka,
    String model,
    int dlugosc,
    DateTime dataOd,
    DateTime dataDo,
  ) async {
    final reservations = await loadReservations();

    for (final reservation in reservations) {
      if (reservation.marka == marka &&
          reservation.model == model &&
          reservation.dlugosc == dlugosc) {
        // Sprawdź czy terminy się nakładają
        if (!(dataDo.isBefore(reservation.dataOd) ||
            dataOd.isAfter(reservation.dataDo))) {
          return true;
        }
      }
    }

    return false;
  }

  /// Pobiera informacje o rezerwacji narty
  Future<Map<String, dynamic>?> getReservationInfo(
    String marka,
    String model,
    int dlugosc,
    DateTime dataOd,
    DateTime dataDo,
  ) async {
    final reservations = await loadReservations();

    for (final reservation in reservations) {
      if (reservation.marka == marka &&
          reservation.model == model &&
          reservation.dlugosc == dlugosc) {
        // Sprawdź czy terminy się nakładają
        if (!(dataDo.isBefore(reservation.dataOd) ||
            dataOd.isAfter(reservation.dataDo))) {
          return {
            'isReserved': true,
            'period':
                '${reservation.dataOd.day}/${reservation.dataOd.month}/${reservation.dataOd.year} - ${reservation.dataDo.day}/${reservation.dataDo.month}/${reservation.dataDo.year}',
            'number': reservation.numerNarty,
            'client': reservation.klient,
          };
        }
      }
    }

    return {'isReserved': false};
  }

  /// Filtruje narty według kryteriów
  List<Ski> filterSkis(
    List<Ski> skis, {
    String? marka,
    String? poziom,
    String? plec,
    String? searchText,
  }) {
    return skis.where((ski) {
      if (marka != null && marka != 'Wszystkie' && ski.marka != marka) {
        return false;
      }

      if (poziom != null && poziom != 'Wszystkie' && ski.poziom != poziom) {
        return false;
      }

      if (plec != null && plec != 'Wszystkie' && ski.plec != plec) {
        return false;
      }

      if (searchText != null && searchText.isNotEmpty) {
        final searchLower = searchText.toLowerCase();
        if (!ski.marka.toLowerCase().contains(searchLower) &&
            !ski.model.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}

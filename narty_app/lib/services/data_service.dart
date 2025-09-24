import 'dart:io';
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
      final file = File('assets/data/NOWABAZA_final.csv');
      final contents = await file.readAsString();
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

  /// Wczytuje rezerwacje z pliku rez.csv
  Future<List<Reservation>> loadReservations() async {
    if (_reservations.isNotEmpty) return _reservations;

    try {
      final file = File('assets/data/rez.csv');
      final contents = await file.readAsString();
      final lines = contents.split('\n');

      _reservations = [];

      // Pomiń nagłówek (pierwszy wiersz) i spróbuj z header=1
      for (int i = 2; i < lines.length; i++) {
        // Start from index 2 (header=1)
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length >= 6) {
          // Sprawdź czy to rezerwacja nart
          final sprzet = values[4]; // Kolumna Sprzęt (index 4)
          if (sprzet.contains('NARTY')) {
            final reservation = _parseReservation(values);
            if (reservation != null) {
              _reservations.add(reservation);
            }
          }
        }
      }

      return _reservations;
    } catch (e) {
      print('Błąd podczas wczytywania rezerwacji: $e');
      return [];
    }
  }

  /// Parsuje wiersz rezerwacji z CSV
  Reservation? _parseReservation(List<String> values) {
    try {
      // Format: [Od, Do, Użytkownik, Klient, Sprzęt, ...]
      final dataOd = DateTime.parse(values[0]);
      final dataDo = DateTime.parse(values[1]);
      final sprzet = values[4];
      final klient = values.length > 3 ? values[3] : 'Nieznany';

      // Wyciągnij informacje o narcie z opisu sprzętu
      final parts = sprzet.split(' ');
      if (parts.length < 4) return null;

      final marka = parts[1];
      String model = '';
      int dlugosc = 0;
      String numerNarty = '';

      // Znajdź model (wszystko między marką a długością)
      final modelParts = <String>[];

      for (int i = 2; i < parts.length; i++) {
        final part = parts[i];
        if (part.contains('cm')) {
          dlugosc = int.tryParse(part.replaceAll('cm', '')) ?? 0;
          break;
        }
        modelParts.add(part);
      }

      model = modelParts.join(' ');

      // Znajdź numer narty (//XX)
      for (final part in parts) {
        if (part.startsWith('//') && part.length > 2) {
          numerNarty = part;
          break;
        }
      }

      if (marka.isNotEmpty && model.isNotEmpty && dlugosc > 0) {
        return Reservation(
          marka: marka,
          model: model,
          dlugosc: dlugosc,
          numerNarty: numerNarty,
          dataOd: dataOd,
          dataDo: dataDo,
          klient: klient,
        );
      }

      return null;
    } catch (e) {
      print('Błąd podczas parsowania rezerwacji: $e');
      return null;
    }
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
            'dataOd': reservation.dataOd,
            'dataDo': reservation.dataDo,
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

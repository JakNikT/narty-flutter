import 'ski.dart';

/// Model dopasowania narty do klienta
class SkiMatch {
  final Ski ski;
  final Map<String, MatchCriteria> dopasowanie;
  final double wspolczynnikIdealnosci;
  final int zielonePunkty;
  final bool poziomNizejKandydat;

  SkiMatch({
    required this.ski,
    required this.dopasowanie,
    required this.wspolczynnikIdealnosci,
    required this.zielonePunkty,
    required this.poziomNizejKandydat,
  });
}

/// Model kryterium dopasowania
class MatchCriteria {
  final String status; // 'green', 'orange', 'red'
  final String opis;
  final String? dodatkoweInfo1;
  final String? dodatkoweInfo2;

  MatchCriteria({
    required this.status,
    required this.opis,
    this.dodatkoweInfo1,
    this.dodatkoweInfo2,
  });

  factory MatchCriteria.fromTuple(List<dynamic> tuple) {
    return MatchCriteria(
      status: tuple[0]?.toString() ?? '',
      opis: tuple[1]?.toString() ?? '',
      dodatkoweInfo1: tuple.length > 2 ? tuple[2]?.toString() : null,
      dodatkoweInfo2: tuple.length > 3 ? tuple[3]?.toString() : null,
    );
  }
}

/// Model klienta
class Client {
  final int wzrost;
  final int waga;
  final int poziom;
  final String plec;
  final String stylJazdy;
  final DateTime dataOd;
  final DateTime dataDo;

  Client({
    required this.wzrost,
    required this.waga,
    required this.poziom,
    required this.plec,
    required this.stylJazdy,
    required this.dataOd,
    required this.dataDo,
  });
}

/// Model rezerwacji
class Reservation {
  final String marka;
  final String model;
  final int dlugosc;
  final String numerNarty;
  final DateTime dataOd;
  final DateTime dataDo;
  final String klient;

  Reservation({
    required this.marka,
    required this.model,
    required this.dlugosc,
    required this.numerNarty,
    required this.dataOd,
    required this.dataDo,
    required this.klient,
  });
}

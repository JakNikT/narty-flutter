/// Model danych narty
class Ski {
  final String id;
  final String marka;
  final String model;
  final int dlugosc;
  final int ilosc;
  final String poziom;
  final String plec;
  final int wagaMin;
  final int wagaMax;
  final int wzrostMin;
  final int wzrostMax;
  final String przeznaczenie;
  final String rok;
  final String uwagi;
  final double? promien;
  final double? podButem;

  Ski({
    required this.id,
    required this.marka,
    required this.model,
    required this.dlugosc,
    required this.ilosc,
    required this.poziom,
    required this.plec,
    required this.wagaMin,
    required this.wagaMax,
    required this.wzrostMin,
    required this.wzrostMax,
    required this.przeznaczenie,
    required this.rok,
    required this.uwagi,
    this.promien,
    this.podButem,
  });

  factory Ski.fromMap(Map<String, dynamic> map) {
    return Ski(
      id: map['ID']?.toString() ?? '',
      marka: map['MARKA']?.toString() ?? '',
      model: map['MODEL']?.toString() ?? '',
      dlugosc: int.tryParse(map['DLUGOSC']?.toString() ?? '0') ?? 0,
      ilosc: int.tryParse(map['ILOSC']?.toString() ?? '1') ?? 1,
      poziom: map['POZIOM']?.toString() ?? '',
      plec: map['PLEC']?.toString() ?? '',
      wagaMin: int.tryParse(map['WAGA_MIN']?.toString() ?? '0') ?? 0,
      wagaMax: int.tryParse(map['WAGA_MAX']?.toString() ?? '0') ?? 0,
      wzrostMin: int.tryParse(map['WZROST_MIN']?.toString() ?? '0') ?? 0,
      wzrostMax: int.tryParse(map['WZROST_MAX']?.toString() ?? '0') ?? 0,
      przeznaczenie: map['PRZEZNACZENIE']?.toString() ?? '',
      rok: map['ROK']?.toString() ?? '',
      uwagi: map['UWAGI']?.toString() ?? '',
      promien: double.tryParse(
        map['PROMIEN']?.toString().replaceAll(',', '.') ?? '0',
      ),
      podButem: double.tryParse(map['POD_BUTEM']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'MARKA': marka,
      'MODEL': model,
      'DLUGOSC': dlugosc,
      'ILOSC': ilosc,
      'POZIOM': poziom,
      'PLEC': plec,
      'WAGA_MIN': wagaMin,
      'WAGA_MAX': wagaMax,
      'WZROST_MIN': wzrostMin,
      'WZROST_MAX': wzrostMax,
      'PRZEZNACZENIE': przeznaczenie,
      'ROK': rok,
      'UWAGI': uwagi,
      'PROMIEN': promien,
      'POD_BUTEM': podButem,
    };
  }
}

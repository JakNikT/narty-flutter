import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ski_match.dart';
import '../utils/theme.dart';

/// Formularz danych klienta
class ClientForm extends StatefulWidget {
  final Function(Client) onFindSkis;
  final VoidCallback onClearForm;

  const ClientForm({
    super.key,
    required this.onFindSkis,
    required this.onClearForm,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _wzrostController = TextEditingController();
  final _wagaController = TextEditingController();
  final _poziomController = TextEditingController();
  final _plecController = TextEditingController();
  final _odDzienController = TextEditingController();
  final _odMiesiacController = TextEditingController();
  final _odRokController = TextEditingController();
  final _doDzienController = TextEditingController();
  final _doMiesiacController = TextEditingController();
  final _doRokController = TextEditingController();

  String _stylJazdy = 'Wszystkie';
  String _plec = 'Wszyscy';

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
  }

  @override
  void dispose() {
    _wzrostController.dispose();
    _wagaController.dispose();
    _poziomController.dispose();
    _plecController.dispose();
    _odDzienController.dispose();
    _odMiesiacController.dispose();
    _odRokController.dispose();
    _doDzienController.dispose();
    _doMiesiacController.dispose();
    _doRokController.dispose();
    super.dispose();
  }

  /// Ustawia domyślne daty (dzisiaj i za tydzień)
  void _setDefaultDates() {
    final now = DateTime.now();
    final future = now.add(const Duration(days: 7));

    _odDzienController.text = now.day.toString().padLeft(2, '0');
    _odMiesiacController.text = now.month.toString().padLeft(2, '0');
    _odRokController.text = now.year.toString().substring(2);

    _doDzienController.text = future.day.toString().padLeft(2, '0');
    _doMiesiacController.text = future.month.toString().padLeft(2, '0');
    _doRokController.text = future.year.toString().substring(2);
  }

  /// Waliduje i wysyła formularz
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      try {
        // Używamy domyślnych dat zamiast pól wejściowych
        final now = DateTime.now();
        final future = now.add(const Duration(days: 7));

        final dataOd = now;
        final dataDo = future;

        final client = Client(
          wzrost: int.parse(_wzrostController.text),
          waga: int.parse(_wagaController.text),
          poziom: int.parse(_poziomController.text),
          plec: _plec,
          stylJazdy: _stylJazdy,
          dataOd: dataOd,
          dataDo: dataDo,
        );

        widget.onFindSkis(client);
      } catch (e) {
        _showError('Błąd podczas tworzenia klienta: $e');
      }
    }
  }

  /// Czyści formularz
  void _clearForm() {
    _formKey.currentState?.reset();
    _wzrostController.clear();
    _wagaController.clear();
    _poziomController.clear();
    _plecController.clear();
    setState(() {
      _stylJazdy = 'Wszystkie';
      _plec = 'Wszyscy';
    });
    _setDefaultDates();
    widget.onClearForm();
  }

  /// Pokazuje błąd
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Daty rezerwacji - WYŁĄCZONE
          // Row(
          //   children: [
          //     Expanded(
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           const Text('📅 Data od:'),
          //           const SizedBox(height: 4),
          //           Row(
          //             children: [
          //               SizedBox(
          //                 width: 50,
          //                 child: TextFormField(
          //                   controller: _odDzienController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'DD',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(2),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz dzień';
          //                     final day = int.tryParse(value);
          //                     if (day == null || day < 1 || day > 31) {
          //                       return 'Nieprawidłowy dzień';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //               const SizedBox(width: 4),
          //               SizedBox(
          //                 width: 50,
          //                 child: TextFormField(
          //                   controller: _odMiesiacController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'MM',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(2),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz miesiąc';
          //                     final month = int.tryParse(value);
          //                     if (month == null || month < 1 || month > 12) {
          //                       return 'Nieprawidłowy miesiąc';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //               const SizedBox(width: 4),
          //               SizedBox(
          //                 width: 60,
          //                 child: TextFormField(
          //                   controller: _odRokController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'RR',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(4),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz rok';
          //                     final year = int.tryParse(value);
          //                     if (year == null || year < 2000) {
          //                       return 'Nieprawidłowy rok';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     Expanded(
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           const Text('📅 Data do:'),
          //           const SizedBox(height: 4),
          //           Row(
          //             children: [
          //               SizedBox(
          //                 width: 50,
          //                 child: TextFormField(
          //                   controller: _doDzienController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'DD',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(2),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz dzień';
          //                     final day = int.tryParse(value);
          //                     if (day == null || day < 1 || day > 31) {
          //                       return 'Nieprawidłowy dzień';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //               const SizedBox(width: 4),
          //               SizedBox(
          //                 width: 50,
          //                 child: TextFormField(
          //                   controller: _doMiesiacController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'MM',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(2),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz miesiąc';
          //                     final month = int.tryParse(value);
          //                     if (month == null || month < 1 || month > 12) {
          //                       return 'Nieprawidłowy miesiąc';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //               const SizedBox(width: 4),
          //               SizedBox(
          //                 width: 60,
          //                 child: TextFormField(
          //                   controller: _doRokController,
          //                   decoration: const InputDecoration(
          //                     hintText: 'RR',
          //                     isDense: true,
          //                   ),
          //                   keyboardType: TextInputType.number,
          //                   inputFormatters: [
          //                     FilteringTextInputFormatter.digitsOnly,
          //                     LengthLimitingTextInputFormatter(4),
          //                   ],
          //                   validator: (value) {
          //                     if (value == null || value.isEmpty)
          //                       return 'Wpisz rok';
          //                     final year = int.tryParse(value);
          //                     if (year == null || year < 2000) {
          //                       return 'Nieprawidłowy rok';
          //                     }
          //                     return null;
          //                   },
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: 16),

          // Wzrost i waga
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _wzrostController,
                  decoration: const InputDecoration(
                    labelText: '📏 Wzrost (cm)',
                    hintText: 'np. 175',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wpisz wzrost';
                    final height = int.tryParse(value);
                    if (height == null || height < 100 || height > 250) {
                      return 'Wzrost musi być między 100 a 250 cm';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _wagaController,
                  decoration: const InputDecoration(
                    labelText: '⚖️ Waga (kg)',
                    hintText: 'np. 70',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wpisz wagę';
                    final weight = int.tryParse(value);
                    if (weight == null || weight < 20 || weight > 200) {
                      return 'Waga musi być między 20 a 200 kg';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Poziom i płeć
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _poziomController,
                  decoration: const InputDecoration(
                    labelText: '🎯 Poziom',
                    hintText: '1-6',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wpisz poziom';
                    final level = int.tryParse(value);
                    if (level == null || level < 1 || level > 6) {
                      return 'Poziom musi być między 1 a 6';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _plec,
                  decoration: const InputDecoration(labelText: '👤 Płeć'),
                  items: const [
                    DropdownMenuItem(value: 'Wszyscy', child: Text('Wszyscy')),
                    DropdownMenuItem(
                      value: 'Mężczyzna',
                      child: Text('Mężczyzna'),
                    ),
                    DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _plec = value ?? 'Wszyscy';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Przeznaczenie
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎿 Przeznaczenie:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildStyleRadio('Wszystkie', 'Wszystkie'),
                  _buildStyleRadio('Slalom (SL)', 'SL'),
                  _buildStyleRadio('Gigant (G)', 'G'),
                  _buildStyleRadio('Performance (SLG)', 'SLG'),
                  _buildStyleRadio('Cały dzień (C)', 'C'),
                  _buildStyleRadio('Poza trasę (OFF)', 'OFF'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Przyciski
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.search),
                  label: const Text('🔍 Znajdź'),
                  style: AppTheme.successButton,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('🗑️ Wyczyść'),
                  style: AppTheme.warningButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tworzy radio button dla stylu jazdy
  Widget _buildStyleRadio(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _stylJazdy,
          onChanged: (newValue) {
            setState(() {
              _stylJazdy = newValue ?? 'Wszystkie';
            });
          },
        ),
        Text(label),
      ],
    );
  }
}

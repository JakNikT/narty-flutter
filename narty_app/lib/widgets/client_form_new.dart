import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ski_match.dart';
import '../utils/theme.dart';

/// Formularz danych klienta zgodny z projektem Figma
class ClientFormNew extends StatefulWidget {
  final Function(Client) onFindSkis;
  final VoidCallback onClearForm;

  const ClientFormNew({
    super.key,
    required this.onFindSkis,
    required this.onClearForm,
  });

  @override
  State<ClientFormNew> createState() => _ClientFormNewState();
}

class _ClientFormNewState extends State<ClientFormNew> {
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // TEST: Yellow square for header position
            Container(
              width: 230,
              height: 50,
              color: Colors.yellow.withValues(alpha: 0.3),
              child: const Center(
                child: Text(
                  'DANE KLIENTA\n(center top)',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 5),
            
            // Dane klienta header
            Container(
              width: 230,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.resultsInnerBackground,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Dane klienta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Three sections positioned
            SizedBox(
              height: 180, // Wysokość formularza
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // TEST: Red square for left container position
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 307,
                      height: 160,
                      color: Colors.red.withValues(alpha: 0.3),
                      child: const Center(
                        child: Text(
                          'LEWY\n(15, 10)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  // Left side - Date and physical data (x:10, y:10, w:307, h:160)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 307,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.sectionBackground,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            // Date section
                            Expanded(
                              child: Column(
                                children: [
                                  // Data od
                                  Row(
                                    children: [
                                      Container(
                                        width: 111,
                                        height: 29,
                                        decoration: BoxDecoration(
                                          color: AppTheme.inputBackground,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '📅 Data od:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 37,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _odDzienController,
                                          decoration: const InputDecoration(
                                            hintText: 'DD',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        '/',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 37,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _odMiesiacController,
                                          decoration: const InputDecoration(
                                            hintText: 'MM',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        '/',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 61,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _odRokController,
                                          decoration: const InputDecoration(
                                            hintText: 'RR',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Data do
                                  Row(
                                    children: [
                                      Container(
                                        width: 111,
                                        height: 29,
                                        decoration: BoxDecoration(
                                          color: AppTheme.inputBackground,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '📅 Data do:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 37,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _doDzienController,
                                          decoration: const InputDecoration(
                                            hintText: 'DD',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        '/',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 37,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _doMiesiacController,
                                          decoration: const InputDecoration(
                                            hintText: 'MM',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        '/',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 61,
                                        height: 29,
                                        child: TextFormField(
                                          controller: _doRokController,
                                          decoration: const InputDecoration(
                                            hintText: 'RR',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 4,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Height and weight
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 31,
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputBackground,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextFormField(
                                      controller: _wzrostController,
                                      decoration: const InputDecoration(
                                        labelText: '📏 Wzrost:',
                                        labelStyle: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Wpisz wzrost';
                                        }
                                        final height = int.tryParse(value);
                                        if (height == null ||
                                            height < 100 ||
                                            height > 250) {
                                          return 'Wzrost musi być między 100 a 250 cm';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 31,
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputBackground,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextFormField(
                                      controller: _wagaController,
                                      decoration: const InputDecoration(
                                        labelText: '⚖️ Waga:',
                                        labelStyle: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Wpisz wagę';
                                        }
                                        final weight = int.tryParse(value);
                                        if (weight == null ||
                                            weight < 20 ||
                                            weight > 200) {
                                          return 'Waga musi być między 20 a 200 kg';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // TEST: Blue square for center container position
                  Positioned(
                    left: 350,
                    top: 120,
                    child: Container(
                      width: 230,
                      height: 96,
                      color: Colors.blue.withValues(alpha: 0.3),
                      child: const Center(
                        child: Text(
                          'ŚRODEK\n(350, 120)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  // Center - Gender and level (center bottom)
                  Positioned(
                    left: 350,
                    top: 120,
                    child: Container(
                      width: 230,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.sectionBackground,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            // Level
                            Container(
                              height: 35,
                              decoration: BoxDecoration(
                                color: AppTheme.inputBackground,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextFormField(
                                controller: _poziomController,
                                decoration: const InputDecoration(
                                  labelText: '🎯 Poziom:',
                                  labelStyle: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Wpisz poziom';
                                  }
                                  final level = int.tryParse(value);
                                  if (level == null || level < 1 || level > 6) {
                                    return 'Poziom musi być między 1 a 6';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Gender
                            Container(
                              height: 35,
                              decoration: BoxDecoration(
                                color: AppTheme.inputBackground,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _plec,
                                decoration: const InputDecoration(
                                  labelText: '👤 Płeć:',
                                  labelStyle: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                ),
                                dropdownColor: AppTheme.inputBackground,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Wszyscy',
                                    child: Text('Wszyscy'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Mężczyzna',
                                    child: Text('Mężczyzna'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Kobieta',
                                    child: Text('Kobieta'),
                                  ),
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
                      ),
                    ),
                  ),

                  // TEST: Green square for right container position
                  Positioned(
                    left: 680,
                    top: 10,
                    child: Container(
                      width: 307,
                      height: 160,
                      color: Colors.green.withValues(alpha: 0.3),
                      child: const Center(
                        child: Text(
                          'PRAWY\n(680, 10)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  // Right side - Preferences (right side, centered vertically)
                  Positioned(
                    left: 680,
                    top: 10,
                    child: Container(
                      width: 307,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.sectionBackground,
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            const Text(
                              'Preferencje:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Style preferences
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildStyleRadio(
                                        'Wszystkie',
                                        'Wszystkie',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStyleRadio('Slalom', 'SL'),
                                      const SizedBox(width: 8),
                                      _buildStyleRadio('Gigant', 'G'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildStyleRadio('Cały dzień', 'C'),
                                      const SizedBox(width: 8),
                                      _buildStyleRadio('Poza trase', 'OFF'),
                                      const SizedBox(width: 8),
                                      _buildStyleRadio('Pomiędzy', 'P'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.inputBackground,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text(
                                      '🔍 Znajdź',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _clearForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.inputBackground,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text(
                                      '🗑️ Wyczyść',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.inputBackground,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text(
                                      '📋 Przeglądaj',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.inputBackground,
                                      foregroundColor: AppTheme.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text(
                                      '🔄 Rezerwacje',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          activeColor: AppTheme.textPrimary,
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

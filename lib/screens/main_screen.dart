import 'package:flutter/material.dart';
import '../models/ski_match.dart';
import '../services/ski_matching_service.dart';
import '../utils/theme.dart';
import '../widgets/client_form.dart';
import '../widgets/results_display.dart';

/// Główny ekran aplikacji
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final SkiMatchingService _matchingService = SkiMatchingService();
  Map<String, List<SkiMatch>> _results = {};
  bool _isLoading = false;

  /// Wyszukuje narty na podstawie danych klienta
  Future<void> _findSkis(Client client) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _matchingService.findMatchingSkis(client);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas wyszukiwania nart: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Czyści formularz i wyniki
  void _clearForm() {
    setState(() {
      _results = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text(
          '🎿 Asystent Doboru Nart v7.0 - Flutter',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Formularz danych klienta
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Dane Klienta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClientForm(onFindSkis: _findSkis, onClearForm: _clearForm),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Wyniki
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_results.isNotEmpty)
              ResultsDisplay(results: _results)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wprowadź dane klienta i kliknij "Znajdź"',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

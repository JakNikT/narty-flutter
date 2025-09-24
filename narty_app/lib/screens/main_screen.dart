import 'package:flutter/material.dart';
import '../models/ski_match.dart';
import '../services/ski_matching_service.dart';
import '../utils/theme.dart';
import '../widgets/client_form_new.dart';
import '../widgets/results_display.dart';
import '../widgets/logo_widget.dart';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Header Section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                color: AppTheme.headerBackground,
                child: Stack(
                  children: [
                    // Logo Circle
                    const Positioned(left: 10, top: 10, child: LogoWidget()),
                    // Form Section
                    Positioned(
                      left: 201,
                      top: 10,
                      right: 10,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.formBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClientFormNew(
                          onFindSkis: _findSkis,
                          onClearForm: _clearForm,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results Section
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppTheme.resultsBackground,
                child: Stack(
                  children: [
                    // Results inner container
                    Positioned(
                      left: 19,
                      top: 5,
                      right: 19,
                      bottom: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.formBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                top: 35,
                                left: 8,
                                right: 8,
                              ),
                              child: Text(
                                '🔍 Wyniki Doboru Nart',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.resultsInnerBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.accent,
                                        ),
                                      )
                                    : _results.isNotEmpty
                                    ? ResultsDisplay(results: _results)
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: 64,
                                              color: AppTheme.textDark,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Wprowadź dane klienta i kliknij "Znajdź"',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: AppTheme.textDark,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

import 'package:flutter/material.dart';
import '../models/ski_match.dart';
import '../services/ski_matching_service.dart';
import '../utils/theme.dart';
import '../widgets/pixel_perfect_painter.dart';

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
      body: SizedBox(
        width: 1100,
        height: 650,
        child: const PixelPerfectTestWidget(),
      ),
    );
  }
}

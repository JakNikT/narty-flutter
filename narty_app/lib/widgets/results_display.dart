import 'package:flutter/material.dart';
import '../models/ski_match.dart';
import '../models/ski.dart';
import '../utils/theme.dart';

/// Widget do wyświetlania wyników dobierania nart
class ResultsDisplay extends StatelessWidget {
  final Map<String, List<SkiMatch>> results;

  const ResultsDisplay({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final idealne = results['idealne'] ?? [];
    final poziomZaNisko = results['poziom_za_nisko'] ?? [];
    final alternatywy = results['alternatywy'] ?? [];
    final innaPlec = results['inna_plec'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Wyniki Doboru Nart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (idealne.isEmpty &&
                poziomZaNisko.isEmpty &&
                alternatywy.isEmpty &&
                innaPlec.isEmpty)
              _buildNoResults()
            else
              Column(
                children: [
                  if (idealne.isNotEmpty)
                    _buildSection('✅ IDEALNE DOPASOWANIA:', idealne),
                  if (poziomZaNisko.isNotEmpty)
                    _buildSection('🟡 POZIOM ZA NISKO:', poziomZaNisko),
                  if (alternatywy.isNotEmpty)
                    _buildSection('⚠️ ALTERNATYWY:', alternatywy),
                  if (innaPlec.isNotEmpty)
                    _buildSection('👥 INNA PŁEĆ:', innaPlec),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Wyświetla komunikat o braku wyników
  Widget _buildNoResults() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              '❌ BRAK DOPASOWANYCH NART',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Nie znaleziono nart spełniających kryteria wyszukiwania.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Tworzy sekcję wyników
  Widget _buildSection(String title, List<SkiMatch> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: AppTheme.tertiary),
        const SizedBox(height: 8),
        ...matches.map((match) => _buildSkiCard(match)),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Tworzy kartę pojedynczej narty
  Widget _buildSkiCard(SkiMatch match) {
    final ski = match.ski;
    final wspolczynnik = match.wspolczynnikIdealnosci;

    // Emoji dla współczynnika idealności
    String wspolczynnikEmoji;
    if (wspolczynnik >= 90) {
      wspolczynnikEmoji = "🎯";
    } else if (wspolczynnik >= 80) {
      wspolczynnikEmoji = "✅";
    } else if (wspolczynnik >= 70) {
      wspolczynnikEmoji = "👍";
    } else if (wspolczynnik >= 60) {
      wspolczynnikEmoji = "⚡";
    } else {
      wspolczynnikEmoji = "📊";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nazwa narty i długość z współczynnikiem
            Row(
              children: [
                const Text('► '),
                Expanded(
                  child: Text(
                    '${ski.marka} ${ski.model} (${ski.dlugosc} cm) $wspolczynnikEmoji ${wspolczynnik.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dostępność (symulacja)
            _buildAvailability(ski),

            const SizedBox(height: 8),

            // Dopasowanie
            _buildMatchDetails(match),

            const SizedBox(height: 8),

            // Informacje dodatkowe
            _buildAdditionalInfo(ski),
          ],
        ),
      ),
    );
  }

  /// Wyświetla dostępność nart
  Widget _buildAvailability(Ski ski) {
    return Row(
      children: [
        const Text('📦 Dostępność: '),
        ...List.generate(ski.ilosc, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Wyświetla szczegóły dopasowania
  Widget _buildMatchDetails(SkiMatch match) {
    final dopasowanie = match.dopasowanie;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Dopasowanie:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildMatchCriterion('P', dopasowanie['poziom']),
            _buildMatchCriterion('Pł', dopasowanie['plec']),
            _buildMatchCriterion('W', dopasowanie['waga']),
            _buildMatchCriterion('Wz', dopasowanie['wzrost']),
            _buildMatchCriterion('Pr', dopasowanie['przeznaczenie']),
          ],
        ),
      ],
    );
  }

  /// Tworzy widget dla pojedynczego kryterium dopasowania
  Widget _buildMatchCriterion(String label, MatchCriteria? criteria) {
    if (criteria == null) return const SizedBox.shrink();

    Color color;
    if (criteria.status == 'green') {
      color = Colors.green;
    } else if (criteria.status == 'orange') {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label: ${criteria.opis}',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Wyświetla dodatkowe informacje o narcie
  Widget _buildAdditionalInfo(Ski ski) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ski.promien != null) Text('ℹ️ Promień: ${ski.promien}'),
        if (ski.podButem != null) Text('ℹ️ Pod butem: ${ski.podButem}mm'),
        if (ski.uwagi.isNotEmpty) Text('📝 Uwagi: ${ski.uwagi}'),
      ],
    );
  }
}

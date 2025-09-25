import 'package:flutter/material.dart';
import '../models/ski_match.dart';
import '../models/ski.dart';
import '../utils/theme.dart';
import '../services/data_service.dart';

/// Widget do wyświetlania wyników dobierania nart
class ResultsDisplay extends StatefulWidget {
  final Map<String, List<SkiMatch>> results;

  const ResultsDisplay({super.key, required this.results});

  @override
  State<ResultsDisplay> createState() => _ResultsDisplayState();
}

class _ResultsDisplayState extends State<ResultsDisplay> {
  final DataService _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    final idealne = widget.results['idealne'] ?? [];
    final poziomZaNisko = widget.results['poziom_za_nisko'] ?? [];
    final alternatywy = widget.results['alternatywy'] ?? [];
    final innaPlec = widget.results['inna_plec'] ?? [];

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
        const Divider(color: AppTheme.accentLight),
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

            // Dostępność z informacjami o rezerwacjach
            _buildAvailabilityWithReservations(ski),

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

  /// Wyświetla dostępność nart z informacjami o rezerwacjach
  Widget _buildAvailabilityWithReservations(Ski ski) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dataService.getReservationInfo(
        ski.marka,
        ski.model,
        ski.dlugosc,
        DateTime.now(),
        DateTime.now().add(const Duration(days: 7)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            children: [
              Text('📦 Dostępność: '),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          );
        }

        final reservationInfo = snapshot.data;
        final isReserved = reservationInfo?['isReserved'] ?? false;
        final period = reservationInfo?['period'] ?? '';
        final number = reservationInfo?['number'] ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📦 Dostępność: '),
                ...List.generate(ski.ilosc, (index) {
                  // Sprawdź czy ta konkretna sztuka jest zarezerwowana
                  final isThisSkiReserved =
                      isReserved &&
                      (number.isEmpty ||
                          number.contains(
                            '//${(index + 1).toString().padLeft(2, '0')}',
                          ) ||
                          number.contains('//${index + 1}'));

                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isThisSkiReserved ? Colors.red : Colors.green,
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
            ),
            if (isReserved && period.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '🚫 Zarezerwowana: $period${number.isNotEmpty ? ' (Nr: $number)' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
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
        color: color.withValues(alpha: 0.2),
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

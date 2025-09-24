/// Klasa do parsowania poziomów umiejętności narciarskich
class LevelParser {
  /// Parsuje poziom narty w zależności od formatu
  /// Zwraca (poziom_min, poziom_display) lub (null, null) w przypadku błędu
  static Map<String, dynamic> parseLevel(String poziomText, String plec) {
    try {
      // Format unisex: "5M/6D"
      if (poziomText.contains('/')) {
        final parts = poziomText.split('/');
        if (parts.length >= 2) {
          final pmPart = parts[0].replaceAll('M', '').trim();
          final pdPart = parts[1].replaceAll('D', '').trim();
          
          final poziomM = int.parse(pmPart);
          final poziomD = int.parse(pdPart);
          
          if (plec == "Mężczyzna") {
            return {
              'poziom_min': poziomM,
              'poziom_display': "PM$poziomM/PD$poziomD"
            };
          } else if (plec == "Kobieta") {
            return {
              'poziom_min': poziomD,
              'poziom_display': "PM$poziomM/PD$poziomD"
            };
          } else { // Wszyscy
            return {
              'poziom_min': poziomM < poziomD ? poziomM : poziomD,
              'poziom_display': "PM$poziomM/PD$poziomD"
            };
          }
        }
      }
      
      // Format unisex ze spacją: "5M 6D"
      if (poziomText.contains('M') && poziomText.contains('D')) {
        final parts = poziomText.split(' ');
        String? pmPart;
        String? pdPart;
        
        for (final part in parts) {
          if (part.contains('M')) {
            pmPart = part.replaceAll('M', '').trim();
          } else if (part.contains('D')) {
            pdPart = part.replaceAll('D', '').trim();
          }
        }
        
        if (pmPart != null && pdPart != null) {
          final poziomM = int.parse(pmPart);
          final poziomD = int.parse(pdPart);
          
          if (plec == "Mężczyzna") {
            return {
              'poziom_min': poziomM,
              'poziom_display': "PM$poziomM PD$poziomD"
            };
          } else if (plec == "Kobieta") {
            return {
              'poziom_min': poziomD,
              'poziom_display': "PM$poziomM PD$poziomD"
            };
          } else { // Wszyscy
            return {
              'poziom_min': poziomM < poziomD ? poziomM : poziomD,
              'poziom_display': "PM$poziomM PD$poziomD"
            };
          }
        }
      }
      
      // Format męski: "5M"
      if (poziomText.contains('M')) {
        final poziomMin = int.parse(poziomText.replaceAll('M', '').trim());
        return {
          'poziom_min': poziomMin,
          'poziom_display': "PM${poziomText.replaceAll('M', '').trim()}"
        };
      }
      
      // Format damski: "5D"
      if (poziomText.contains('D')) {
        final poziomMin = int.parse(poziomText.replaceAll('D', '').trim());
        return {
          'poziom_min': poziomMin,
          'poziom_display': "PD${poziomText.replaceAll('D', '').trim()}"
        };
      }
      
      // Format prosty: tylko cyfra
      if (RegExp(r'^\d+$').hasMatch(poziomText.trim())) {
        final poziomMin = int.parse(poziomText.trim());
        return {
          'poziom_min': poziomMin,
          'poziom_display': "P${poziomText.trim()}"
        };
      }
      
      return {'poziom_min': null, 'poziom_display': null};
      
    } catch (e) {
      return {'poziom_min': null, 'poziom_display': null};
    }
  }
}

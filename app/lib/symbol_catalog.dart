/// Katalog standardních praček symbolů
/// Pro offline porovnání s AI detekcí
class LaundrySymbolCatalog {
  static final Map<String, Map<String, String>> _catalog = {
    'prádlo': {
      'čeština': 'Mytí prádla',
      'anglicky': 'Machine Wash',
      'kategorie': 'Praní',
      'teplota': 'Vlažná voda (30°C)',
      'popis': 'Oblečení je vhodné na praní v pračce. Obvukle nejnižší teplota.',
      'emoji': '🧺',
      'asset': 'assets/symbols/machine-wash-normal.png',
    },
    'prádlo_40': {
      'čeština': 'Mytí prádla (40°C)',
      'anglicky': 'Machine Wash 40°C',
      'kategorie': 'Praní',
      'teplota': 'Teplá voda (40°C)',
      'popis': 'Praní v teplé vodě do 40°C. Vhodné pro normálně znečištěné oblečení.',
      'emoji': '🧺',
      'asset': 'assets/symbols/machine-wash-warm.png',
    },
    'prádlo_60': {
      'čeština': 'Mytí prádla (60°C)',
      'anglicky': 'Machine Wash 60°C',
      'kategorie': 'Praní',
      'teplota': 'Horká voda (60°C)',
      'popis': 'Praní v teplé vodě do 60°C. Vhodné pro silně znečištěné oblečení.',
      'emoji': '🧺',
      'asset': 'assets/symbols/machine-wash-hot.png',
    },
    'rucni_prani': {
      'čeština': 'Ruční praní',
      'anglicky': 'Hand Wash',
      'kategorie': 'Praní',
      'teplota': 'Vlažná voda (30-40°C)',
      'popis': 'Oblečení je třeba prát rukou. V pračce se může poškodit.',
      'emoji': '✋',
      'asset': 'assets/symbols/hand-wash.png',
    },
    'bez_bleleni': {
      'čeština': 'Bez bělení',
      'anglicky': 'No Bleach',
      'kategorie': 'Bělení',
      'popis': 'Nepoužívat bělidlo, ani na bázi chloru. Může se oblečení zbarevit.',
      'emoji': '🚫',
      'asset': 'assets/symbols/do-not-bleach.png',
    },
    'bleleni_vyznam': {
      'čeština': 'Bělení povoleno',
      'anglicky': 'Bleach Allowed',
      'kategorie': 'Bělení',
      'popis': 'Bělidlo je povoleno. Lze použít bělidlo na bázi chlóru.',
      'emoji': '✅',
      'asset': 'assets/symbols/bleach.png',
    },
    'suseni_na_vzduchu': {
      'čeština': 'Sušení na vzduchu',
      'anglicky': 'Air Dry',
      'kategorie': 'Sušení',
      'popis': 'Oblečení je třeba sušit přirozeně. Nelze do sušičky.',
      'emoji': '💨',
      'asset': 'assets/symbols/hang-dry.png',
    },
    'sitko': {
      'čeština': 'Sušení v sušičce',
      'anglicky': 'Tumble Dry',
      'kategorie': 'Sušení',
      'popis': 'Sušení v sušičce je bezpečné. Vhodné pro normální sušení.',
      'emoji': '🌀',
      'asset': 'assets/symbols/tumble-dry-normal.png',
    },
    'sitko_nizka_teplota': {
      'čeština': 'Sušení v sušičce - nižší teplota',
      'anglicky': 'Tumble Dry Low',
      'kategorie': 'Sušení',
      'popis': 'Sušení v sušičce na nižší teplotu. Vhodné pro citlivé látky.',
      'emoji': '🌬️',
      'asset': 'assets/symbols/tumble-dry-low.png',
    },
    'zihleni': {
      'čeština': 'Žehlení',
      'anglicky': 'Iron',
      'kategorie': 'Žehlení',
      'teplota': 'Do 110°C',
      'popis': 'Oblečení lze žehlit. Maximum teplota se uvádí body.',
      'emoji': '🔥',
      'asset': 'assets/symbols/iron-high.png',
    },
    'bez_zihleni': {
      'čeština': 'Bez žehlení',
      'anglicky': 'Do Not Iron',
      'kategorie': 'Žehlení',
      'popis': 'Oblečení nelze žehlit. Může se poškodit nebo roztavit.',
      'emoji': '🚫',
      'asset': 'assets/symbols/do-not-iron.png',
    },
    'chemicke_cisteni': {
      'čeština': 'Chemické čištění',
      'anglicky': 'Dry Clean',
      'kategorie': 'Chemické čištění',
      'popis': 'Doporučuje se chemické čištění. Nehází se do domácí pračky.',
      'emoji': '🧼',
      'asset': 'assets/symbols/dry-clean.png',
    },
    'bez_zkrucovani': {
      'čeština': 'Bez zkrucování',
      'anglicky': 'No Spin',
      'kategorie': 'Praní',
      'popis': 'Nekrucovat. Po praní opatrně vymačkat bez kroucení.',
      'emoji': '🚫',
      'asset': 'assets/symbols/do-not-wring.png',
    },
  };

  /// Vrátí všechny symboly z katalogu
  static List<Map<String, String>> getAllSymbols() {
    return _catalog.values.toList();
  }

  /// Hledá symbol podle českého jména (case-insensitive)
  static Map<String, String>? findSymbolByName(String name) {
    final normalized = name.toLowerCase().trim();
    for (final entry in _catalog.entries) {
      if (entry.value['čeština']?.toLowerCase().contains(normalized) ?? false) {
        return entry.value;
      }
    }
    return null;
  }

  /// Hledá symboly podle kategorie
  static List<Map<String, String>> findSymbolsByCategory(String category) {
    return _catalog.values
        .where((s) => s['kategorie']?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Vrátí seznam všech kategorií
  static List<String> getCategories() {
    final categories = <String>{};
    for (final symbol in _catalog.values) {
      final cat = symbol['kategorie'];
      if (cat != null) categories.add(cat);
    }
    return categories.toList();
  }

  /// Hledá nejpodobnější symbol podle klíčových slov
  static Map<String, String>? findMostSimilarSymbol(String query) {
    if (query.isEmpty) return null;

    final normalized = query.toLowerCase().trim();
    int bestScore = 0;
    Map<String, String>? bestMatch;

    for (final entry in _catalog.entries) {
      int score = 0;

      // Skóre za obsahy v českém jméně
      if (entry.value['čeština']?.toLowerCase().contains(normalized) ?? false) {
        score += 100;
      }

      // Skóre za obsahy v anglickém jméně
      if (entry.value['anglicky']?.toLowerCase().contains(normalized) ?? false) {
        score += 50;
      }

      // Skóre za obsahy v popisu
      if (entry.value['popis']?.toLowerCase().contains(normalized) ?? false) {
        score += 25;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.value;
      }
    }

    return bestMatch;
  }

  /// Vrátí HTML reprezentaci symbolu pro UI
  static String getSymbolHtml(Map<String, String> symbol) {
    return '''
      <b>${symbol['čeština']}</b> (${symbol['anglicky']})
      <br>
      <small>${symbol['popis']}</small>
    ''';
  }
}

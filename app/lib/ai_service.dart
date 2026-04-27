import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'image_processing_helper.dart';

class AiService {
  // DŮLEŽITÉ: API klíč se musí předávat externě, aby nebyl commitnutý do repozitáře.
  // Například při vývoji použij: flutter run --dart-define=API_KEY=tvuj_novy_klic
  static final String _apiKey = const String.fromEnvironment('API_KEY', defaultValue: '');
  static const String _model = 'gemini-2.5-flash'; // Gemini 2.5 Flash je dostupný ve free tieru

  /// Analyzuje fotografii pracího symbolu pomocí Gemini AI
  /// 
  /// Vrací strukturovanou odpověď s názvem symbolu a instrukcemi
  static Future<String> analyzeImage(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      return '❌ Chyba: API klíč není nastaven.\n\n'
          'Spusť aplikaci s novým klíčem přes dart-define:\n'
          'flutter run --dart-define=API_KEY=tvuj_novy_klic\n'
          'Nebo ho nastav v build procesu jako Dart define.';
    }

    try {
      final preprocessedBytes = await _preprocessImageBytes(imageBytes);

      final model = GenerativeModel(
        model: _model,
        apiKey: _apiKey,
      );

      // Vylepšený prompt s strukturovaným výstupem
      final prompt = TextPart('''
Jsi expert na péči o oblečení a mezinárodní symboly pro praní.

ÚKOL:
Analyzuj přiloženou fotografii a identifikuj pracovní symbol (laundry care symbol).

ODPOVĚZ V TOMTO FORMÁTU:

🏷️ NÁZEV SYMBOLU:
[Přesný název symbolu česky a anglicky v závorce]

📋 KATEGORIE:
[Praní / Bělení / Sušení / Žehlení / Chemické čištění]

📖 INSTRUKCE:
[Stručné a jasné instrukce, jak správně pečovat o oblečení s tímto symbolem. Max 3 věty.]

💡 TIPY:
[Praktické rady pro každodenní použití. Max 2 věty.]

⚠️ VAROVÁNÍ:
[Co určitě nedělat, aby se oblečení nepoškodilo. Max 1 věta, pokud relevantní.]

DŮLEŽITÉ:
- Buď přesný a konkrétní
- Používej českou terminologii
- Pokud si nejsi jistý, uveď možné varianty
- Pokud symbol nerozpoznáš, přiznej to a poraď uživateli, jak udělat lepší foto

''');

      // Přečteme fotku a připravíme ji pro odeslání
      final imagePart = DataPart('image/jpeg', preprocessedBytes);

      // Zavoláme Gemini API
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text;

      if (text == null || text.isEmpty) {
        return '⚠️ AI nevrátila žádnou odpověď.\n\n'
            'Zkus to prosím znovu nebo udělej foto s lepším osvětlením.';
      }

      return text;
    } on GenerativeAIException catch (e) {
      // Specifické chyby Gemini API
      if (e.message.contains('API_KEY_INVALID')) {
        return '❌ Neplatný API klíč.\n\n'
            'Zkontroluj, že máš správný klíč z Google AI Studio.';
      } else if (e.message.contains('RATE_LIMIT') || e.message.contains('503')) {
        return '⏳ Gemini server je momentálně přetížený.\n\n'
            'Google AI má vysokou poptávku. Počkej prosím 30-60 sekund a zkus to znovu.\n\n'
            'Tip: Zkus to později nebo v méně vytížené hodině.';
      } else if (e.message.contains('SAFETY')) {
        return '🚫 Obsah fotky byl označen jako problematický.\n\n'
            'Zkus vyfotit pouze pracovní symbol bez okolního obsahu.';
      } else if (e.message.contains('high demand') || e.message.contains('UNAVAILABLE')) {
        return '⏳ Služba je momentálně nedostupná.\n\n'
            'Gemini API zažívá vrcholní zatížení. Zkus to za chvíli znovu.';
      }

      return '❌ Chyba Gemini API: ${e.message}\n\n'
          'Zkus to prosím znovu za chvíli.';
    } on FormatException catch (e) {
      // Problém s formátem obrázku
      return '🖼️ Problém s formátem fotky.\n\n'
          'Zkus udělat novou fotku.\n'
          'Detail: ${e.message}';
    } catch (e) {
      // Obecná chyba
      return '❌ Neočekávaná chyba: $e\n\n'
          'Zkontroluj připojení k internetu a zkus to znovu.';
    }
  }

  /// Testovací funkce - zkontroluje, jestli je API klíč validní
  static Future<bool> testApiKey() async {
    if (_apiKey == 'TVŮJ_API_KLÍČ_SEM' || _apiKey.isEmpty) {
      return false;
    }

    try {
      final model = GenerativeModel(
        model: _model,
        apiKey: _apiKey,
      );

      final response = await model.generateContent([
        Content.text('Test')
      ]);

      return response.text != null;
    } catch (e) {
      return false;
    }
  }

  /// Alternativní metoda - analýza textu (pokud by uživatel napsal, co vidí)
  static Future<String> analyzeTextDescription(String description) async {
    if (_apiKey == 'TVŮJ_API_KLÍČ_SEM' || _apiKey.isEmpty) {
      return '❌ API klíč není nastaven.';
    }

    try {
      final model = GenerativeModel(
        model: _model,
        apiKey: _apiKey,
      );

      final prompt = '''
Jsi expert na mezinárodní symboly pro praní oblečení.

Uživatel popsal symbol takto: "$description"

Na základě popisu identifikuj symbol a poraď, jak o oblečení pečovat.

Odpověz ve strukturovaném formátu:
- Název symbolu
- Kategorie (Praní/Bělení/Sušení/Žehlení/Chemické čištění)
- Instrukce pro péči
- Praktické tipy
''';

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      return response.text ?? 'Nepodařilo se získat odpověď.';
    } catch (e) {
      return 'Chyba: $e';
    }
  }

  /// Pokud je potřeba, obrázek před odesláním zpracujeme tak, aby byl kontrastní a čistý.
  static Future<Uint8List> _preprocessImageBytes(Uint8List imageBytes) async {
    try {
      final result = await ImageProcessingHelper.processBytes(imageBytes);
      return result.compressedBytes;
    } catch (_) {
      return imageBytes;
    }
  }

  /// Hromadná analýza - pokud má uživatel více symbolů na jedné fotce
  static Future<String> analyzeMultipleSymbols(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      return '❌ API klíč není nastaven. Spusť aplikaci s --dart-define=API_KEY=tvuj_novy_klic.';
    }

    try {
      final preprocessedBytes = await _preprocessImageBytes(imageBytes);

      final model = GenerativeModel(
        model: _model,
        apiKey: _apiKey,
      );

      final prompt = TextPart('''
Analyzuj přiloženou fotografii a identifikuj VŠECHNY pracovní symboly, které vidíš.

Pro každý symbol napiš:
1. Název symbolu
2. Co znamená
3. Jak postupovat

Pokud vidíš více symbolů, vypočítej je jako seznam.
Pokud vidíš jen jeden symbol, řekni to a analyzuj ho podrobně.
''');

      final imagePart = DataPart('image/jpeg', preprocessedBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? 'Nepodařilo se analyzovat fotku.';
    } catch (e) {
      return 'Chyba: $e';
    }
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'image_preprocessor.dart';

class AiService {
  // DŮLEŽITÉ: Vlož sem svůj API klíč z Google AI Studio
  // https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyAWC5XsCvgCzJAbIy00EwcpRID75aPNHoo';
  static const String _model = 'gemini-2.5-flash'; // Gemini 2.5 Flash je dostupný ve free tieru

  /// Analyzuje fotografii pracího symbolu pomocí Gemini AI
  /// 
  /// Vrací strukturovanou odpověď s názvem symbolu a instrukcemi
  static Future<String> analyzeImage(File imageFile) async {
    if (_apiKey == 'TVŮJ_API_KLÍČ_SEM' || _apiKey.isEmpty) {
      return '❌ Chyba: API klíč není nastaven.\n\n'
          'Otevři soubor ai_service.dart a vlož svůj API klíč z Google AI Studio.\n'
          'Získáš ho zde: https://aistudio.google.com/app/apikey';
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
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
      } else if (e.message.contains('RATE_LIMIT')) {
        return '⏳ Příliš mnoho požadavků.\n\n'
            'Počkej chvíli a zkus to znovu.';
      } else if (e.message.contains('SAFETY')) {
        return '🚫 Obsah fotky byl označen jako problematický.\n\n'
            'Zkus vyfotit pouze pracovní symbol bez okolního obsahu.';
      }

      return '❌ Chyba Gemini API: ${e.message}\n\n'
          'Zkus to prosím znovu za chvíli.';
    } on SocketException catch (e) {
      // Problémy s připojením
      return '📡 Chyba připojení k internetu.\n\n'
          'Zkontroluj své připojení a zkus to znovu.\n'
          'Detail: ${e.message}';
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
      final original = img.decodeImage(imageBytes);
      if (original == null) {
        return imageBytes;
      }

      final processed = ImagePreprocessor.preprocessForModel(original);
      final resized = img.copyResize(
        processed,
        width: 512,
        height: 512,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return imageBytes;
    }
  }

  /// Hromadná analýza - pokud má uživatel více symbolů na jedné fotce
  static Future<String> analyzeMultipleSymbols(File imageFile) async {
    if (_apiKey == 'TVŮJ_API_KLÍČ_SEM' || _apiKey.isEmpty) {
      return '❌ API klíč není nastaven.';
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
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
# Laundry Decoder

Flutter aplikace pro rozpoznání praních symbolů s pomocí AI.

## O Projektu

Aplikace řeší problém neznalosti praních symbolů na etiketách oblečení. Workflow:

1. Nahrání symbolu z fotoaparátu nebo galerie
2. Lokální předzpracování obrázku (kontrast, redukce šumu)
3. Analýza pomocí Google Gemini AI
4. Zobrazení instrukcí v češtině

## Funkce

- AI rozpoznání (Gemini 2.5 Flash, 85-90% přesnost)
- Předzpracování obrázků (thresholding, kontrast)
- Asynchronní zpracování (bez zamrznutí UI)
- Offline katalog (36 symbolů bez připojení)
- Caching výsledků (úspora API volání)
- Porovnání s katalogem (vizuální ověření)
- Material Design 3
- iOS, Android, Web 

---

## Technologický Stack

- Framework: Flutter 3.41.3
- Jazyk: Dart (null-safe)
- AI Model: Google Generative AI (Gemini 2.5 Flash)
- Zpracování obrázků: dart package:image (thresholding, morfologie)
- Úložiště: SharedPreferences (MD5 hash-based cache)
- Platformy: Android 7.0+, iOS 11.0+, Web

---

## Instalace

### Požadavky

- Flutter 3.30+
- Dart 3.0+
- Google Generative AI API klíč

### Kroky

```bash
git clone https://github.com/Jachymac/Laundry-Decoder.git
cd Laundry-Decoder/app
flutter pub get
```

### Konfigurace API klíče

1. Přejděte na https://ai.google.dev/app/apikey
2. Vytvořte API klíč (zdarma)
3. Spusťte aplikaci s definicí klíče:

```bash
flutter run --dart-define=API_KEY=vash_klic
```

Pro konkrétní platformu:

```bash
flutter run -d android --dart-define=API_KEY=vash_klic
flutter run -d ios --dart-define=API_KEY=vash_klic
flutter run -d chrome --dart-define=API_KEY=vash_klic
```

---

## Použití

1. **Výběr symbolu**: Vyberte fotoaparát (live fotografie) nebo galerie (existující fotografie)
2. **Ořez**: Použijte nástroj pro ořez obrázku do čtvercového formátu
3. **Náhled**: Přepínač mezi originální a předzpracovanou fotografií
4. **Analýza**: Spusťte skenování a sledujte průběh (Dekódování → Zpracování → AI)
5. **Výsledky**: Zobrazení názvu, instrukcí, tipů, varování a porovnání s katalogem

### Offline režim

- Druhá záložka "Katalog" obsahuje 36 symbolů bez připojení k internetu
- Podpora hledání a filtrování podle kategorie

---

## Architektura

```
Obrázek → Předzpracování → Caching → API/Fallback → Porovnání s katalogem → Zobrazení
```

### Předzpracování

- Převod do stupňů šedi
- Adaptivní thresholding
- Morfologické operace
- Úprava velikosti a osazení

### API limity

- Limit: 353 RPM, 250K TPM (free tier)
- Fallback: Offline katalog s fuzzy matching

---

## Řešení problémů

| Problém | Řešení |
|---------|--------|
| Chyba API klíče | Ověřte klíč na https://ai.google.dev/app/apikey |
| Chyba buildu | Spusťte `flutter clean && flutter pub get && flutter run` |
| Symbol není rozpoznán | Lepší fotografie, lepší osvětlení, nebo vyberte ze katalogu |

---

## Licence

MIT


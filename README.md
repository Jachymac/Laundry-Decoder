# Laundry Decoder

Flutter aplikace pro rozpoznání praních symbolů s pomocí AI.

## O Projektu

Aplikace řeší problém: lidé neznají praní symboly na etiketách. Workflow:

1. Vyfotíš symbol nebo vybereš z galerie
2. Aplikace ho preprocessuje (kontrast, šum)
3. Google Gemini AI rozpozná symbol
4. Dostaneš instrukce v češtině

## Features

- AI Rozpoznání (Gemini 2.5 Flash, 85-90% přesnost)
- Image Preprocessing (thresholding, kontrast)
- Asynchronní Processing (bez zamrznutí UI)
- Offline Katalog (36 symbolů bez Internetu)
- Caching (ušetření API calls)
- Porovnání s Katalogem (vizuální ověření)
- Material Design 3
- iOS, Android, Web

---

## Technologický Stack

- Framework: Flutter 3.41.3
- Jazyk: Dart (null-safe)
- AI Model: Google Generative AI (Gemini 2.5 Flash)
- Image Processing: dart package:image (thresholding, morphology)
- Storage: SharedPreferences (MD5 hash-based cache)
- Platform: Android 7.0+, iOS 11.0+, Web

---

## Instalace

Požadavky: Flutter 3.30+, Dart 3.0+, Google Generative AI API Key

```bash
git clone https://github.com/Jachymac/Laundry-Decoder.git
cd Laundry-Decoder/app
flutter pub get
```

Nastav API Key:
1. Jdi na https://ai.google.dev/app/apikey
2. Vytvoř API Key (zdarma)
3. V lib/main.dart vlož: `const String apiKey = 'YOUR_API_KEY_HERE';`

Spuštění:
```bash
flutter run -d android  # nebo ios, web
```

---

## Jak Používat

1. Vyjímej symbol: Klikni Fotoaparát (live fotka) nebo Galerie (existující foto)
2. Ořez: Aplikace ti umožňuje ořezat na čtverec
3. Preview: Přepínač mezi Originál-Preprocessováno
4. Analýza: Klikni Skenuj - vidíš progress (Dekódování → Zpracování → AI)
5. Výsledky: Název, instrukce, tipy, varování, porovnání s katalogem

Offline Režim:
- Druhá záložka Katalog obsahuje 13 symbolů bez Internetu
- Hledání a filtrování podle kategorie

---

## Workflow

Obrázek -> Preprocessing -> Caching -> API/Fallback -> Catalog Matching -> Display

Preprocessing: Grayscale, kontrast, thresholding, morfologické operace
API Limity: 353 RPM, 250K TPM (free tier)
Fallback: Offline katalog, fuzzy matching

---

## Troubleshooting

- API key error: Zkontroluj https://ai.google.dev/app/apikey
- Build error: `flutter clean && flutter pub get && flutter run`
- Symbol not recognized: Lépe vyfotit, lepší osvětlení, nebo vybrat z katalogu

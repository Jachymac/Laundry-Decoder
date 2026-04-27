# Laundry Decoder

Laundry Decoder je Flutter aplikace pro skenování symbolů péče o oblečení a jejich analýzu pomocí Google Gemini AI.

Repozitář: https://github.com/Jachymac/Laundry-Decoder

## Co tento projekt dělá

- umožňuje nahrát fotku symbolu z fotoaparátu nebo galerií
- provede lokální předzpracování obrázku (grayscale, threshold, morph, resize)
- zobrazí procesovaný náhled fotky
- odešle obrázek do Gemini AI modelu přes `google_generative_ai`
- zobrazí strukturovaný výsledek popisu symbolu, kategorie, instrukcí, tipů a varování
- udržuje jednoduchý lokální cache výkonu pomocí `shared_preferences`
- podporuje mobilní i webovou verzi (s podmínkami pro web)

## Hlavní soubory

### `lib/main.dart`
- obsahuje hlavní UI aplikace
- řídí výběr a zpracování obrázků
- zobrazuje průběh zpracování i výsledky AI analýzy
- má přepínač pro zobrazení originální nebo procesované fotky
- provádí jednoduchou detekci online/offline stavu

### `lib/ai_service.dart`
- komunikuje s Google Gemini API
- načítá API klíč externě přes `--dart-define` (není uložen v kódu)
- vytváří prompt pro analýzu symbolu
- ošetřuje běžné chyby Gemini API (invalid key, rate limit, nedostupnost, safety)

### `lib/image_processing_helper.dart`
- provádí zpracování obrázků v izolátu, pokud platforma podporuje `Isolate`
- zpracovává `XFile` i `Uint8List`
- vytváří předzpracovaný i komprimovaný výstup

### `lib/image_preprocessor.dart`
- obsahuje algoritmus pro zpracování obrazu symbolu
- dělá grayscale, adaptivní threshold, morfologické úpravy a crop/padding
- používá vlastní práci s byte buffery pro výkon

### `lib/dictionary_screen.dart`
- zobrazuje katalog symbolů, který slouží jako offline reference
- obsahuje přehled kategorií symbolů a jejich popisy

### `lib/online_status.dart`, `lib/online_status_stub.dart`, `lib/online_status_web.dart`
- řeší detekci online stavu pro různé platformy
- web používá `window.navigator.onLine`
- mobil používá standardní síťové ověření

## Závislosti

Hlavní balíčky projektu jsou:

- `flutter`
- `image_picker` – pro výběr obrázků z galerie a fotoaparátu
- `image_cropper` – pro ořezávání obrázků na mobilu
- `image` – pro manipulaci a kompresi obrázků
- `google_generative_ai` – pro volání Gemini AI
- `shared_preferences` – pro lokální cache a statistiky
- `crypto` – pro MD5 hash obrázků do cache
- `http` – pro webovou kompatibilitu a síťové ověření

## Jak spustit

1. Přes `flutter pub get` stáhni závislosti:

```bash
flutter pub get
```

2. Nastav API klíč pro Gemini AI externě:

```bash
flutter run -d chrome --dart-define=API_KEY=tvuj_novy_klic
```

Pro Android / iOS pak obdobně:

```bash
flutter run --dart-define=API_KEY=tvuj_novy_klic
```

> Poznámka: API klíč by neměl být commitnut do repozitáře.

## Webová podpora

- Web může fungovat, ale Gemini API může vracet 503, když je služba přetížená.
- Zobrazení online stavu na webu používá prohlížečovou detekci síťové dostupnosti.
- Pokud chcete nasadit web, doporučujeme použít vlastní backend/proxy pro skrytí klíče.

## Doporučené úpravy

- `ai_service.dart` je nastaven tak, aby klíč nebyl uložen v kódu.
- pokud nasazujete veřejně, klíč by měl být dostupný pouze přes backend nebo CI/CD proměnné.

## Struktura projektu

```
app/
  lib/
    main.dart
    ai_service.dart
    image_processing_helper.dart
    image_preprocessor.dart
    dictionary_screen.dart
    online_status.dart
    online_status_stub.dart
    online_status_web.dart
  pubspec.yaml
  README.md
```


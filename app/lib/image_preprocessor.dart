import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// Modul pro preprocessing obrázků pracích symbolů
/// 
/// Cíl: Zvýšit kontrast černého symbolu na bílém pozadí,
/// odstranit šum a normalizovat obrázek pro lepší detekci modelem.
class ImagePreprocessor {
  /// Hlavní funkce pro preprocessing obrázku symbolu
  /// 
  /// Provádí:
  /// 1. Převod na grayscale
  /// 2. Adaptivní prahování (thresholding)
  /// 3. Odstranění šumu
  /// 4. Automatické oříznutí na samotný symbol
  /// 5. Normalizace osvětlení
  static img.Image preprocessForModel(img.Image original) {
    // Krok 1: Převod na grayscale (odstranění barev)
    img.Image grayscale = img.grayscale(original);

    // Krok 2: Zvýšení kontrastu
    img.Image contrasted = _enhanceContrast(grayscale);

    // Krok 3: Adaptivní prahování - převod na černo-bílý obrázek
    img.Image thresholded = _adaptiveThreshold(contrasted);

    // Krok 4: Morfologické operace - odstranění šumu
    img.Image cleaned = _morphologicalCleaning(thresholded);

    // Krok 5: Automatické oříznutí na symbol (remove empty borders)
    img.Image cropped = _autoCrop(cleaned);

    // Krok 6: Padding - přidání malého okraje kolem symbolu
    img.Image padded = _addPadding(cropped, 20);

    // Krok 7: Finální normalizace - zajištění, že pozadí je bílé a symbol černý
    img.Image normalized = _normalizeColors(padded);

    return normalized;
  }

  /// Zvýšení kontrastu pomocí histogram equalization
  static img.Image _enhanceContrast(img.Image image) {
    // Histogram equalization pro lepší kontrast
    return img.adjustColor(
      image,
      contrast: 1.5, // Zvýšení kontrastu o 50%
      brightness: 1.1, // Mírné zesvětlení
    );
  }

  /// Adaptivní prahování - převod na černo-bílý s lokálním prahem
  static img.Image _adaptiveThreshold(img.Image image) {
    final width = image.width;
    final height = image.height;
    final result = img.Image(width: width, height: height);

    // Výpočet průměrné intenzity v okolí každého pixelu
    const windowSize = 15; // Velikost okolí
    const threshold = 10; // Tolerance

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Získání průměrné intenzity v okolí
        double sum = 0;
        int count = 0;

        for (int dy = -windowSize; dy <= windowSize; dy++) {
          for (int dx = -windowSize; dx <= windowSize; dx++) {
            final nx = x + dx;
            final ny = y + dy;

            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final pixel = image.getPixel(nx, ny);
              sum += pixel.r.toDouble(); // Grayscale, takže R=G=B
              count++;
            }
          }
        }

        final localMean = sum / count;
        final currentPixel = image.getPixel(x, y);
        final intensity = currentPixel.r.toDouble();

        // Pokud je pixel tmavší než lokální průměr - threshold, je to část symbolu
        if (intensity < localMean - threshold) {
          result.setPixelRgb(x, y, 0, 0, 0); // Černá (symbol)
        } else {
          result.setPixelRgb(x, y, 255, 255, 255); // Bílá (pozadí)
        }
      }
    }

    return result;
  }

  /// Morfologické operace - odstranění malého šumu a vyhlazení hran
  static img.Image _morphologicalCleaning(img.Image image) {
    // Erosion - odstranění malých bílých teček na symbolu
    img.Image eroded = _erode(image, 1);

    // Dilation - obnovení velikosti symbolu
    img.Image dilated = _dilate(eroded, 1);

    return dilated;
  }

  /// Erosion - zmenšení bílých oblastí (zvětšení černých)
  static img.Image _erode(img.Image image, int iterations) {
    img.Image result = image;

    for (int iter = 0; iter < iterations; iter++) {
      final temp = img.Image(width: result.width, height: result.height);

      for (int y = 1; y < result.height - 1; y++) {
        for (int x = 1; x < result.width - 1; x++) {
          // Kontrola 3x3 okolí
          bool allWhite = true;

          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              final pixel = result.getPixel(x + dx, y + dy);
              if (pixel.r < 128) {
                // Je tam černý pixel
                allWhite = false;
                break;
              }
            }
            if (!allWhite) break;
          }

          if (allWhite) {
            temp.setPixelRgb(x, y, 255, 255, 255);
          } else {
            temp.setPixelRgb(x, y, 0, 0, 0);
          }
        }
      }

      result = temp;
    }

    return result;
  }

  /// Dilation - zvětšení bílých oblastí
  static img.Image _dilate(img.Image image, int iterations) {
    img.Image result = image;

    for (int iter = 0; iter < iterations; iter++) {
      final temp = img.Image(width: result.width, height: result.height);

      for (int y = 1; y < result.height - 1; y++) {
        for (int x = 1; x < result.width - 1; x++) {
          // Kontrola 3x3 okolí
          bool anyWhite = false;

          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              final pixel = result.getPixel(x + dx, y + dy);
              if (pixel.r > 128) {
                // Je tam bílý pixel
                anyWhite = true;
                break;
              }
            }
            if (anyWhite) break;
          }

          if (anyWhite) {
            temp.setPixelRgb(x, y, 255, 255, 255);
          } else {
            temp.setPixelRgb(x, y, 0, 0, 0);
          }
        }
      }

      result = temp;
    }

    return result;
  }

  /// Automatické oříznutí - odstranění prázdných okrajů
  static img.Image _autoCrop(img.Image image) {
    int minX = image.width;
    int maxX = 0;
    int minY = image.height;
    int maxY = 0;

    // Najdeme hranice černých pixelů (symbolu)
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Pokud je pixel černý (část symbolu)
        if (pixel.r < 128) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }

    // Pokud jsme nenašli žádný černý pixel, vrátíme originál
    if (minX >= maxX || minY >= maxY) {
      return image;
    }

    // Oříznutí na nalezené hranice
    final width = maxX - minX + 1;
    final height = maxY - minY + 1;

    return img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: width,
      height: height,
    );
  }

  /// Přidání bílého okraje kolem symbolu
  static img.Image _addPadding(img.Image image, int padding) {
    final newWidth = image.width + 2 * padding;
    final newHeight = image.height + 2 * padding;

    final padded = img.Image(width: newWidth, height: newHeight);

    // Vyplníme bílou
    img.fill(padded, color: img.ColorRgb8(255, 255, 255));

    // Vložíme originální obrázek doprostřed
    img.compositeImage(
      padded,
      image,
      dstX: padding,
      dstY: padding,
    );

    return padded;
  }

  /// Normalizace barev - zajištění, že pozadí je skutečně bílé
  static img.Image _normalizeColors(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final intensity = pixel.r.toDouble();

        // Pokud je pixel tmavší než 128, je černý (symbol)
        // Jinak je bílý (pozadí)
        if (intensity < 128) {
          result.setPixelRgb(x, y, 0, 0, 0);
        } else {
          result.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }

    return result;
  }

  /// Alternativní metoda: Otsu's thresholding
  /// Pro případy, kdy adaptivní thresholding nefunguje dobře
  static img.Image otsuThreshold(img.Image image) {
    // Výpočet histogramu
    final histogram = List.filled(256, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        histogram[pixel.r.toInt()]++;
      }
    }

    final total = image.width * image.height;

    // Otsu's algoritmus pro nalezení optimálního prahu
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;

    double maxVariance = 0;
    int threshold = 0;

    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }

    // Aplikace prahu
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        if (pixel.r < threshold) {
          result.setPixelRgb(x, y, 0, 0, 0);
        } else {
          result.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }

    return result;
  }

  /// Debug funkce - uložení mezikroků pro vizuální kontrolu
  static Future<void> debugSaveSteps(img.Image original, String basePath) async {
    // Tuto funkci můžeš použít pro debugování
    // Uloží všechny mezikroky zpracování

    final grayscale = img.grayscale(original);
    final contrasted = _enhanceContrast(grayscale);
    final thresholded = _adaptiveThreshold(contrasted);
    final cleaned = _morphologicalCleaning(thresholded);
    final cropped = _autoCrop(cleaned);
    final padded = _addPadding(cropped, 20);
    final normalized = _normalizeColors(padded);

    // Zde bys mohl uložit každý krok jako soubor
    // await File('$basePath/1_grayscale.png').writeAsBytes(img.encodePng(grayscale));
    // atd...
  }
}
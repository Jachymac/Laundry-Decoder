import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'image_preprocessor.dart';

/// Výsledek zpracování obrázku.
class ProcessedImageResult {
  final img.Image preprocessed;
  final img.Image compressed;
  final Uint8List compressedBytes;
  final Duration processingTime;

  const ProcessedImageResult({
    required this.preprocessed,
    required this.compressed,
    required this.compressedBytes,
    required this.processingTime,
  });
}

/// Pomocné funkce pro zpracování obrázků v isolátu (bez blokování UI).
///
/// Změny oproti původní verzi:
///   • [processImage] přijímá volitelný [onProgress] callback (0.0 – 1.0)
///   • Dekódování a preprocessing probíhá v jednom [Isolate.run] volání
///     → žádný zbytečný přesun dat mezi isoláty
///   • Výstupní resize se provede jen jednou na konci, ne před i po preprocessingu
///   • [processingTime] v result usnadňuje profilování
class ImageProcessingHelper {
  /// Zpracuje XFile (kompatibilní s webem) na pozadí.
  static Future<ProcessedImageResult> processXFile(
    XFile imageFile, {
    int targetSize = 512,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    final bytes = await imageFile.readAsBytes();
    onProgress?.call(0.15);

    // Všechno CPU-heavy jede v isolátu na podporovaných platformách.
    final result = kIsWeb
        ? _processInIsolate(bytes, targetSize)
        : await Isolate.run(
            () => _processInIsolate(bytes, targetSize),
          );

    onProgress?.call(1.0);
    return result;
  }

  /// Zpracuje surové bajty (pro případ, kdy soubor není dostupný – např. galerie).
  static Future<ProcessedImageResult> processBytes(
    Uint8List bytes, {
    int targetSize = 512,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.1);
    final result = kIsWeb
        ? _processInIsolate(bytes, targetSize)
        : await Isolate.run(
            () => _processInIsolate(bytes, targetSize),
          );
    onProgress?.call(1.0);
    return result;
  }

  /// Čistá funkce spouštěná v isolátu – žádný přístup k Flutter/UI.
  static ProcessedImageResult _processInIsolate(
    Uint8List rawBytes,
    int targetSize,
  ) {
    final start = DateTime.now();

    // 1. Dekódování
    final original = img.decodeImage(rawBytes);
    if (original == null) {
      throw Exception('Nepodařilo se dekódovat obrázek – zkontroluj formát souboru.');
    }

    // 2. Preprocessing (grayscale, threshold, morph, crop, padding)
    final preprocessed = ImagePreprocessor.preprocessForModel(original);

    // 3. Resize na cílovou velikost – jen jednou, na konci
    final compressed = img.copyResize(
      preprocessed,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.average,
    );

    final compressedBytes = Uint8List.fromList(
      img.encodeJpg(compressed, quality: 85),
    );

    return ProcessedImageResult(
      preprocessed: preprocessed,
      compressed: compressed,
      compressedBytes: compressedBytes,
      processingTime: DateTime.now().difference(start),
    );
  }

  /// Vytvoří miniaturu pro náhled (synchronní, pro UI).
  static img.Image createThumbnail(img.Image image, int size) {
    return img.copyResize(
      image,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
  }

  /// Uloží bajty do dočasného souboru. Vrátí [File].
  static Future<File> saveBytesToTempFile(
    List<int> bytes, {
    bool isPng = false,
  }) async {
    final ext = isPng ? 'png' : 'jpg';
    final name = '${isPng ? 'processed' : 'compressed'}_'
        '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }
}
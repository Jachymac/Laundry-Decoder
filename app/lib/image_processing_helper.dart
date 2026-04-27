import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'image_preprocessor.dart';

/// Pomocné funkce pro zpracování obrázků v izolaci (bez blokování UI)
class ImageProcessingHelper {
  /// Dekóduje obrázek z bytů
  static img.Image? decodeImageInBg(List<int> bytes) {
    try {
      return img.decodeImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  /// Zpracuje obrázek (předzpracování a kompresi)
  static ProcessedImageResult processImageInBg(img.Image original) {
    try {
      // Preprocessing
      img.Image processed = ImagePreprocessor.preprocessForModel(original);

      // Kompresi na 512x512
      img.Image compressed = img.copyResize(
        processed,
        width: 512,
        height: 512,
      );

      final compressedBytes = img.encodeJpg(compressed, quality: 85);

      return ProcessedImageResult(
        preprocessed: processed,
        compressed: compressed,
        compressedBytes: compressedBytes,
      );
    } catch (e) {
      throw Exception("Nepodařilo se zpracovat obrázek: $e");
    }
  }

  /// Uloží bytes do souboru
  static Future<File> saveBytesToFile(
    List<int> bytes,
    String suffix, {
    bool isPng = false,
  }) async {
    try {
      final tempDir = Directory.systemTemp;
      final filename =
          '${isPng ? "processed" : "compressed"}_${DateTime.now().millisecondsSinceEpoch}.${isPng ? "png" : "jpg"}';
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception("Nepodařilo se uložit soubor: $e");
    }
  }

  /// Zkompresuje obrázek pro previw
  static img.Image createThumbnail(img.Image image, int size) {
    return img.copyResize(image, width: size, height: size);
  }
}

class ProcessedImageResult {
  final img.Image preprocessed;
  final img.Image compressed;
  final List<int> compressedBytes;

  ProcessedImageResult({
    required this.preprocessed,
    required this.compressed,
    required this.compressedBytes,
  });
}

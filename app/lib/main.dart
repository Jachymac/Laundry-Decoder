import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dictionary_screen.dart';
import 'ai_service.dart';
import 'image_processing_helper.dart';
import 'symbol_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaundryApp());
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Decoder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MainScreen(onNavigateToCatalog: _navigateToCatalog),
      const DictionaryScreen(),
    ];
  }

  void _navigateToCatalog() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Skener',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Katalog',
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCatalog;

  const MainScreen({super.key, this.onNavigateToCatalog});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  File? _imageFile;
  File? _processedImageFile;

  String _detectedSymbol = "";
  String _symbolCategory = "";
  String _symbolDescription = "";
  String _symbolTips = "";
  String _symbolWarning = "";

  // Katalog symbol pro porovnání
  Map<String, String>? _catalogSymbol;

  bool _isProcessing = false;
  bool _isDecoding = false;
  bool _isCompressing = false;
  bool _showProcessedImage = false;
  bool _isOnline = true;

  // Cache pro uložení výsledků (aby se nevolalo API zbytečně)
  final Map<String, Map<String, String>> _memoryCache = {};

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  // Vytvoření hashe obrázku pro cache
  String _getImageHash(List<int> bytes) {
    return md5.convert(bytes).toString();
  }

  // Uložení výsledku do cache
  Future<void> _saveToCacheAsync(String hash, Map<String, String> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$hash', json.encode(result));
  }

  // Načtení z cache
  Future<Map<String, String>?> _loadFromCacheAsync(String hash) async {
    // Nejdřív zkus memory cache
    if (_memoryCache.containsKey(hash)) {
      return _memoryCache[hash];
    }

    // Pak zkus persistent cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cache_$hash');
    if (cached != null) {
      final result = Map<String, String>.from(json.decode(cached));
      _memoryCache[hash] = result; // Ulož i do memory
      return result;
    }

    return null;
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ořízněte jeden symbol',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Ořízněte jeden symbol',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
          _detectedSymbol = "";
          _showProcessedImage = false;
        });
        _processAndAnalyze(File(croppedFile.path));
      }
    }
  }

  Future<void> _processAndAnalyze(File file) async {
    setState(() => _isProcessing = true);

    try {
      // 1. Dekódování obrázku v izolaci (bez blokování UI)
      setState(() => _isDecoding = true);
      
      final bytes = await file.readAsBytes();
      final original = await compute(
        ImageProcessingHelper.decodeImageInBg,
        bytes,
      );

      if (original == null) {
        throw Exception("Nelze dekódovat obrázek");
      }

      // 2. Zpracování obrázku v izolaci
      setState(() => _isDecoding = false);
      setState(() => _isCompressing = true);
      
      final result = await compute(
        ImageProcessingHelper.processImageInBg,
        original,
      );

      // Uložení preprocessovaného obrázku
      _processedImageFile = await ImageProcessingHelper.saveBytesToFile(
        img.encodePng(result.preprocessed),
        'processed',
        isPng: true,
      );

      // 3. Zkontroluj cache (aby se šetřily API requesty)
      final imageHash = _getImageHash(bytes);
      final cached = await _loadFromCacheAsync(imageHash);

      if (cached != null) {
        // Máme výsledek v cache!
        setState(() {
          _detectedSymbol = cached['symbol'] ?? '';
          _symbolCategory = cached['category'] ?? '';
          _symbolDescription = cached['description'] ?? '';
          _symbolTips = cached['tips'] ?? '';
          _symbolWarning = cached['warning'] ?? '';
          _catalogSymbol = LaundrySymbolCatalog.findMostSimilarSymbol(_detectedSymbol);
          _isCompressing = false;
        });
      debugPrint("✅ Výsledek načten z cache");
      return;
      }

      // 4. Zkontroluj připojení
      await _checkConnectivity();

      if (!_isOnline) {
        setState(() => _isCompressing = false);
        _showOfflineDialog();
        return;
      }

      // 5. Uložení kompresovaného obrázku
      final compressedFile = await ImageProcessingHelper.saveBytesToFile(
        result.compressedBytes,
        'compressed',
      );

      setState(() => _isCompressing = false);

      // 6. Pošli na AI (asynchronně)
      final aiResponse = await AiService.analyzeImage(compressedFile);

      // 7. Parsování strukturované odpovědi
      final parsed = _parseAiResponse(aiResponse);

      // 8. Hledej podobný symbol v katalogu
      final catalogMatch = LaundrySymbolCatalog.findMostSimilarSymbol(
        parsed['symbol'] ?? '',
      );

      setState(() {
        _detectedSymbol = parsed['symbol'] ?? 'Nerozpoznáno';
        _symbolCategory = parsed['category'] ?? '';
        _symbolDescription = parsed['description'] ?? '';
        _symbolTips = parsed['tips'] ?? '';
        _symbolWarning = parsed['warning'] ?? '';
        _catalogSymbol = catalogMatch;
      });

      // 9. Ulož do cache pro příště
      _memoryCache[imageHash] = parsed;
      _saveToCacheAsync(imageHash, parsed);

      debugPrint("✅ Symbol rozpoznán: $_detectedSymbol");

      // Smazání dočasného souboru
      await compressedFile.delete();

    } catch (e) {
      debugPrint("❌ Chyba: $e");
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
        _isDecoding = false;
        _isCompressing = false;
      });
    }
  }

  Map<String, String> _parseAiResponse(String response) {
    // Jednoduchý parser pro strukturovanou odpověď
    final result = <String, String>{};

    // Extrakce sekcí pomocí regulárních výrazů
    final symbolMatch = RegExp(r'🏷️ NÁZEV SYMBOLU:\s*(.+?)(?=\n|$)', multiLine: true).firstMatch(response);
    final categoryMatch = RegExp(r'📋 KATEGORIE:\s*(.+?)(?=\n|$)', multiLine: true).firstMatch(response);
    final descMatch = RegExp(r'📖 INSTRUKCE:\s*(.+?)(?=💡|⚠️|$)', multiLine: true, dotAll: true).firstMatch(response);
    final tipsMatch = RegExp(r'💡 TIPY:\s*(.+?)(?=⚠️|$)', multiLine: true, dotAll: true).firstMatch(response);
    final warningMatch = RegExp(r'⚠️ VAROVÁNÍ:\s*(.+?)$', multiLine: true, dotAll: true).firstMatch(response);

    result['symbol'] = symbolMatch?.group(1)?.trim() ?? 'Nerozpoznáno';
    result['category'] = categoryMatch?.group(1)?.trim() ?? '';
    result['description'] = descMatch?.group(1)?.trim() ?? response;
    result['tips'] = tipsMatch?.group(1)?.trim() ?? '';
    result['warning'] = warningMatch?.group(1)?.trim() ?? '';

    return result;
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text("Jste offline"),
          ],
        ),
        content: const Text(
          "Pro rozpoznání symbolu je potřeba připojení k internetu.\n\n"
          "Můžete použít offline katalog symbolů v druhé záložce.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigateToCatalog?.call();
            },
            child: const Text("Otevřít katalog"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Zavřít"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Chyba"),
          ],
        ),
        content: Text("Nepodařilo se analyzovat symbol.\n\n$error"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Zavřít"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Skener symbolů',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Indikátor online/offline
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: _isOnline ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Karta s obrázkem
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Toggle mezi originálem a preprocessem
                      if (_imageFile != null && _processedImageFile != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showProcessedImage ? "Preprocessováno" : "Originál",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Switch(
                              value: _showProcessedImage,
                              onChanged: (val) {
                                setState(() {
                                  _showProcessedImage = val;
                                });
                              },
                            ),
                          ],
                        ),

                      // Zobrazení obrázku
                      Container(
                        height: 250,
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  _showProcessedImage && _processedImageFile != null
                                      ? _processedImageFile!
                                      : _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_search,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Vyfotit nebo vybrat symbol",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 20),

                      // Tlačítka pro výběr zdroje
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _pickAndCropImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Fotoaparát"),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _pickAndCropImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text("Galerie"),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Načítání
              if (_isProcessing)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        if (_isDecoding)
                          const Row(
                            children: [
                              Icon(Icons.photo, size: 20, color: Colors.blue),
                              SizedBox(width: 12),
                              Text("Dekódování obrázku..."),
                            ],
                          )
                        else if (_isCompressing)
                          const Row(
                            children: [
                              Icon(Icons.compress, size: 20, color: Colors.blue),
                              SizedBox(width: 12),
                              Text("Zpracování a kompresi..."),
                            ],
                          )
                        else
                          const Row(
                            children: [
                              Icon(Icons.smart_toy, size: 20, color: Colors.blue),
                              SizedBox(width: 12),
                              Text("AI analyzuje symbol..."),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              // Karta s výsledkem
              if (_detectedSymbol.isNotEmpty && !_isProcessing)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "VÝSLEDEK ANALÝZY",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Název symbolu
                        Center(
                          child: Text(
                            _detectedSymbol,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Kategorie
                        if (_symbolCategory.isNotEmpty)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _symbolCategory,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // Porovnání s katalogem
                        if (_catalogSymbol != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Porovnání s katalogem",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_catalogSymbol!['asset'] != null)
                                        Container(
                                          width: 80,
                                          height: 80,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.green.shade100,
                                            ),
                                          ),
                                          child: Image.asset(
                                            _catalogSymbol!['asset']!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${_catalogSymbol!['čeština']} (${_catalogSymbol!['anglicky']})",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _catalogSymbol!['popis'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),

                        // Instrukce
                        if (_symbolDescription.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blueAccent,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _symbolDescription,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Tipy
                        if (_symbolTips.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _symbolTips,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Varování
                        if (_symbolWarning.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _symbolWarning,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
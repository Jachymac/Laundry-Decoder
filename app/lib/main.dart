import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dictionary_screen.dart';
import 'ai_service.dart';
import 'image_processing_helper.dart';
import 'online_status.dart';

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

  final List<Widget> _screens = [
    const MainScreen(),
    const DictionaryScreen(),
  ];

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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  XFile? _imageFile;
  File? _processedImageFile;
  Uint8List? _processedImageBytes;

  String _detectedSymbol = "";
  String _symbolCategory = "";
  String _symbolDescription = "";
  String _symbolTips = "";
  String _symbolWarning = "";

  bool _isProcessing = false;
  bool _showProcessedImage = false;
  bool _isOnline = true;

  // OPTIMALIZACE: Caching
  final Map<String, Map<String, String>> _memoryCache = {};

  // OPTIMALIZACE: Progress tracking
  String _processingStage = "";
  double _progress = 0.0;

  // OPTIMALIZACE: Rate limiting
  DateTime? _lastApiCall;
  static const _minDelayBetweenCalls = Duration(seconds: 2);

  // OPTIMALIZACE: Statistics
  int _todayScans = 0;
  int _cacheHits = 0;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().day;
    final savedDay = prefs.getInt('stats_day') ?? 0;

    if (savedDay != today) {
      // Nový den - reset statistik
      await prefs.setInt('stats_day', today);
      await prefs.setInt('today_scans', 0);
      await prefs.setInt('cache_hits', 0);
    }

    setState(() {
      _todayScans = prefs.getInt('today_scans') ?? 0;
      _cacheHits = prefs.getInt('cache_hits') ?? 0;
    });
  }

  Future<void> _incrementStatistics({bool fromCache = false}) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todayScans++;
      if (fromCache) _cacheHits++;
    });
    await prefs.setInt('today_scans', _todayScans);
    if (fromCache) {
      await prefs.setInt('cache_hits', _cacheHits);
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      if (kIsWeb) {
        final online = await checkOnlineStatus();
        setState(() {
          _isOnline = online;
        });
      } else {
        // Pro mobilní zařízení použijeme InternetAddress.lookup
        final result = await InternetAddress.lookup('google.com');
        setState(() {
          _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        });
      }
    } catch (_) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  // OPTIMALIZACE: MD5 hash pro cache
  String _getImageHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  // OPTIMALIZACE: Načtení z cache
  Future<Map<String, String>?> _loadFromCache(String hash) async {
    // Memory cache (rychlé)
    if (_memoryCache.containsKey(hash)) {

    }

    // Persistent cache (pomalejší, ale přežije restart)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cache_$hash');
    
    if (cached != null) {
      try {
        final result = Map<String, String>.from(json.decode(cached));
        _memoryCache[hash] = result; // Ulož i do memory
        return result;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // OPTIMALIZACE: Uložení do cache
  Future<void> _saveToCache(String hash, Map<String, String> result) async {
    _memoryCache[hash] = result;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$hash', json.encode(result));
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Pro web přeskočíme ořezávání (ImageCropper nefunguje na webu)
        setState(() {
          _imageFile = pickedFile;
          _detectedSymbol = "";
          _showProcessedImage = false;
        });
        _processAndAnalyze(pickedFile);
      } else {
        // Pro mobilní zařízení použijeme ořezávání
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
            _imageFile = XFile(croppedFile.path);
            _detectedSymbol = "";
            _showProcessedImage = false;
          });
          _processAndAnalyze(XFile(croppedFile.path));
        }
      }
    }
  }

  Future<void> _processAndAnalyze(XFile file) async {
    // OPTIMALIZACE: Rate limiting
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed < _minDelayBetweenCalls) {
        final remaining = _minDelayBetweenCalls - elapsed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⏳ Počkejte ${remaining.inSeconds}s před dalším skenem"),
            duration: remaining,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _processingStage = "Načítání obrázku...";
      _progress = 0.1;
    });

    try {
      final bytes = await file.readAsBytes();
      
      setState(() {
        _processingStage = "Dekódování...";
        _progress = 0.2;
      });

      img.Image? original = img.decodeImage(bytes);
      if (original == null) {
        throw Exception("Nelze dekódovat obrázek");
      }

      // OPTIMALIZACE: Kontrola cache PŘED preprocessingem
      final hash = _getImageHash(bytes);
      
      setState(() {
        _processingStage = "Kontrola cache...";
        _progress = 0.3;
      });

      final cached = await _loadFromCache(hash);
      
      if (cached != null) {
        // NAŠLI V CACHE!
        setState(() {
          _detectedSymbol = cached['symbol'] ?? '';
          _symbolCategory = cached['category'] ?? '';
          _symbolDescription = cached['description'] ?? '';
          _symbolTips = cached['tips'] ?? '';
          _symbolWarning = cached['warning'] ?? '';
          _processingStage = "Hotovo z cache!";
          _progress = 1.0;
        });

        await _incrementStatistics(fromCache: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.flash_on, color: Colors.white),
                SizedBox(width: 8),
                Text("⚡ Načteno z cache (okamžitě)"),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        setState(() => _isProcessing = false);
        return; // KONEC - nepokračovat s API!
      }

      // CACHE MISS - pokračuj s preprocessingem
      setState(() {
        _processingStage = "Preprocessing...";
        _progress = 0.4;
      });

      // OPTIMALIZACE: Použij nový ImageProcessingHelper s isolátem
      final processedResult = await ImageProcessingHelper.processXFile(
        _imageFile!,
        onProgress: (progress) {
          setState(() {
            _progress = 0.4 + (progress * 0.4); // 0.4-0.8 range
          });
        },
      );

      // Uložení preprocessovaného obrázku pro zobrazení
      final processedBytes = img.encodePng(processedResult.preprocessed);
      if (kIsWeb) {
        _processedImageBytes = processedBytes;
        _processedImageFile = null;
      } else {
        final tempDir = Directory.systemTemp;
        final processedPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(processedPath).writeAsBytes(processedBytes);
        _processedImageFile = File(processedPath);
      }

      setState(() {
        _processingStage = "Komprese...";
        _progress = 0.8;
      });

      // Kompresovaný obrázek už máme z result
      final compressedBytes = processedResult.compressedBytes;

      // Kontrola připojení
      await _checkConnectivity();

      if (!_isOnline) {
        _showOfflineDialog();
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _processingStage = "Posílám na AI...";
        _progress = 0.8;
      });

      // Volání AI
      final aiResponse = await AiService.analyzeImage(compressedBytes);
      _lastApiCall = DateTime.now(); // Rate limit tracking

      setState(() {
        _processingStage = "Parsování výsledku...";
        _progress = 0.9;
      });

      // Parsování
      final parsed = _parseAiResponse(aiResponse);

      setState(() {
        _detectedSymbol = parsed['symbol'] ?? 'Nerozpoznáno';
        _symbolCategory = parsed['category'] ?? '';
        _symbolDescription = parsed['description'] ?? '';
        _symbolTips = parsed['tips'] ?? '';
        _symbolWarning = parsed['warning'] ?? '';
        _processingStage = "Hotovo!";
        _progress = 1.0;
      });

      // ULOŽENÍ DO CACHE
      await _saveToCache(hash, parsed);
      await _incrementStatistics(fromCache: false);


    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Map<String, String> _parseAiResponse(String response) {
    final result = <String, String>{};

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
              // Přepni na katalog (potřebuješ přístup k _currentIndex z AppNavigator)
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
    String title = "Chyba";
    String message = error;
    String action = "Zavřít";
    VoidCallback? actionCallback;

    // OPTIMALIZACE: User-friendly error messages
    if (error.contains("Quota exceeded") || error.contains("quota")) {
      title = "Překročen limit";
      message = "Dosáhli jste denního limitu API.\n\n"
          "Dnes jste naskenovali: $_todayScans symbolů\n"
          "Cache hits: $_cacheHits\n\n"
          "Zkuste to zítra nebo použijte offline katalog.";
      action = "Otevřít katalog";
    } else if (error.contains("internet") || error.contains("network")) {
      title = "Chyba připojení";
      message = "Zkontrolujte připojení k internetu.\n\n"
          "Offline katalog je stále dostupný.";
      action = "Otevřít katalog";
    } else if (error.contains("RATE_LIMIT")) {
      title = "Příliš mnoho požadavků";
      message = "Počkejte chvíli a zkuste znovu.";
      action = "OK";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (error.contains("Quota") || error.contains("internet"))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processAndAnalyze(_imageFile!); // Retry
              },
              child: const Text("Zkusit znovu"),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              actionCallback?.call();
            },
            child: Text(action),
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
          // Online/Offline indikátor
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
          // OPTIMALIZACE: Statistiky
          PopupMenuButton(
            icon: const Icon(Icons.info_outline),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dnešní statistiky",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("Naskenováno: $_todayScans"),
                    Text("Z cache: $_cacheHits"),
                    Text("API volání: ${_todayScans - _cacheHits}"),
                    if (_todayScans > 0)
                      Text(
                        "Úspora: ${(_cacheHits / _todayScans * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
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
                      // Toggle - zobraz na webu i mobilu
                      if (_imageFile != null && 
                          ((kIsWeb && _processedImageBytes != null) || 
                           (!kIsWeb && _processedImageFile != null)))
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

                      // Obrázek
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
                                child: FutureBuilder<Uint8List>(
                                  future: _showProcessedImage
                                      ? (_processedImageBytes != null
                                          ? Future.value(_processedImageBytes!)
                                          : _processedImageFile!.readAsBytes())
                                      : _imageFile!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                  },
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

                      // Tlačítka
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

              // OPTIMALIZACE: Lepší progress indikátor
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
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _processingStage,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(_progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Výsledky (stejné jako předtím, ale s lepším UX)
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

                        // Název
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

                        // OPTIMALIZACE: Retry tlačítko
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _processAndAnalyze(_imageFile!),
                            icon: const Icon(Icons.refresh),
                            label: const Text("Zkusit znovu"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
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
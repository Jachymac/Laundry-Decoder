import 'package:flutter/material.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  // KOMPLETNÍ databáze VŠECH standardních pracích symbolů
  final List<Map<String, String>> _allSymbols = [
    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: PRANÍ (WASHING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "machine-wash-normal",
      "title": "Praní v pračce",
      "description":
          "Běžný program praní v pračce. Symbol obvykle obsahuje teplotu (30°, 40°, 60°, 95°). Číslo udává maximální teplotu vody v °C.",
      "category": "Praní",
      "temp": "různé"
    },
    {
      "id": "machine-wash-permanent-press",
      "title": "Šetrné praní",
      "description":
          "Program s jemným odstřeďováním a sníženou mechanickou akcí. Jedna čára pod symbolem. Vhodné pro syntetické tkaniny a směsové materiály.",
      "category": "Praní",
      "temp": "různé"
    },
    {
      "id": "machine-wash-delicate",
      "title": "Velmi šetrné praní",
      "description":
          "Velmi jemný program s minimální mechanickou akcí. Dvě čáry pod symbolem. Pro citlivé materiály jako hedvábí, vlna, krajky.",
      "category": "Praní",
      "temp": "různé"
    },
    {
      "id": "machine-wash-cold",
      "title": "Praní v pračce - studená voda",
      "description":
          "Praní v pračce na studenou vodu (max 30°C). Symbol obsahuje číslo 30 nebo sněhovou vločku.",
      "category": "Praní",
      "temp": "max 30°C"
    },
    {
      "id": "machine-wash-warm",
      "title": "Praní v pračce - teplá voda",
      "description":
          "Praní v pračce na teplou vodu (max 40°C). Symbol obsahuje číslo 40.",
      "category": "Praní",
      "temp": "max 40°C"
    },
    {
      "id": "machine-wash-hot",
      "title": "Praní v pračce - horká voda",
      "description":
          "Praní v pračce na horkou vodu (max 60°C). Symbol obsahuje číslo 60.",
      "category": "Praní",
      "temp": "max 60°C"
    },
    {
      "id": "machine-wash-very-hot",
      "title": "Praní v pračce - velmi horká voda",
      "description":
          "Praní v pračce na velmi horkou vodu (max 95°C). Symbol obsahuje číslo 95.",
      "category": "Praní",
      "temp": "max 95°C"
    },
    {
      "id": "hand-wash",
      "title": "Pouze ruční praní",
      "description":
          "Perte pouze ručně ve vlažné vodě (max 40°C). Nepoužívejte pračku. Jemně mačkejte, nekruťte. Vhodné pro velmi jemné tkaniny.",
      "category": "Praní",
      "temp": "max 40°C"
    },
    {
      "id": "do-not-machine-wash",
      "title": "Neprat v pračce",
      "description":
          "Oblečení nesmí být prané v pračce. Přeškrtnutý lavor. Perte pouze ručně nebo chemicky.",
      "category": "Praní",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: BĚLENÍ (BLEACHING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "bleach",
      "title": "Lze bělit",
      "description":
          "Lze použít jakýkoli typ bělicího prostředku (s chlorem i bez chloru). Prázdný trojúhelník.",
      "category": "Bělení",
      "temp": "—"
    },
    {
      "id": "bleach-non-chlorine",
      "title": "Pouze kyslíkové bělení",
      "description":
          "Lze bělit pouze prostředky bez chloru (kyslíkové). Trojúhelník se dvěma diagonálními čarami. Chlor by poškodil materiál.",
      "category": "Bělení",
      "temp": "—"
    },
    {
      "id": "do-not-bleach",
      "title": "Nebělit",
      "description":
          "Nesmí se používat žádné bělicí prostředky. Přeškrtnutý trojúhelník. Bělení by poškodilo barvu nebo strukturu látky.",
      "category": "Bělení",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: SUŠENÍ V SUŠIČCE (TUMBLE DRYING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "tumble-dry-normal",
      "title": "Sušení v sušičce - normální",
      "description":
          "Běžné sušení v sušičce na normální teplotu. Kruh ve čtverci. Bez dalších značek.",
      "category": "Sušení v sušičce",
      "temp": "normální"
    },
    {
      "id": "tumble-dry-low",
      "title": "Sušení v sušičce - nízká teplota",
      "description":
          "Sušit v sušičce pouze na nízkou teplotu. Jedna tečka uvnitř kruhu. Pro citlivější materiály.",
      "category": "Sušení v sušičce",
      "temp": "nízká"
    },
    {
      "id": "tumble-dry-medium",
      "title": "Sušení v sušičce - střední teplota",
      "description":
          "Sušit v sušičce na střední teplotu. Dvě tečky uvnitř kruhu. Pro běžné oblečení.",
      "category": "Sušení v sušičce",
      "temp": "střední"
    },
    {
      "id": "tumble-dry-high",
      "title": "Sušení v sušičce - vysoká teplota",
      "description":
          "Sušit v sušičce na vysokou teplotu. Tři tečky uvnitř kruhu. Pro odolné materiály jako ručníky, bavlněné povlečení.",
      "category": "Sušení v sušičce",
      "temp": "vysoká"
    },
    {
      "id": "tumble-dry-delicate",
      "title": "Sušení v sušičce - šetrné",
      "description":
          "Sušit v sušičce na šetrný program s nižší teplotou. Jedna tečka uvnitř kruhu. Pro jemné materiály.",
      "category": "Sušení v sušičce",
      "temp": "šetrná"
    },
    {
      "id": "tumble-dry-permanent-press",
      "title": "Sušení v sušičce - permanent press",
      "description":
          "Sušit v sušičce na program pro materiály, které si mají zachovat tvar. Dvě tečky uvnitř kruhu.",
      "category": "Sušení v sušičce",
      "temp": "permanent press"
    },
    {
      "id": "tumble-dry-no-heat",
      "title": "Sušení v sušičce - bez tepla",
      "description":
          "Sušit v sušičce pouze na studený vzduch, bez ohřevu. Prázdný kruh. Pro velmi citlivé materiály.",
      "category": "Sušení v sušičce",
      "temp": "studený vzduch"
    },
    {
      "id": "do-not-tumble-dry",
      "title": "Nesušit v sušičce",
      "description":
          "Nelze sušit v automatické sušičce. Přeškrtnutý kruh ve čtverci. Sušte pouze na vzduchu.",
      "category": "Sušení v sušičce",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: PŘÍRODNÍ SUŠENÍ (NATURAL DRYING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "hang-dry",
      "title": "Sušit na šňůře",
      "description":
          "Pověste oblečení na šňůru nebo ramínko a nechte oschnout na vzduchu. Svislá čára ve čtverci.",
      "category": "Přírodní sušení",
      "temp": "—"
    },
    {
      "id": "drip-dry",
      "title": "Sušit odkapáváním",
      "description":
          "Pověste mokré oblečení a nechte vodu odkapat. Tři svislé čáry ve čtverci. Neždímejte.",
      "category": "Přírodní sušení",
      "temp": "—"
    },
    {
      "id": "dry-flat",
      "title": "Sušit vodorovně",
      "description":
          "Položte oblečení na rovný povrch (například na ručník) a nechte vyschnout. Vodorovná čára ve čtverci. Pro vlněné svetry a podobné kusy.",
      "category": "Přírodní sušení",
      "temp": "—"
    },
    {
      "id": "dry-in-shade",
      "title": "Sušit ve stínu",
      "description":
          "Sušte mimo přímé sluneční světlo. Dvě diagonální čáry v rohu čtverce. Slunce by vybledly barvy nebo poškodilo materiál.",
      "category": "Přírodní sušení",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: ŽDÍMÁNÍ (WRINGING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "do-not-wring",
      "title": "Neždímat",
      "description":
          "Vodu z oblečení vymačkejte jemně, nekruťte látku. Kroucení by poškodilo strukturu materiálu. Obvykle pro vlnu, hedvábí, jemné tkaniny.",
      "category": "Ždímání",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: ŽEHLENÍ (IRONING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "iron-low",
      "title": "Žehlení - nízká teplota",
      "description":
          "Žehlit pouze na nízkou teplotu (max 110°C). Jedna tečka v žehličce. Pro akryl, nylon, polyester, elastan.",
      "category": "Žehlení",
      "temp": "110°C"
    },
    {
      "id": "iron-medium",
      "title": "Žehlení - střední teplota",
      "description":
          "Žehlit na střední teplotu (max 150°C). Dvě tečky v žehličce. Pro vlnu, polyester-bavlněné směsi.",
      "category": "Žehlení",
      "temp": "150°C"
    },
    {
      "id": "iron-high",
      "title": "Žehlení - vysoká teplota",
      "description":
          "Lze žehlit na vysokou teplotu (max 200°C). Tři tečky v žehličce. Vhodné pro bavlnu a len.",
      "category": "Žehlení",
      "temp": "200°C"
    },
    {
      "id": "do-not-iron",
      "title": "Nežehlit",
      "description":
          "Toto oblečení nesmí být žehleno. Přeškrtnutá žehlička. Teplo by poškodilo materiál nebo výzdobu (potisky, nášivky).",
      "category": "Žehlení",
      "temp": "—"
    },
    {
      "id": "iron-no-steam",
      "title": "Žehlit bez páry",
      "description":
          "Žehlit lze, ale bez použití páry. Žehlička s přeškrtnutou parou. Pára by způsobila skvrny nebo poškození.",
      "category": "Žehlení",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: CHEMICKÉ ČIŠTĚNÍ (DRY CLEANING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "dry-clean",
      "title": "Chemické čištění",
      "description":
          "Lze čistit profesionálním chemickým čištěním. Prázdný kruh. Specifické písmeno uvnitř (P, F, W) označuje typ rozpouštědla.",
      "category": "Chemické čištění",
      "temp": "—"
    },
    {
      "id": "dry-clean-any-solvent",
      "title": "Chemické čištění - jakékoli rozpouštědlo",
      "description":
          "Chemické čištění jakýmkoli rozpouštědlem. Písmeno A v kruhu. Pro odolné materiály.",
      "category": "Chemické čištění",
      "temp": "—"
    },
    {
      "id": "dry-clean-tetrachloroethylene-solvent-only",
      "title": "Chemické čištění - tetrachlorethylen",
      "description":
          "Chemické čištění pouze tetrachlorethylenem. Písmeno P v kruhu. Standardní proces.",
      "category": "Chemické čištění",
      "temp": "—"
    },
    {
      "id": "dry-clean-hydrocarbon-solvent-only",
      "title": "Chemické čištění - uhlovodíky",
      "description":
          "Chemické čištění pouze uhlovodíkovými rozpouštědly. Alternativní označení pro F. Šetrnější než perchlorethylen.",
      "category": "Chemické čištění",
      "temp": "—"
    },
    {
      "id": "do-not-dry-clean",
      "title": "Nečistit chemicky",
      "description":
          "Nesmí se používat chemické čištění. Přeškrtnutý kruh. Chemikálie by poškodily materiál. Pouze domácí péče.",
      "category": "Chemické čištění",
      "temp": "—"
    },

    // ═══════════════════════════════════════════════════════════════
    // KATEGORIE: PROFESIONÁLNÍ MOKRÉ ČIŠTĚNÍ (WET CLEANING)
    // ═══════════════════════════════════════════════════════════════
    {
      "id": "professional-wet-cleaning-only",
      "title": "Pouze profesionální mokré čištění",
      "description":
          "Lze čistit pouze profesionálním mokrým čištěním. Písmeno W v kruhu. Ekologická alternativa k chemickému čištění.",
      "category": "Profesionální čištění",
      "temp": "—"
    },
  ];

  List<Map<String, String>> _filteredSymbols = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Vše";

  // Seznam všech kategorií
  final List<String> _categories = [
    "Vše",
    "Praní",
    "Bělení",
    "Sušení v sušičce",
    "Přírodní sušení",
    "Ždímání",
    "Žehlení",
    "Chemické čištění",
    "Profesionální čištění",
  ];

  @override
  void initState() {
    super.initState();
    _filteredSymbols = _allSymbols;
  }

  void _filterSymbols(String query) {
    setState(() {
      _filteredSymbols = _allSymbols.where((symbol) {
        final matchesSearch = query.isEmpty ||
            symbol["title"]!.toLowerCase().contains(query.toLowerCase()) ||
            symbol["description"]!.toLowerCase().contains(query.toLowerCase());

        final matchesCategory = _selectedCategory == "Vše" ||
            symbol["category"] == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterSymbols(_searchController.text);
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Praní":
        return Colors.blue;
      case "Bělení":
        return Colors.cyan;
      case "Sušení v sušičce":
        return Colors.orange;
      case "Přírodní sušení":
        return Colors.green;
      case "Ždímání":
        return Colors.purple;
      case "Žehlení":
        return Colors.red;
      case "Chemické čištění":
        return Colors.brown;
      case "Profesionální čištění":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Praní":
        return Icons.local_laundry_service;
      case "Bělení":
        return Icons.water_drop;
      case "Sušení v sušičce":
        return Icons.dry_cleaning;
      case "Přírodní sušení":
        return Icons.air;
      case "Ždímání":
        return Icons.rotate_right;
      case "Žehlení":
        return Icons.iron;
      case "Chemické čištění":
        return Icons.science;
      case "Profesionální čištění":
        return Icons.cleaning_services;
      default:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Katalog symbolů',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSymbols,
              decoration: InputDecoration(
                hintText: 'Hledat symbol...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSymbols('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Horizontální filtr kategorií
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _filterByCategory(category),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Počet výsledků
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nalezeno: ${_filteredSymbols.length} symbolů',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                if (_selectedCategory != "Vše" || _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _filterByCategory("Vše");
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text("Zrušit filtry", style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Seznam symbolů
          Expanded(
            child: _filteredSymbols.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Žádný symbol nenalezen",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Zkuste jiná klíčová slova",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _filteredSymbols.length,
                    itemBuilder: (context, index) {
                      final symbol = _filteredSymbols[index];
                      final categoryColor = _getCategoryColor(symbol["category"]!);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage('assets/symbols/${symbol["id"]}.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          title: Text(
                            symbol["title"]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  symbol["category"]!,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (symbol["temp"] != "—" && symbol["temp"] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    symbol["temp"]!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    symbol["description"]!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

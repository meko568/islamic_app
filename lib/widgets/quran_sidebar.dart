import 'package:flutter/material.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';

class QuranSidebar extends StatefulWidget {
  static const Map<int, int> _surahAyahCount = {
    1: 7,
    2: 286,
    3: 200,
    4: 176,
    5: 120,
    6: 165,
    7: 206,
    8: 75,
    9: 129,
    10: 109,
    11: 123,
    12: 111,
    13: 43,
    14: 52,
    15: 99,
    16: 128,
    17: 111,
    18: 110,
    19: 98,
    20: 135,
    21: 112,
    22: 78,
    23: 118,
    24: 64,
    25: 77,
    26: 227,
    27: 93,
    28: 88,
    29: 69,
    30: 60,
    31: 34,
    32: 30,
    33: 73,
    34: 54,
    35: 45,
    36: 83,
    37: 182,
    38: 88,
    39: 75,
    40: 85,
    41: 54,
    42: 53,
    43: 89,
    44: 59,
    45: 37,
    46: 35,
    47: 38,
    48: 29,
    49: 18,
    50: 45,
    51: 60,
    52: 49,
    53: 62,
    54: 55,
    55: 78,
    56: 96,
    57: 29,
    58: 22,
    59: 24,
    60: 13,
    61: 14,
    62: 11,
    63: 11,
    64: 18,
    65: 12,
    66: 12,
    67: 30,
    68: 52,
    69: 52,
    70: 44,
    71: 28,
    72: 28,
    73: 20,
    74: 56,
    75: 40,
    76: 31,
    77: 50,
    78: 40,
    79: 46,
    80: 42,
    81: 29,
    82: 19,
    83: 36,
    84: 25,
    85: 22,
    86: 17,
    87: 19,
    88: 26,
    89: 30,
    90: 20,
    91: 15,
    92: 21,
    93: 11,
    94: 8,
    95: 8,
    96: 19,
    97: 5,
    98: 8,
    99: 8,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
  };

  final Function(int surahNumber, int ayahNumber) onNavigateToAyah;
  final Function(int pageNumber) onNavigateToPage;
  final Function(int juzNumber) onNavigateToJuz;

  const QuranSidebar({
    super.key,
    required this.onNavigateToAyah,
    required this.onNavigateToPage,
    required this.onNavigateToJuz,
  });

  @override
  State<QuranSidebar> createState() => _QuranSidebarState();
}

class _QuranSidebarState extends State<QuranSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Surah>? _surahs;
  bool _isLoading = true;
  int? _selectedSurahNumber;
  int? _selectedAyahNumber;
  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSurahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await QuranService.getQuran();
      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B6914),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF5D4E37), width: 2),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'القرآن الكريم',
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF8B6914),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF8B6914),
            labelStyle: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'الأجزاء'),
              Tab(text: 'السور'),
              Tab(text: 'الصفحات'),
            ],
          ),
          // Tab content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildJuzTab(),
                        _buildSurahTab(),
                        _buildPagesTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuzTab() {
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return ListTile(
          title: Text(
            'الجزء $juzNumber',
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 18,
              color: Color(0xFF2C1810),
            ),
            textDirection: TextDirection.rtl,
          ),
          trailing: const Icon(Icons.chevron_left, color: Color(0xFF8B6914)),
          onTap: () {
            widget.onNavigateToJuz(juzNumber);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildSurahTab() {
    return Column(
      children: [
        // Surah selector
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'اختر السورة',
              labelStyle: const TextStyle(
                fontFamily: 'UthmanicHafs',
                color: Color(0xFF8B6914),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8B6914)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B6914),
                  width: 2,
                ),
              ),
            ),
            initialValue: _selectedSurahNumber,
            items:
                _surahs?.map((surah) {
                  return DropdownMenuItem<int>(
                    value: surah.number,
                    child: Text(
                      '${surah.number}. ${surah.nameArabic}',
                      style: const TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontSize: 16,
                        color: Color(0xFF2C1810),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSurahNumber = value;
                _selectedAyahNumber = null;
              });
            },
          ),
        ),
        // Ayah count display (shown when surah is selected)
        if (_selectedSurahNumber != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'عدد الآيات: ${QuranSidebar._surahAyahCount[_selectedSurahNumber] ?? 0}',
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 14,
                color: Color(0xFF8B6914),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        // Ayah selector (shown when surah is selected)
        if (_selectedSurahNumber != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'اختر الآية',
                labelStyle: const TextStyle(
                  fontFamily: 'UthmanicHafs',
                  color: Color(0xFF8B6914),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B6914)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B6914),
                    width: 2,
                  ),
                ),
              ),
              initialValue: _selectedAyahNumber,
              items: List.generate(
                QuranSidebar._surahAyahCount[_selectedSurahNumber] ?? 0,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(
                    'الآية ${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 16,
                      color: Color(0xFF2C1810),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedAyahNumber = value;
                });
              },
            ),
          ),
        // Go button
        if (_selectedSurahNumber != null && _selectedAyahNumber != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                widget.onNavigateToAyah(
                  _selectedSurahNumber!,
                  _selectedAyahNumber!,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'اذهب ↵',
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPagesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'رقم الصفحة (1-604)',
              labelStyle: const TextStyle(
                fontFamily: 'UthmanicHafs',
                color: Color(0xFF8B6914),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8B6914)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B6914),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF8B6914)),
                onPressed: () {
                  final pageNumber = int.tryParse(_pageController.text);
                  if (pageNumber != null &&
                      pageNumber >= 1 &&
                      pageNumber <= 604) {
                    widget.onNavigateToPage(pageNumber);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 18,
              color: Color(0xFF2C1810),
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 604,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return InkWell(
                  onTap: () {
                    widget.onNavigateToPage(pageNumber);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B6914),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$pageNumber',
                        style: const TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

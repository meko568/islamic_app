import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../widgets/quran_sidebar.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import 'tafsir_screen.dart';

enum QuranLayoutMode { mushaf, adaptive }

class QuranScreen extends StatefulWidget {
  final int? initialSurahNumber;
  const QuranScreen({super.key, this.initialSurahNumber});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late PageController _pageController;
  late ScrollController _adaptiveScrollController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  String _currentSurahName = '';
  int _currentJuz = 1;
  bool _showLastPageMessage = false;
  String? _mushafImagesPath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int? _bookmarkedPage;

  final Map<int, String> _translationCache = {};
  bool _translationLoading = false;

  // ✅ FIX 1: Cache كل الآيات في الذاكرة — مفيش reload
  final Map<int, List<Ayah>> _pageCache = {};
  final Map<int, bool> _pageExists = {};
  final Map<int, int> _surahNumberForAyahNumber = {};
  final Map<int, Surah> _surahByNumber = {};
  final List<int> _headersBeforeIndex = [];
  bool _mushafFullyDownloaded = false;
  List<Surah> _allSurahs = [];
  List<Ayah> _allAyahs = [];
  final Map<int, GlobalKey> _surahKeys = {};
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _adaptiveScrollController = ScrollController();
    _loadQuran().then((_) {
      if (widget.initialSurahNumber != null && mounted) {
        _navigateToAyah(widget.initialSurahNumber!, 1);
      }
    });
    _pageController.addListener(_onPageChanged);
    _adaptiveScrollController.addListener(_onAdaptiveScrollChanged);
    _getMushafImagesPath();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bookmarkedPage = prefs.getInt('bookmarked_page');
      });
    } catch (_) {}
  }

  Future<void> _saveBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bookmarked_page', _currentPage);
      setState(() {
        _bookmarkedPage = _currentPage;
      });
      if (mounted) {
        final lang = context.read<SettingsProvider>().appLanguage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('bookmark_saved', lang, params: {'page': _currentPage.toString()})),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF8B6914),
          ),
        );
      }
    } catch (_) {}
  }

  void _goToBookmark() {
    if (_bookmarkedPage != null) {
      _navigateToPage(_bookmarkedPage!);
    } else {
      final lang = context.read<SettingsProvider>().appLanguage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('no_bookmark', lang))),
      );
    }
  }

  Future<void> _loadEnglishTranslation(int surahNumber) async {
    final settings = context.read<SettingsProvider>();
    final translationLang = settings.quranTranslationLang;
    if (translationLang == 'none') {
      setState(() {
        _translationCache.clear();
        _translationLoading = false;
      });
      return;
    }

    setState(() => _translationLoading = true);

    final edition = translationLang == 'ar' ? 'ar.muyassar' : 'en.sahih';
    final url = "https://api.alquran.cloud/v1/surah/$surahNumber/$edition";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List verses = data['data']['ayahs'];
        final Map<int, String> result = {};
        for (final v in verses) {
          result[v['numberInSurah'] as int] = v['text'] as String;
        }
        setState(() {
          _translationCache.clear();
          _translationCache.addAll(result);
          _translationLoading = false;
        });
      }
    } catch (e) {
      setState(() => _translationLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _adaptiveScrollController.removeListener(_onAdaptiveScrollChanged);
    _pageController.dispose();
    _adaptiveScrollController.dispose();
    super.dispose();
  }

  Future<void> _getMushafImagesPath() async {
    if (kIsWeb) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final mushafPath = '${appDocDir.path}/quran_pages';
      
      final prefs = await SharedPreferences.getInstance();
      final isDownloaded = prefs.getBool('mushaf_fully_downloaded') ?? false;

      setState(() {
        _mushafImagesPath = mushafPath;
        _mushafFullyDownloaded = isDownloaded;
      });

      // Pre-check file existence for all pages
      await _checkPageExistence();
    } catch (_) {}
  }

  Future<void> _checkPageExistence() async {
    if (_mushafImagesPath == null) return;
    
    int existingCount = 0;
    for (int i = 1; i <= 604; i++) {
      final imagePath = '$_mushafImagesPath/page_$i.png';
      final imageFile = File(imagePath);
      // Check if file exists AND has content (not 0 bytes)
      final exists = await imageFile.exists();
      if (exists) {
        final size = await imageFile.length();
        if (size > 5000) {
          _pageExists[i] = true;
          existingCount++;
        } else {
          _pageExists[i] = false;
        }
      } else {
        _pageExists[i] = false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (existingCount == 604) {
      await prefs.setBool('mushaf_fully_downloaded', true);
      setState(() => _mushafFullyDownloaded = true);
    } else {
      await prefs.setBool('mushaf_fully_downloaded', false);
      setState(() => _mushafFullyDownloaded = false);
    }
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      final newPage = (_pageController.page! + 1).toInt();
      if (newPage != _currentPage) {
        setState(() => _currentPage = newPage);
        _updatePageInfo(newPage);
        _saveLastPage(newPage);
      }
    }
  }

  void _onAdaptiveScrollChanged() {
    if (!_adaptiveScrollController.hasClients || _allAyahs.isEmpty) return;

    final scrollPosition = _adaptiveScrollController.offset;
    final settings = context.read<SettingsProvider>();
    final hasTranslation = settings.quranTranslationLang != 'none';

    // Sync with _estimateScrollPosition factors for consistency
    double ayahTextFactor = 1.2;
    double avgHeight = settings.quranFontSize * (hasTranslation ? 8.0 : 4.5) * ayahTextFactor;

    int approximateAyahIndex = (scrollPosition / avgHeight).floor().clamp(0, _allAyahs.length - 1);

    if (approximateAyahIndex >= 0 && approximateAyahIndex < _allAyahs.length) {
      final visibleAyah = _allAyahs[approximateAyahIndex];

      // Find the surah for this ayah
      final surah = _allSurahs.firstWhere(
        (s) => s.ayahs?.any((a) => a.number == visibleAyah.number) ?? false,
        orElse: () => _allSurahs.first,
      );

      final newPage = visibleAyah.page;
      // Save last page when it changes
      if (newPage != _currentPage) {
        _saveLastPage(newPage);
      }
      setState(() {
        _currentSurahName = surah.nameArabic;
        _currentJuz = visibleAyah.juz;
        _currentPage = newPage;
      });
    }
  }

  Future<void> _loadQuran() async {
    try {
      final surahs = await QuranService.getQuran();
      // بناء الـ cache كله مرة واحدة
      for (final surah in surahs) {
        if (surah.ayahs == null) continue;
        _surahByNumber[surah.number] = surah;
        for (final ayah in surah.ayahs!) {
          _pageCache.putIfAbsent(ayah.page, () => []).add(ayah);
          _surahNumberForAyahNumber[ayah.number] = surah.number;
        }
      }
      setState(() {
        _allSurahs = surahs;
        _allAyahs = surahs.expand((s) => s.ayahs ?? <Ayah>[]).toList();
        
        // ✅ Pre-initialize keys for EVERY ayah to ensure stable IDs for navigation
        for (var ayah in _allAyahs) {
          _ayahKeys[ayah.number] = GlobalKey(debugLabel: 'ayah_${ayah.number}');
        }
        for (var surah in _allSurahs) {
          _surahKeys[surah.number] = GlobalKey(debugLabel: 'surah_${surah.number}');
        }

        // Prefix-sum of surah headers before each index, so scroll-position
        // estimation during navigation is O(1) instead of re-scanning
        // everything on every jump.
        _headersBeforeIndex.clear();
        int headerCount = 0;
        for (final a in _allAyahs) {
          _headersBeforeIndex.add(headerCount);
          if (a.numberInSurah == 1) headerCount++;
        }

        _isLoading = false;
        if (surahs.isNotEmpty) _currentSurahName = surahs.first.nameArabic;
      });
      await _loadLastPage();
      // Load translations for initial page's surah after last page is loaded
      if (_pageCache[_currentPage] != null &&
          _pageCache[_currentPage]!.isNotEmpty) {
        final currentAyahs = _pageCache[_currentPage]!;
        final surah =
            _allSurahs.where((s) {
              return s.ayahs?.any(
                    (a) => a.number == currentAyahs.first.number,
                  ) ??
                  false;
            }).firstOrNull;
        if (surah != null) {
          await _loadEnglishTranslation(surah.number);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLastPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getInt('last_page');
      if (lastPage != null && lastPage > 1) {
        setState(() {
          _currentPage = lastPage;
          _showLastPageMessage = true;
        });

        final settings = context.read<SettingsProvider>();
        final currentLayoutMode =
            settings.quranLayoutMode == 'mushaf'
                ? QuranLayoutMode.mushaf
                : QuranLayoutMode.adaptive;

        if (currentLayoutMode == QuranLayoutMode.mushaf) {
          _pageController.jumpToPage(lastPage - 1);
        } else {
          // Adaptive mode: scroll to the first ayah of the last page
          _scrollToPageInAdaptive(lastPage);
        }
        _updatePageInfo(lastPage);
      }
    } catch (_) {}
  }

  Future<void> _saveLastPage(int pageNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_page', pageNumber);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();
    // If translation language changes, reload translations for current surah
    final currentAyahs = _pageCache[_currentPage];
    if (currentAyahs != null && currentAyahs.isNotEmpty) {
      final surah =
          _allSurahs.where((s) {
            return s.ayahs?.any((a) => a.number == currentAyahs.first.number) ??
                false;
          }).firstOrNull;
      if (surah != null) {
        _loadEnglishTranslation(surah.number);
      }
    }
  }

  void _updatePageInfo(int page) {
    final ayahs = _pageCache[page];
    if (ayahs == null || ayahs.isEmpty) return;
    // نبحث في الـ cache عن اسم السورة
    final surah =
        _allSurahs.where((s) {
          return s.ayahs?.any((a) => a.number == ayahs.first.number) ?? false;
        }).firstOrNull;
    setState(() {
      if (surah != null) {
        _currentSurahName = surah.nameArabic;
        _loadEnglishTranslation(
          surah.number,
        ); // Load translations for this surah
      }
      _currentJuz = ayahs.first.juz;
    });
  }

  Future<void> _navigateToAyah(int surahNumber, int ayahNumber) async {
    final settings = context.read<SettingsProvider>();
    final lang = settings.appLanguage;
    final currentLayoutMode =
        settings.quranLayoutMode == 'mushaf'
            ? QuranLayoutMode.mushaf
            : QuranLayoutMode.adaptive;
    try {
      final ayah = await QuranService.getAyah(surahNumber, ayahNumber);
      if (ayah != null) {
        if (currentLayoutMode == QuranLayoutMode.mushaf) {
          // Mushaf mode: navigate to page
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              ayah.page - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() => _currentPage = ayah.page);
          }
        } else {
          // Adaptive mode: scroll to ayah in list
          _scrollToAyahInAdaptive(ayah);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get(
                'error_message',
                lang,
                params: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  void _scrollToAyahInAdaptive(Ayah targetAyah) {
    if (!_adaptiveScrollController.hasClients || _allAyahs.isEmpty) return;

    final ayahIndex = _allAyahs.indexWhere((a) => a.number == targetAyah.number);
    if (ayahIndex < 0) return;

    // 1. Update UI state immediately
    final surahNumber = _surahNumberForAyahNumber[targetAyah.number];
    final surah = surahNumber == null
        ? _allSurahs.first
        : (_surahByNumber[surahNumber] ?? _allSurahs.first);

    setState(() {
      _currentPage = targetAyah.page;
      _currentJuz = targetAyah.juz;
      _currentSurahName = surah.nameArabic;
    });

    // 2. Exact navigation using the Ayah ID (GlobalKey)
    // We jump to a rough estimate first so ListView starts building the target area
    double estimate = _estimateScrollPosition(targetAyah.number);
    _adaptiveScrollController.jumpTo(
      estimate.clamp(0.0, _adaptiveScrollController.position.maxScrollExtent),
    );

    // 3. Repeatedly check for the key's context and snap to it precisely
    int attempts = 0;
    void snapToKey() {
      if (!mounted) return;
      
      final key = (targetAyah.numberInSurah == 1) 
          ? _surahKeys[surah.number] 
          : _ayahKeys[targetAyah.number];
      
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.1, // Put it near the top but not hidden by header
        );
      } else if (attempts < 15) {
        attempts++;
        // If not found, move the scroll slightly to force building more items
        if (attempts % 3 == 0) {
          double jumpDist = (attempts > 6) ? 800.0 : 400.0;
          _adaptiveScrollController.jumpTo(
            (estimate + jumpDist).clamp(0.0, _adaptiveScrollController.position.maxScrollExtent)
          );
        }
        Future.delayed(const Duration(milliseconds: 60), snapToKey);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => snapToKey());
    _saveLastPage(targetAyah.page);
  }

  double _estimateScrollPosition(int targetAyahNumber) {
    if (_allAyahs.isEmpty) return 0.0;

    final ayahIndex = _allAyahs.indexWhere((a) => a.number == targetAyahNumber);
    if (ayahIndex == -1) return 0.0;

    final settings = context.read<SettingsProvider>();
    final hasTranslation = settings.quranTranslationLang != 'none';

    // Refined estimation factors
    double ayahTextFactor = 1.2; // Extra height for text wrapping
    double avgAyahHeight = settings.quranFontSize * (hasTranslation ? 8.0 : 4.5) * ayahTextFactor;
    double headerHeight = 180.0;

    int headersCount = ayahIndex < _headersBeforeIndex.length
        ? _headersBeforeIndex[ayahIndex]
        : 0;

    return (ayahIndex * avgAyahHeight) + (headersCount * headerHeight);
  }

  void _navigateToPage(int pageNumber) {
    final settings = context.read<SettingsProvider>();
    final currentLayoutMode =
        settings.quranLayoutMode == 'mushaf'
            ? QuranLayoutMode.mushaf
            : QuranLayoutMode.adaptive;
    if (currentLayoutMode == QuranLayoutMode.mushaf) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          pageNumber - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Controller not attached yet, just update state
        setState(() => _currentPage = pageNumber);
      }
    } else {
      // Adaptive mode: scroll to first ayah of this page
      _scrollToPageInAdaptive(pageNumber);
    }
  }

  Future<void> _navigateToJuz(int juzNumber) async {
    final targetAyah = _allAyahs.firstWhere(
      (a) => a.juz == juzNumber,
      orElse: () => _allAyahs.first,
    );

    final settings = context.read<SettingsProvider>();
    if (settings.quranLayoutMode == 'mushaf') {
      _pageController.jumpToPage(targetAyah.page - 1);
    } else {
      _scrollToAyahInAdaptive(targetAyah);
    }
  }

  void _showLayoutSwitcher(SettingsProvider settings, String lang) {
    final currentLayoutMode =
        settings.quranLayoutMode == 'mushaf'
            ? QuranLayoutMode.mushaf
            : QuranLayoutMode.adaptive;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppStrings.get('choose_display_mode', lang),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0A00),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildLayoutOption(
                        currentLayoutMode,
                        QuranLayoutMode.mushaf,
                        AppStrings.get('mushaf', lang),
                        Icons.menu_book,
                        settings,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLayoutOption(
                        currentLayoutMode,
                        QuranLayoutMode.adaptive,
                        AppStrings.get('adaptive', lang),
                        Icons.format_align_right,
                        settings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLayoutOption(
    QuranLayoutMode currentLayoutMode,
    QuranLayoutMode mode,
    String label,
    IconData icon,
    SettingsProvider settings,
  ) {
    final isSelected = currentLayoutMode == mode;
    return GestureDetector(
      onTap: () async {
        final previousMode = currentLayoutMode;
        await settings.setQuranLayoutMode(mode.name);
        Navigator.pop(context);

        // Preserve position when switching layouts
        if (previousMode == QuranLayoutMode.mushaf &&
            mode == QuranLayoutMode.adaptive) {
          // Switching from Mushaf to Adaptive: scroll to first ayah of current page
          _scrollToPageInAdaptive(_currentPage);
        } else if (previousMode == QuranLayoutMode.adaptive &&
            mode == QuranLayoutMode.mushaf) {
          // Switching from Adaptive to Mushaf: jump to page of visible ayah
          _jumpToPageFromAdaptive();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF8B6914).withValues(alpha: 0.15)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF8B6914)
                    : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  isSelected
                      ? const Color(0xFF8B6914)
                      : Colors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.amiri(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? const Color(0xFF8B6914)
                        : const Color(0xFF1A0A00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToPageInAdaptive(int pageNumber) {
    final ayahs = _pageCache[pageNumber];
    if (ayahs == null || ayahs.isEmpty) return;
    _scrollToAyahInAdaptive(ayahs.first);
  }

  void _jumpToPageFromAdaptive() {
    if (!_adaptiveScrollController.hasClients || _allAyahs.isEmpty) return;
    
    final scrollPosition = _adaptiveScrollController.offset;
    final approximateAyahIndex = (scrollPosition / 180.0).floor().clamp(0, _allAyahs.length - 1);

    if (approximateAyahIndex >= 0 && approximateAyahIndex < _allAyahs.length) {
      final visibleAyah = _allAyahs[approximateAyahIndex];
      _pageController.jumpToPage(visibleAyah.page - 1);
      setState(() {
        _currentPage = visibleAyah.page;
      });
      _updatePageInfo(visibleAyah.page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.appLanguage;
    final currentLayoutMode =
        settings.quranLayoutMode == 'mushaf'
            ? QuranLayoutMode.mushaf
            : QuranLayoutMode.adaptive;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF8F0),
          elevation: 0,
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF8B6914)),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
          title: Text(
            AppStrings.get('holy_quran', lang),
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8B6914),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _bookmarkedPage == _currentPage ? Icons.bookmark : Icons.bookmark_border,
                color: const Color(0xFF8B6914),
              ),
              onPressed: _saveBookmark,
              tooltip: AppStrings.get('save_bookmark', lang),
            ),
            if (_bookmarkedPage != null)
              IconButton(
                icon: const Icon(Icons.bookmark_added, color: Color(0xFF8B6914)),
                onPressed: _goToBookmark,
                tooltip: AppStrings.get('go_to_bookmark', lang),
              ),
            IconButton(
              icon: const Icon(Icons.menu_book_outlined, color: Color(0xFF8B6914)),
              tooltip: AppStrings.get('tafsir', lang),
              onPressed: () {
                final ayahsOnPage = _pageCache[_currentPage];
                if (ayahsOnPage == null || ayahsOnPage.isEmpty) return;
                final firstAyah = ayahsOnPage.first;
                final surahNumber = _surahNumberForAyahNumber[firstAyah.number];
                if (surahNumber == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TafsirScreen(
                      surahNumber: surahNumber,
                      ayahNumber: firstAyah.numberInSurah,
                      surahName: _surahByNumber[surahNumber]?.nameArabic,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.view_module, color: Color(0xFF8B6914)),
              onPressed: () => _showLayoutSwitcher(settings, lang),
              tooltip: AppStrings.get('change_display_mode', lang),
            ),
          ],
        ),
        endDrawer: QuranSidebar(
          onNavigateToAyah: _navigateToAyah,
          onNavigateToPage: _navigateToPage,
          onNavigateToJuz: _navigateToJuz,
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView(lang)
                : currentLayoutMode == QuranLayoutMode.mushaf
                ? _buildMushafView(lang)
                : _buildAdaptiveView(settings, lang),
      ),
    );
  }

  Widget _buildErrorView(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '${AppStrings.get('error_occurred', lang)}: $_errorMessage',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadQuran,
            child: Text(AppStrings.get('retry', lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMessage(String lang) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B6914).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android_outlined, size: 64, color: Color(0xFF8B6914)),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('mushaf_only_mobile', lang),
              style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('use_adaptive_web', lang),
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafView(String lang) {
    return Stack(
      children: [
        // Mushaf Mode with local images
        PageView.builder(
          controller: _pageController,
          itemCount: 604,
          reverse: true, // RTL: swipe right = next page
          itemBuilder:
              (context, index) => _buildMushafImagePage(index + 1, lang),
        ),

        // شريط المعلومات
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF8B6914).withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.get(
                    'juz',
                    lang,
                    params: {'number': _currentJuz.toString()},
                  ),
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                  ),
                ),
                Text(
                  '$_currentPage',
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 13,
                    color: Color(0xFF8B6914),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentSurahName,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                  ),
                ),
              ],
            ),
          ),
        ),

        // رسالة آخر صفحة
        if (_showLastPageMessage)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6914).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.get(
                        'continue_from_page',
                        lang,
                        params: {'page': _currentPage.toString()},
                      ),
                      style: const TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showLastPageMessage = false),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadMushaf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final quranDir = Directory('${appDocDir.path}/quran_pages');
      if (!await quranDir.exists()) {
        await quranDir.create(recursive: true);
      }

      int successfullyDownloaded = 0;
      List<int> pagesToDownload = [];

      // 1. Identify which pages are TRULY missing or broken
      for (int i = 1; i <= 604; i++) {
        final f = File('${quranDir.path}/page_$i.png');
        bool isValid = false;
        try {
          if (f.existsSync()) {
            final size = f.lengthSync();
            // Reject files that are too small (likely error pages)
            if (size > 30000) {
              isValid = true;
            } else {
              // Delete broken file immediately to allow re-download
              f.deleteSync();
            }
          }
        } catch (_) {}

        if (isValid) {
          successfullyDownloaded++;
          _pageExists[i] = true;
        } else {
          _pageExists[i] = false;
          pagesToDownload.add(i);
        }
      }

      setState(() {
        _downloadProgress = successfullyDownloaded / 604;
      });

      if (pagesToDownload.isEmpty) {
        _finishDownload(604);
        return;
      }

      // 2. Download missing pages
      const int batchSize = 4; // Slightly smaller batch for stability
      for (int i = 0; i < pagesToDownload.length; i += batchSize) {
        if (!mounted || !_isDownloading) break;

        final currentBatch = pagesToDownload.sublist(
          i, 
          (i + batchSize > pagesToDownload.length) ? pagesToDownload.length : i + batchSize
        );

        final List<Future<bool>> batchFutures = currentBatch.map((pageNum) {
          return QuranService.downloadPage(pageNum, (_) {});
        }).toList();

        final List<bool> results = await Future.wait(batchFutures);
        
        bool anyNewSuccess = false;
        for (int j = 0; j < results.length; j++) {
          if (results[j]) {
            successfullyDownloaded++;
            _pageExists[currentBatch[j]] = true;
            anyNewSuccess = true;
          }
        }

        if (mounted) {
          setState(() {
            _downloadProgress = (successfullyDownloaded / 604).clamp(0.0, 1.0);
          });
        }
        
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      _finishDownload(successfullyDownloaded);
    } catch (e) {
      debugPrint('Download error: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _finishDownload(int count) async {
    final prefs = await SharedPreferences.getInstance();
    if (count == 604) {
      await prefs.setBool('mushaf_fully_downloaded', true);
      setState(() => _mushafFullyDownloaded = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل المصحف بالكامل بنجاح')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل $count صفحة من أصل 604. يمكنك المحاولة مرة أخرى لاحقاً.')),
        );
      }
    }
  }

  Widget _buildMushafImagePage(int pageNumber, String lang) {
    // Guard for web platform
    if (kIsWeb) {
      return _buildWebMessage(lang);
    }

    if (_mushafImagesPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final imagePath = '$_mushafImagesPath/page_$pageNumber.png';
    final imageFile = File(imagePath);
    
    // DIRECT CHECK: If file exists and isn't empty, SHOW IT. 
    // We use a safe check here because lengthSync might be problematic if file is partially written
    bool exists = false;
    try {
       exists = imageFile.existsSync() && imageFile.lengthSync() > 5000;
    } catch (_) {}

    if (exists) {
      return Container(
        color: const Color(0xFFFFFEF5),
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          // We use a key that includes the file size to force a reload if the file changes
          key: ValueKey('page_${pageNumber}_${imageFile.lengthSync()}'),
          errorBuilder: (context, error, stackTrace) => _buildRetryView(pageNumber, imageFile, lang),
        ),
      );
    }

    // If file doesn't exist, show download prompt
    return _buildDownloadPrompt(pageNumber, lang);
  }

  Widget _buildDownloadPrompt(int pageNumber, String lang) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B6914).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDownloading)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل المصحف... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.cairo(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر الصفحة تلقائياً عند وصول التحميل إليها',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _downloadMushaf,
                child: Column(
                  children: [
                    const Icon(Icons.download_outlined, size: 64, color: Color(0xFF8B6914)),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.get('tap_to_download_mushaf', lang),
                      style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('page_number', lang, params: {'page': pageNumber.toString()}),
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryView(int pageNumber, File file, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(AppStrings.get('error_loading_image', lang)),
          const SizedBox(height: 8),
          Text(
            'حجم الملف: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Clear from Flutter image cache
                await FileImage(file).evict();
                if (await file.exists()) await file.delete();
                
                setState(() {
                  _pageExists[pageNumber] = false;
                  _isDownloading = true; // Show loading immediately
                });
                
                // Small delay to ensure disk is ready
                await Future.delayed(const Duration(milliseconds: 300));
                
                _downloadMushaf();
              } catch (e) {
                debugPrint('Retry error: $e');
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppStrings.get('retry_download', lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6914),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveView(SettingsProvider settings, String lang) {
    if (_allAyahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download_outlined, size: 64, color: Color(0xFF8B6914)),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('quran_text_not_downloaded', lang),
              style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('tap_to_download_text', lang),
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQuran,
              icon: const Icon(Icons.download),
              label: Text(AppStrings.get('download_now', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Scrollable list of ayahs
        ListView.builder(
          controller: _adaptiveScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _allAyahs.length,
          cacheExtent: 2000,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final ayah = _allAyahs[index];
            final isSurahStart = ayah.numberInSurah == 1;

            return RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isSurahStart) _buildAdaptiveSurahHeader(ayah),
                  _buildAdaptiveAyahRow(ayah, settings),
                  if (index < _allAyahs.length - 1) const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),

        // شريط المعلومات
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF8B6914).withValues(alpha: 0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.get(
                    'juz',
                    lang,
                    params: {'number': _currentJuz.toString()},
                  ),
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                  ),
                ),
                Text(
                  '$_currentPage',
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 13,
                    color: Color(0xFF8B6914),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentSurahName,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 12,
                    color: Color(0xFF8B6914),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveSurahHeader(Ayah ayah) {
    final lang = context.watch<SettingsProvider>().appLanguage;

    // Find the surah for this ayah (O(1) via prebuilt index)
    final surahNumber = _surahNumberForAyahNumber[ayah.number];
    final surah = surahNumber == null ? null : _surahByNumber[surahNumber];
    if (surah == null) return const SizedBox.shrink();

    final title =
        lang == 'ar'
            ? '${AppStrings.get('surah_prefix', lang)} ${surah.nameArabic}'
            : '${AppStrings.get('surah_prefix', lang)} ${surah.nameEnglish}';
    return Container(
      key: _surahKeys[surah.number],
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6914).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B6914).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B6914),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.get(
              'surah_info',
              lang,
              params: {
                'type': AppStrings.get(
                  surah.revelationType == 'Meccan' ? 'meccan' : 'medinan',
                  lang,
                ),
                'count': surah.ayahCount.toString(),
                'plural': surah.ayahCount == 1 ? '' : 's',
              },
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveAyahRow(Ayah ayah, SettingsProvider settings) {
    final translationLang = settings.quranTranslationLang;
    final lang = settings.appLanguage;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        key: _ayahKeys[ayah.number],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF8B6914).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: ayah.text,
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: settings.quranFontSize,
                      height: 2.0,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B6914),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${AppStrings.get('ayah_number_prefix', lang)}${_toArabicNumerals(ayah.numberInSurah)}${AppStrings.get('ayah_number_suffix', lang)}',
                          style: const TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (translationLang != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child:
                    _translationLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          _translationCache[ayah.numberInSurah] ?? '',
                          style: TextStyle(
                            fontSize: settings.quranFontSize * 0.65,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          textAlign:
                              translationLang == 'ar'
                                  ? TextAlign.right
                                  : TextAlign.left,
                          textDirection:
                              translationLang == 'ar'
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                        ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final surahNumber = _surahNumberForAyahNumber[ayah.number];
                  if (surahNumber == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TafsirScreen(
                        surahNumber: surahNumber,
                        ayahNumber: ayah.numberInSurah,
                        surahName: _surahByNumber[surahNumber]?.nameArabic,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_outlined, size: 16),
                label: Text(
                  AppStrings.get('tafsir', lang),
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicNumerals(int number) {
    const n = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => n[int.parse(d)]).join();
  }
}

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

enum QuranLayoutMode { mushaf, adaptive }

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

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

  final Map<int, String> _translationCache = {};
  bool _translationLoading = false;

  // ✅ FIX 1: Cache كل الآيات في الذاكرة — مفيش reload
  final Map<int, List<Ayah>> _pageCache = {};
  final Map<int, bool> _pageExists = {};
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
    _loadQuran();
    _pageController.addListener(_onPageChanged);
    _adaptiveScrollController.addListener(_onAdaptiveScrollChanged);
    _getMushafImagesPath();
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
        if (size > 1000) {
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

    // Improved estimation for current ayah/page tracking
    double avgHeight = settings.quranFontSize * (hasTranslation ? 9.0 : 5.0);
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
        for (final ayah in surah.ayahs!) {
          _pageCache.putIfAbsent(ayah.page, () => []).add(ayah);
        }
      }
      setState(() {
        _allSurahs = surahs;
        _allAyahs = surahs.expand((s) => s.ayahs ?? <Ayah>[]).toList();
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
    if (ayahIndex >= 0) {
      final isSurahStart = targetAyah.numberInSurah == 1;
      GlobalKey? targetKey;

      if (isSurahStart) {
        final surah = _allSurahs.firstWhere(
          (s) => s.ayahs?.any((a) => a.number == targetAyah.number) ?? false,
          orElse: () => _allSurahs.first,
        );
        targetKey = _surahKeys[surah.number];
      } else {
        targetKey = _ayahKeys.putIfAbsent(targetAyah.number, () => GlobalKey());
      }

      // 1. Calculate a high-precision estimate
      final targetScrollPos = _estimateScrollPosition(targetAyah.number);

      // 2. Perform a fast jump to the estimated position
      _adaptiveScrollController.jumpTo(
        targetScrollPos.clamp(
          0.0,
          _adaptiveScrollController.position.maxScrollExtent,
        ),
      );

      // 3. Precise adjustment after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey!.currentContext!,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  double _estimateScrollPosition(int targetAyahNumber) {
    if (_allAyahs.isEmpty) return 0.0;

    final ayahIndex = _allAyahs.indexWhere((a) => a.number == targetAyahNumber);
    if (ayahIndex == -1) return 0.0;

    final settings = context.read<SettingsProvider>();
    final hasTranslation = settings.quranTranslationLang != 'none';

    // Precision values for estimation
    // For font size 22: Arabic ~110px, Translation ~210px
    double factor = hasTranslation ? 9.5 : 5.0;
    double avgAyahHeight = settings.quranFontSize * factor;
    double headerHeight = 160.0;

    int headersCount = 0;
    for (int i = 0; i < ayahIndex; i++) {
      if (_allAyahs[i].numberInSurah == 1) {
        headersCount++;
      }
    }

    // Baseline position
    double pos = (ayahIndex * avgAyahHeight) + (headersCount * headerHeight);

    // Adjust for very long surahs or specific parts if needed, 
    // but a linear estimate with headers is usually sufficient for a jump
    return pos;
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

      for (int i = 1; i <= 604; i++) {
        final imagePath = '${quranDir.path}/page_$i.png';
        final imageFile = File(imagePath);
        
        // Only download if file doesn't exist or is too small (corrupted)
        if (await imageFile.exists() && await imageFile.length() > 1000) {
          _pageExists[i] = true;
          setState(() {
            _downloadProgress = i / 604;
          });
          continue;
        }
        
        await QuranService.downloadPage(i, (progress) {});
        
        setState(() {
          _downloadProgress = i / 604;
          _pageExists[i] = true;
        });
      }
      
      // Verification
      int existingCount = 0;
      for (int i = 1; i <= 604; i++) {
        final imagePath = '${quranDir.path}/page_$i.png';
        if (await File(imagePath).exists()) existingCount++;
      }

      if (existingCount == 604) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('mushaf_fully_downloaded', true);
        setState(() {
          _mushafFullyDownloaded = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحميل المصحف بنجاح')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التحميل: $e')),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Widget _buildMushafImagePage(int pageNumber, String lang) {
    // Guard for web platform
    if (kIsWeb) {
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
              const Icon(
                Icons.phone_android_outlined,
                size: 64,
                color: Color(0xFF8B6914),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('mushaf_only_mobile', lang),
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A0A00),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('use_adaptive_web', lang),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final imagePath = '$_mushafImagesPath/page_$pageNumber.png';
    final imageFile = File(imagePath);
    bool pageExists = _pageExists[pageNumber] ?? false;

    // Fast path: if fully downloaded flag is set, skip heavy file checks
    if (_mushafFullyDownloaded) {
      if (kIsWeb) {
        pageExists = true;
      } else {
        // Double check specific file exists even if flag is true, to catch deletions
        if (!imageFile.existsSync()) {
          pageExists = false;
        } else {
          pageExists = true;
        }
      }
    } else if (pageExists && !kIsWeb && !imageFile.existsSync()) {
      pageExists = false;
    }

    if (!pageExists) {
      // Show download prompt if image not found
      return Center(
        child: GestureDetector(
          onTap: _downloadMushaf,
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
                      CircularProgressIndicator(value: _downloadProgress),
                      const SizedBox(height: 16),
                      Text(
                        'جاري التحميل... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: const Color(0xFF8B6914),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('tap_to_download_mushaf', lang),
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A0A00),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get(
                    'page_number',
                    lang,
                    params: {'page': pageNumber.toString()},
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Display the image
    return Container(
      color: const Color(0xFFFFFEF5),
      child: Image.file(
        imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('error_loading_image', lang),
                  style: GoogleFonts.cairo(),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('mushaf_fully_downloaded', false);
                    setState(() {
                      _mushafFullyDownloaded = false;
                      // Reset all page existence to force a full re-scan/re-download of missing parts
                      _pageExists.clear();
                    });
                    _downloadMushaf();
                  },
                  child: Text(AppStrings.get('retry_download', lang)),
                ),
              ],
            ),
          );
        },
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
          cacheExtent: 3000, // Pre-build items for smoother navigation
          itemCount: _allAyahs.length,
          itemBuilder: (context, index) {
            final ayah = _allAyahs[index];
            final isSurahStart = ayah.numberInSurah == 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSurahStart) _buildAdaptiveSurahHeader(ayah),
                _buildAdaptiveAyahRow(ayah, settings),
                if (index < _allAyahs.length - 1) const SizedBox(height: 12),
              ],
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

    // Find the surah for this ayah
    Surah? surah;
    for (final s in _allSurahs) {
      if (s.ayahs?.any((a) => a.number == ayah.number) ?? false) {
        surah = s;
        break;
      }
    }
    if (surah == null) return const SizedBox.shrink();

    final title =
        lang == 'ar'
            ? '${AppStrings.get('surah_prefix', lang)} ${surah.nameArabic}'
            : '${AppStrings.get('surah_prefix', lang)} ${surah.nameEnglish}';
    return Container(
      key: _surahKeys.putIfAbsent(surah.number, () => GlobalKey()),
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
        key: _ayahKeys.putIfAbsent(ayah.number, () => GlobalKey()),
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

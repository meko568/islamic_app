import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../services/cloud_sync_service.dart';
import 'tafsir_screen.dart';

class QuranScreen extends StatefulWidget {
  final int? initialSurahNumber;
  const QuranScreen({super.key, this.initialSurahNumber});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late PageController _pageController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  String _currentSurahName = '';
  int _currentJuz = 1;
  String? _mushafImagesPath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int? _bookmarkedPage;

  final Map<int, String> _translationCache = {};
  bool _translationLoading = false;

  final Map<int, List<Ayah>> _pageCache = {};
  final Map<int, bool> _pageExists = {};
  final Map<int, int> _surahNumberForAyahNumber = {};
  final Map<int, Surah> _surahByNumber = {};
  bool _mushafFullyDownloaded = false;
  List<Surah> _allSurahs = [];
  List<Ayah> _allAyahs = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadQuran().then((_) {
      if (widget.initialSurahNumber != null && mounted) {
        _navigateToAyah(widget.initialSurahNumber!, 1);
      }
    });
    _pageController.addListener(_onPageChanged);
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
      
      // Sync to cloud
      final uid = FirebaseAuth.instance.currentUser?.uid;
      CloudSyncService().pushOnDataChange(uid);
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
    _pageController.dispose();
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

      await _checkPageExistence();
    } catch (_) {}
  }

  Future<void> _checkPageExistence() async {
    if (_mushafImagesPath == null) return;
    
    int existingCount = 0;
    for (int i = 1; i <= 604; i++) {
      final imagePath = '$_mushafImagesPath/page_$i.png';
      final imageFile = File(imagePath);
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

  Future<void> _loadQuran() async {
    try {
      final surahs = await QuranService.getQuran();
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
        _isLoading = false;
        if (surahs.isNotEmpty) _currentSurahName = surahs.first.nameArabic;
      });
      await _loadLastPage();
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
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(lastPage - 1);
        }
        _updatePageInfo(lastPage);
      }
    } catch (_) {}
  }

  Future<void> _saveLastPage(int pageNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_page', pageNumber);
      
      // Sync to cloud (debounced)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      CloudSyncService().pushOnDataChange(uid);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final surah =
        _allSurahs.where((s) {
          return s.ayahs?.any((a) => a.number == ayahs.first.number) ?? false;
        }).firstOrNull;
    setState(() {
      if (surah != null) {
        _currentSurahName = surah.nameArabic;
        _loadEnglishTranslation(
          surah.number,
        );
      }
      _currentJuz = ayahs.first.juz;
    });
  }

  Future<void> _navigateToAyah(int surahNumber, int ayahNumber) async {
    final settings = context.read<SettingsProvider>();
    final lang = settings.appLanguage;
    try {
      final ayah = await QuranService.getAyah(surahNumber, ayahNumber);
      if (ayah != null) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            ayah.page - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          setState(() => _currentPage = ayah.page);
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

  void _navigateToPage(int pageNumber) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _currentPage = pageNumber);
    }
  }

  Future<void> _navigateToJuz(int juzNumber) async {
    final targetAyah = _allAyahs.firstWhere(
      (a) => a.juz == juzNumber,
      orElse: () => _allAyahs.first,
    );

    if (_pageController.hasClients) {
      _pageController.jumpToPage(targetAyah.page - 1);
    } else {
      setState(() => _currentPage = targetAyah.page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.appLanguage;

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
                      ayahsOnPage: ayahsOnPage,
                    ),
                  ),
                );
              },
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
                : _buildMushafView(lang),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMushafView(String lang) {
    return Stack(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 604,
            reverse: false,
            itemBuilder:
                (context, index) => _buildMushafImagePage(index + 1, lang),
          ),
        ),

        // Info bar
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

      for (int i = 1; i <= 604; i++) {
        final f = File('${quranDir.path}/page_$i.png');
        bool isValid = false;
        try {
          if (f.existsSync()) {
            final size = f.lengthSync();
            if (size > 30000) {
              isValid = true;
            } else {
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

      const int batchSize = 4;
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
    if (kIsWeb) {
      return _buildWebMessage(lang);
    }

    if (_mushafImagesPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final imagePath = '$_mushafImagesPath/page_$pageNumber.png';
    final imageFile = File(imagePath);
    
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
          key: ValueKey('page_${pageNumber}_${imageFile.lengthSync()}'),
          errorBuilder: (context, error, stackTrace) => _buildRetryView(pageNumber, imageFile, lang),
        ),
      );
    }

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
                await FileImage(file).evict();
                if (await file.exists()) await file.delete();
                
                setState(() {
                  _pageExists[pageNumber] = false;
                  _isDownloading = true;
                });
                
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
}

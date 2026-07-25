import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/surah_model.dart';
import '../providers/settings_provider.dart';
import '../services/quran_service.dart';
import '../services/tafsir_service.dart';
import '../theme/app_theme.dart';

class TafsirScreen extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber; // initial ayah number within the surah
  final String? surahName;
  final List<Ayah>? ayahsOnPage;

  const TafsirScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
    this.ayahsOnPage,
  });

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  final Map<int, String?> _tafsirCache = {};
  final Map<int, bool> _loadingMap = {};
  final Map<int, bool> _failedMap = {};
  late List<Ayah> _ayahs;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _ayahs = widget.ayahsOnPage ?? [];
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 400 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });

    if (_ayahs.isEmpty) {
      _loadSingleAyah();
    } else {
      for (var ayah in _ayahs) {
        _ayahKeys[ayah.numberInSurah] = GlobalKey();
        _loadTafsirForAyah(ayah.numberInSurah);
      }
      
      // Scroll to initial ayah
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(widget.ayahNumber);
      });
    }
  }

  Future<void> _loadSingleAyah() async {
    try {
      final ayah = await QuranService.getAyah(widget.surahNumber, widget.ayahNumber);
      if (ayah != null && mounted) {
        setState(() {
          _ayahs = [ayah];
          _ayahKeys[ayah.numberInSurah] = GlobalKey();
        });
        _loadTafsirForAyah(ayah.numberInSurah);
      }
    } catch (_) {}
  }

  Future<void> _loadTafsirForAyah(int ayahNumber) async {
    if (_tafsirCache.containsKey(ayahNumber) && !_failedMap.containsKey(ayahNumber)) return;

    setState(() {
      _loadingMap[ayahNumber] = true;
      _failedMap.remove(ayahNumber);
    });

    try {
      final tafsir = await TafsirService.getTafsir(widget.surahNumber, ayahNumber);
      if (!mounted) return;
      setState(() {
        _tafsirCache[ayahNumber] = tafsir;
        _loadingMap[ayahNumber] = false;
        if (tafsir == null) _failedMap[ayahNumber] = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMap[ayahNumber] = false;
        _failedMap[ayahNumber] = true;
      });
    }
  }

  void _scrollToAyah(int ayahNumber) {
    final key = _ayahKeys[ayahNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF8F0),
          elevation: 0,
          title: Text(
            '${AppStrings.get('tafsir', lang)}${widget.surahName != null ? ' - ${widget.surahName}' : ''}',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B6914),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8B6914)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: _showBackToTop
            ? FloatingActionButton(
                onPressed: () => _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut),
                backgroundColor: const Color(0xFF8B6914),
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
            : null,
        body: _ayahs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = _ayahs[index];
                  return _buildAyahCard(ayah, lang, index);
                },
              ),
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah, String lang, int index) {
    final tafsir = _tafsirCache[ayah.numberInSurah];
    final isLoading = _loadingMap[ayah.numberInSurah] ?? false;
    final isFailed = _failedMap[ayah.numberInSurah] ?? false;

    return Container(
      key: _ayahKeys[ayah.numberInSurah],
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6914).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Ayah Number and Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B6914).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.get('ayah', lang)} ${ayah.numberInSurah}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B6914),
                  ),
                ),
                Row(
                  children: [
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF8B6914)),
                        onPressed: () => _scrollToAyah(_ayahs[index - 1].numberInSurah),
                        tooltip: 'الآية السابقة',
                      ),
                    if (index < _ayahs.length - 1)
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B6914)),
                        onPressed: () => _scrollToAyah(_ayahs[index + 1].numberInSurah),
                        tooltip: 'الآية التالية',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 22,
                    height: 1.8,
                    color: Color(0xFF1A0A00),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFF8B6914)),
                    ),
                  )
                else if (isFailed)
                  Center(
                    child: Column(
                      children: [
                        Text(AppStrings.get('tafsir_load_failed', lang)),
                        TextButton.icon(
                          onPressed: () => _loadTafsirForAyah(ayah.numberInSurah),
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.get('retry', lang)),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    tafsir ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

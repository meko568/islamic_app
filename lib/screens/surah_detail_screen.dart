import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;

  const SurahDetailScreen({super.key, required this.surahNumber});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  Surah? _surah;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    try {
      final surah = await QuranService.getSurah(widget.surahNumber);
      setState(() {
        _surah = surah;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B6914),
          foregroundColor: Colors.white,
          title: Text(
            _surah == null
                ? AppStrings.get('loading', lang)
                : (lang == 'ar' ? _surah!.nameArabic : _surah!.nameEnglish),
            style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 20),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Text(
                    '${AppStrings.get('error_occurred', lang)}: $_error',
                  ),
                )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final surah = _surah!;
    final ayahs = surah.ayahs ?? [];
    final isShort = ayahs.length <= 7;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF8B6914).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF8B6914).withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: isShort ? _buildShortSurah(ayahs) : _buildLongSurah(ayahs),
      ),
    );
  }

  // ✅ سورة قصيرة زي الفاتحة — في المنتصف مع زخرفة
  Widget _buildShortSurah(List<Ayah> ayahs) {
    return Column(
      children: [
        _buildOrnament(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildAyahsFlow(ayahs),
            ],
          ),
        ),
        const Spacer(),
        _buildOrnament(),
      ],
    );
  }

  // ✅ سورة طويلة — scroll عادي
  Widget _buildLongSurah(List<Ayah> ayahs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildAyahsFlow(ayahs),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final lang = context.watch<SettingsProvider>().appLanguage;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6914).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF8B6914).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            lang == 'ar'
                ? '${AppStrings.get('surah_prefix', lang)} ${_surah!.nameArabic}'
                : '${AppStrings.get('surah_prefix', lang)} ${_surah!.nameEnglish}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 24,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.get(
              'surah_info',
              lang,
              params: {
                'type': AppStrings.get(
                  _surah!.revelationType == 'Meccan' ? 'meccan' : 'medinan',
                  lang,
                ),
                'count': _surah!.ayahCount.toString(),
                'plural': _surah!.ayahCount == 1 ? '' : 's',
              },
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B6914)),
          ),
        ],
      ),
    );
  }

  // ✅ النص يتدفق مع بعض زي PDF — مفيش فراغات بين الآيات
  Widget _buildAyahsFlow(List<Ayah> ayahs) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        text: TextSpan(
          children: ayahs.map(_buildAyahSpan).expand((x) => x).toList(),
        ),
      ),
    );
  }

  List<InlineSpan> _buildAyahSpan(Ayah ayah) {
    final spans = <InlineSpan>[];
    final text = ayah.text;
    final pattern = RegExp(r'(الله|تالله|بالله)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: _textStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: _textStyle.copyWith(
            color: const Color(0xFFC0392B),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: _textStyle));
    }

    // رقم الآية مباشرة بعد النص
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildMarker(ayah.numberInSurah),
      ),
    );

    return spans;
  }

  static const TextStyle _textStyle = TextStyle(
    fontFamily: 'UthmanicHafs',
    fontSize: 22,
    height: 2.2,
    color: Color(0xFF1A0A00),
  );

  Widget _buildMarker(int n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF8B6914),
      ),
      child: Center(
        child: Text(
          _toArabic(n),
          style: const TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOrnament() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: const Color(0xFF8B6914).withValues(alpha: 0.4),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.star_outline,
              color: const Color(0xFF8B6914).withValues(alpha: 0.6),
              size: 18,
            ),
          ),
          Expanded(
            child: Divider(
              color: const Color(0xFF8B6914).withValues(alpha: 0.4),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _toArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}

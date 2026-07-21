import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../services/quran_service.dart';
import '../services/tafsir_service.dart';
import '../theme/app_theme.dart';

class TafsirScreen extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber; // number within the surah
  final String? surahName;

  const TafsirScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName,
  });

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  String? _ayahText;
  String? _tafsirText;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final ayah = await QuranService.getAyah(
        widget.surahNumber,
        widget.ayahNumber,
      );
      final tafsir = await TafsirService.getTafsir(
        widget.surahNumber,
        widget.ayahNumber,
      );
      if (!mounted) return;
      setState(() {
        _ayahText = ayah?.text;
        _tafsirText = tafsir;
        _loading = false;
        _failed = tafsir == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${AppStrings.get('tafsir', lang)}'
            '${widget.surahName != null ? ' - ${widget.surahName}' : ''}',
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_ayahText != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _ayahText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 22,
                              height: 1.9,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.get('tafsir', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_failed)
                        Text(
                          AppStrings.get('tafsir_load_failed', lang),
                          style: TextStyle(color: AppColors.secondaryText),
                        )
                      else
                        Text(
                          _tafsirText ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 15.5,
                            height: 1.8,
                          ),
                        ),
                      if (_failed) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.get('retry', lang)),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

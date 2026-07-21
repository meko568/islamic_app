import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/target_provider.dart';
import '../services/stats_service.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  // Preset Azkar/Tasbeeh phrases
  static const List<String> _presetPhrases = [
    'اللهم صل على محمد',
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'لا حول ولا قوة إلا بالله',
    'لَا إلَه إلّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'توكلنا على الله',
    'إنا لله وإنا إليه راجعون',
    'أسماء الله الحسنى',
    'سبحان الله وبحمده سبحان الله العظيم',
    'أستغفر الله العظيم',
    'حسبنا الله ونعم الوكيل',
  ];

  String _selectedPhrase = _presetPhrases[1]; // Default: سبحان الله
  // Store counters for each phrase: Map<phrase, {mainCounter, roundCounter}>
  final Map<String, Map<String, int>> _phraseCounters = {};

  // Custom tasbeeh items
  final List<String> _customPhrases = [];
  final TextEditingController _customPhraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCounters();
    _loadCustomPhrases();
  }

  @override
  void dispose() {
    _customPhraseController.dispose();
    super.dispose();
  }

  // Get counter for current phrase
  Map<String, int> _getCurrentCounters() {
    final phrase = _currentPhrase;
    if (!_phraseCounters.containsKey(phrase)) {
      _phraseCounters[phrase] = {'main': 100, 'round': 0};
    }
    return _phraseCounters[phrase]!;
  }

  // Get main counter for current phrase
  int get _mainCounter => _getCurrentCounters()['main'] ?? 100;

  // Get round counter for current phrase
  int get _roundCounter => _getCurrentCounters()['round'] ?? 0;

  // Set main counter for current phrase
  void _setMainCounter(int value) {
    final phrase = _currentPhrase;
    if (!_phraseCounters.containsKey(phrase)) {
      _phraseCounters[phrase] = {'main': 100, 'round': 0};
    }
    _phraseCounters[phrase]!['main'] = value;
  }

  // Set round counter for current phrase
  void _setRoundCounter(int value) {
    final phrase = _currentPhrase;
    if (!_phraseCounters.containsKey(phrase)) {
      _phraseCounters[phrase] = {'main': 100, 'round': 0};
    }
    _phraseCounters[phrase]!['round'] = value;
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPhrase =
          prefs.getString('tasbeeh_selected_phrase') ?? _presetPhrases[1];

      // Load counters for each preset phrase
      for (var phrase in _presetPhrases) {
        final mainCounter = prefs.getInt('tasbeeh_${phrase}_main') ?? 100;
        final roundCounter = prefs.getInt('tasbeeh_${phrase}_round') ?? 0;
        _phraseCounters[phrase] = {'main': mainCounter, 'round': roundCounter};
      }
    });
  }

  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasbeeh_selected_phrase', _selectedPhrase);

    // Save counters for all phrases
    for (var entry in _phraseCounters.entries) {
      final phrase = entry.key;
      final counters = entry.value;
      if (_presetPhrases.contains(phrase) || _customPhrases.contains(phrase)) {
        await prefs.setInt('tasbeeh_${phrase}_main', counters['main'] ?? 100);
        await prefs.setInt('tasbeeh_${phrase}_round', counters['round'] ?? 0);
      }
    }
  }

  Future<void> _loadCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final customPhrasesJson = prefs.getString('tasbeeh_custom_phrases');

    if (customPhrasesJson != null) {
      try {
        final decoded = jsonDecode(customPhrasesJson);
        if (decoded is List) {
          setState(() {
            _customPhrases.clear();
            _customPhrases.addAll(decoded.cast<String>());
          });
        }
      } catch (e) {
        // Ignore error
      }
    }
  }

  Future<void> _saveCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasbeeh_custom_phrases', jsonEncode(_customPhrases));
  }

  void _addCustomPhrase() {
    final text = _customPhraseController.text.trim();
    if (text.isNotEmpty && !_customPhrases.contains(text)) {
      setState(() {
        _customPhrases.add(text);
        _selectedPhrase = text;
        _phraseCounters[text] = {'main': 100, 'round': 0};
      });
      _customPhraseController.clear();
      _saveCustomPhrases();
      _saveCounters();
    }
  }

  void _removeCustomPhrase(String phrase) {
    setState(() {
      _customPhrases.remove(phrase);
      _phraseCounters.remove(phrase);
      if (_selectedPhrase == phrase) {
        _selectedPhrase = _presetPhrases[1];
      }
    });
    _saveCustomPhrases();
    _saveCounters();
  }

  List<String> get _allPhrases => [..._presetPhrases, ..._customPhrases];

  void _onCounterTap() {
    setState(() {
      int currentMain = _mainCounter;
      int currentRound = _roundCounter;

      currentMain--;

      if (currentMain <= 0) {
        currentMain = 100;
        currentRound++;
        HapticFeedback.mediumImpact();
      }

      _setMainCounter(currentMain);
      _setRoundCounter(currentRound);
    });
    _saveCounters();
    context.read<TargetProvider>().incrementAllByLinkType('tasbeeh');
    StatsService.incrementLifetimeTasbeeh();
  }

  void _showResetDialog() {
    final lang = context.read<SettingsProvider>().appLanguage;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.get('reset_counter', lang)),
          content: Text(AppStrings.get('sure_reset_counter', lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.get('no', lang)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _setMainCounter(100);
                  _setRoundCounter(0);
                });
                _saveCounters();
                Navigator.of(context).pop();
              },
              child: Text(AppStrings.get('yes', lang)),
            ),
          ],
        );
      },
    );
  }

  String get _currentPhrase => _selectedPhrase;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('tasbeeh', lang)),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Phrase selector (Horizontal scroll like flex)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _allPhrases.map((phrase) {
                      final isCustom = _customPhrases.contains(phrase);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: Text(
                                phrase,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _selectedPhrase == phrase,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPhrase = phrase;
                                });
                                _saveCounters();
                              },
                            ),
                            if (isCustom)
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => _removeCustomPhrase(phrase),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Add custom phrase input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customPhraseController,
                        decoration: InputDecoration(
                          hintText:
                              lang == 'ar'
                                  ? 'أضف ذكر مخصص'
                                  : 'Add custom tasbeeh',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        textDirection: TextDirection.rtl,
                        onSubmitted: (_) => _addCustomPhrase(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomPhrase,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Selected phrase display
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentPhrase,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),

                const SizedBox(height: 48),

                // Circular counter display
                GestureDetector(
                  onTap: _onCounterTap,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_mainCounter',
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.get(
                            'rounds_count',
                            lang,
                            params: {'count': _roundCounter.toString()},
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Instructions
                Text(
                  AppStrings.get('tap_to_count', lang),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 16),

                // Reset button moved from navbar
                OutlinedButton.icon(
                  onPressed: _showResetDialog,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppStrings.get('reset_counter', lang)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

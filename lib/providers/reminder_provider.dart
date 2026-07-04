import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_settings.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderSettings _settings = ReminderSettings();
  static const String _settingsKey = 'reminder_settings';

  // Custom tasbeeh storage keys
  static const String _customTasbeehKey = 'custom_tasbeeh_list';
  static const String _customRepeatCountsKey = 'custom_repeat_counts';

  List<Map<String, dynamic>> _customTasbeehList = [];
  Map<String, int> _customRepeatCounts = {};

  ReminderSettings get settings => _settings;

  List<Map<String, dynamic>> get customTasbeehList => _customTasbeehList;

  // Get all available tasbeeh IDs (presets + custom)
  List<String> get allTasbeehIds {
    final presetIds = _getPresetTasbeehIds();
    final customIds = _customTasbeehList.map((t) => t['id'] as String).toList();
    return [...presetIds, ...customIds];
  }

  // Get tasbeeh text by ID
  String getTasbeehText(String id) {
    final custom = _customTasbeehList.firstWhere(
      (t) => t['id'] == id,
      orElse: () => {},
    );
    if (custom.isNotEmpty) {
      return custom['text'] as String;
    }
    return id; // For preset IDs, the ID is the text itself
  }

  // Get tasbeeh target count by ID
  int getTasbeehTargetCount(String id) {
    // Check if user has custom repeat count
    if (_customRepeatCounts.containsKey(id)) {
      return _customRepeatCounts[id]!;
    }

    final custom = _customTasbeehList.firstWhere(
      (t) => t['id'] == id,
      orElse: () => {},
    );
    if (custom.isNotEmpty) {
      return custom['targetCount'] as int;
    }
    return 100; // Default for presets
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      _settings = ReminderSettings.fromJsonString(settingsJson);
    }

    await _loadCustomTasbeehList();
    await _loadCustomRepeatCounts();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, _settings.toJsonString());
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    _settings = _settings.copyWith(enabled: enabled);
    await saveSettings();
  }

  Future<void> setInterval(int minutes) async {
    _settings = _settings.copyWith(intervalMinutes: minutes);
    await saveSettings();
  }

  Future<void> toggleTasbeehId(String id) async {
    final currentList = List<String>.from(
      _settings.selectedTasbeehIds.whereType<String>(),
    );
    if (currentList.contains(id)) {
      currentList.remove(id);
    } else {
      currentList.add(id);
    }
    _settings = _settings.copyWith(selectedTasbeehIds: currentList);
    await saveSettings();
  }

  Future<void> setAllowCloseAnytime(bool allow) async {
    _settings = _settings.copyWith(allowCloseAnytime: allow);
    await saveSettings();
  }

  // Custom tasbeeh management
  Future<void> _loadCustomTasbeehList() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getString(_customTasbeehKey);

    if (listJson != null) {
      try {
        final decoded = jsonDecode(listJson);
        if (decoded is List) {
          _customTasbeehList =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          _customTasbeehList = [];
        }
      } catch (e) {
        _customTasbeehList = [];
      }
    }
  }

  Future<void> _saveCustomTasbeehList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customTasbeehKey, jsonEncode(_customTasbeehList));
  }

  Future<void> _loadCustomRepeatCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_customRepeatCountsKey);

    if (countsJson != null) {
      try {
        final decoded = jsonDecode(countsJson);
        if (decoded is Map) {
          _customRepeatCounts = Map<String, int>.from(
            decoded.map((key, value) => MapEntry(key as String, value as int)),
          );
        }
      } catch (e) {
        _customRepeatCounts = {};
      }
    }
  }

  Future<void> _saveCustomRepeatCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customRepeatCountsKey,
      jsonEncode(_customRepeatCounts),
    );
  }

  Future<void> setCustomRepeatCount(String id, int count) async {
    _customRepeatCounts[id] = count;
    await _saveCustomRepeatCounts();
    notifyListeners();
  }

  Future<void> addCustomTasbeeh(String text, int targetCount) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _customTasbeehList.add({
      'id': id,
      'text': text,
      'targetCount': targetCount,
    });
    await _saveCustomTasbeehList();
    notifyListeners();
  }

  Future<void> removeCustomTasbeeh(String removedId) async {
    _customTasbeehList.removeWhere((t) => t['id'] == removedId);
    // Also remove from selected tasbeehs if present
    final newSelected =
        _settings.selectedTasbeehIds
            .where((selectedId) => selectedId != removedId)
            .toList();
    _settings = _settings.copyWith(selectedTasbeehIds: newSelected);
    await _saveCustomTasbeehList();
    await saveSettings();
  }

  // Preset tasbeeh IDs (matching the phrases in tasbeeh_screen.dart)
  List<String> _getPresetTasbeehIds() {
    return [
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
  }
}

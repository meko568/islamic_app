import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Settings keys
  static const String _themeModeKey = 'theme_mode';
  static const String _appLanguageKey = 'app_language';
  static const String _quranTranslationLangKey = 'quran_translation';
  static const String _appFontSizeKey = 'app_font_size';
  static const String _quranFontSizeKey = 'quran_font_size';
  static const String _quranLayoutModeKey = 'quran_layout_mode';

  // Default values
  static const ThemeMode _defaultThemeMode = ThemeMode.system;
  static const String _defaultAppLanguage = 'ar';
  static const String _defaultQuranTranslationLang = 'none';
  static const double _defaultAppFontSize = 16.0;
  static const double _defaultQuranFontSize = 22.0;
  static const String _defaultQuranLayoutMode = 'adaptive';

  // Current values
  ThemeMode _themeMode = _defaultThemeMode;
  String _appLanguage = _defaultAppLanguage;
  String _quranTranslationLang = _defaultQuranTranslationLang;
  double _appFontSize = _defaultAppFontSize;
  double _quranFontSize = _defaultQuranFontSize;
  String _quranLayoutMode = _defaultQuranLayoutMode;

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get appLanguage => _appLanguage;
  String get quranTranslationLang => _quranTranslationLang;
  double get appFontSize => _appFontSize;
  double get quranFontSize => _quranFontSize;
  String get quranLayoutMode => _quranLayoutMode;

  // Setters
  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _saveString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> setAppLanguage(String value) async {
    _appLanguage = value;
    await _saveString(_appLanguageKey, value);
    notifyListeners();
  }

  Future<void> setQuranTranslationLang(String value) async {
    _quranTranslationLang = value;
    await _saveString(_quranTranslationLangKey, value);
    notifyListeners();
  }

  Future<void> setAppFontSize(double value) async {
    _appFontSize = value;
    await _saveDouble(_appFontSizeKey, value);
    notifyListeners();
  }

  Future<void> setQuranFontSize(double value) async {
    _quranFontSize = value;
    await _saveDouble(_quranFontSizeKey, value);
    notifyListeners();
  }

  Future<void> setQuranLayoutMode(String value) async {
    _quranLayoutMode = value;
    await _saveString(_quranLayoutModeKey, value);
    notifyListeners();
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _themeMode = _loadThemeMode(prefs.getString(_themeModeKey));
      _appLanguage = prefs.getString(_appLanguageKey) ?? _defaultAppLanguage;
      _quranTranslationLang =
          prefs.getString(_quranTranslationLangKey) ??
          _defaultQuranTranslationLang;
      // SharedPreferences.getDouble may return null or a non-double; guard with tryCast
      final appFont = prefs.getDouble(_appFontSizeKey);
      _appFontSize = (appFont is double) ? appFont : _defaultAppFontSize;
      final quranFont = prefs.getDouble(_quranFontSizeKey);
      _quranFontSize =
          (quranFont is double) ? quranFont : _defaultQuranFontSize;
      _quranLayoutMode =
          prefs.getString(_quranLayoutModeKey) ?? _defaultQuranLayoutMode;

      notifyListeners();
    } catch (e) {
      // If SharedPreferences fails for any reason, keep defaults and notify
      print('Failed to load settings: $e');
      _themeMode = _defaultThemeMode;
      _appLanguage = _defaultAppLanguage;
      _quranTranslationLang = _defaultQuranTranslationLang;
      _appFontSize = _defaultAppFontSize;
      _quranFontSize = _defaultQuranFontSize;
      _quranLayoutMode = _defaultQuranLayoutMode;
      notifyListeners();
    }
  }

  // Helper methods
  ThemeMode _loadThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }
}

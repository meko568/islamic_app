import 'dart:convert';
import 'package:http/http.dart' as http;

class TafsirService {
  /// Returns the tafsir (exegesis) text for a given ayah, or null if it
  /// couldn't be fetched from either source. Tries quranenc.com first
  /// (dedicated tafsir API), then falls back to Al Quran Cloud's Jalalayn
  /// tafsir edition, which uses the same request shape as the translation
  /// calls already used elsewhere in this app.
  static Future<String?> getTafsir(int surahNumber, int ayahNumber) async {
    final quranenc = await _fromQuranEnc(surahNumber, ayahNumber);
    if (quranenc != null && quranenc.trim().isNotEmpty) return quranenc;

    return _fromAlQuranCloud(surahNumber, ayahNumber);
  }

  static Future<String?> _fromQuranEnc(int surahNumber, int ayahNumber) async {
    try {
      final url = Uri.parse(
        'https://quranenc.com/api/v1/translation/aya/arabic_moyassar/$surahNumber/$ayahNumber',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['result'];
      if (result is Map<String, dynamic>) {
        return result['translation'] as String?;
      }
      // Some quranenc responses nest under 'translation' -> 'text' instead.
      final translation = data['translation'];
      if (translation is Map<String, dynamic>) {
        return translation['text'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _fromAlQuranCloud(
    int surahNumber,
    int ayahNumber,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/ar.jalalayn',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = data['data'] as Map<String, dynamic>?;
      return result?['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}

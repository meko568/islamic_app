import 'dart:convert';
import 'package:http/http.dart' as http;

class TafsirService {
  static const String _baseUrl = 'https://quranenc.com/api/v1/translation/aya/arabic_moyassar';

  // Fetch tafsir for a specific ayah
  static Future<String> getTafsir(int surahNumber, int ayahNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$surahNumber/$ayahNumber'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translation']['text'] as String;
    } else {
      throw Exception('Failed to load tafsir');
    }
  }
}

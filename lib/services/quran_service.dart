import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/surah_model.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1/quran/quran-uthmani';
  static const String _cacheFileName = 'quran_cache.json';

  // Fetch full Quran text with caching
  static Future<List<Surah>> getQuran() async {
    // Check if cached data exists
    final cachedData = await _loadCachedData();
    if (cachedData != null) {
      return cachedData;
    }

    // Fetch from API
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final surahs = (data['data']['surahs'] as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache the data
      await _cacheData(surahs);

      return surahs;
    } else {
      throw Exception('Failed to load Quran');
    }
  }

  // Load cached data from file
  static Future<List<Surah>?> _loadCachedData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString);
        return (data as List)
            .map((e) => Surah.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If cache fails, return null and fetch from API
    }
    return null;
  }

  // Cache data to file
  static Future<void> _cacheData(List<Surah> surahs) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      final jsonString = json.encode(surahs.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      // If caching fails, continue without cache
    }
  }

  // Get surah by number
  static Future<Surah?> getSurah(int surahNumber) async {
    final surahs = await getQuran();
    try {
      return surahs.firstWhere((surah) => surah.number == surahNumber);
    } catch (e) {
      return null;
    }
  }

  // Get surahs by juz
  static Future<List<Surah>> getSurahsByJuz(int juzNumber) async {
    final surahs = await getQuran();
    final filteredSurahs = <Surah>[];
    
    for (var surah in surahs) {
      if (surah.ayahs != null) {
        for (var ayah in surah.ayahs!) {
          if (ayah.juz == juzNumber) {
            if (!filteredSurahs.contains(surah)) {
              filteredSurahs.add(surah);
            }
            break;
          }
        }
      }
    }
    
    return filteredSurahs;
  }

  // Get surahs by page
  static Future<List<Surah>> getSurahsByPage(int pageNumber) async {
    final surahs = await getQuran();
    final filteredSurahs = <Surah>[];
    
    for (var surah in surahs) {
      if (surah.ayahs != null) {
        for (var ayah in surah.ayahs!) {
          if (ayah.page == pageNumber) {
            if (!filteredSurahs.contains(surah)) {
              filteredSurahs.add(surah);
            }
            break;
          }
        }
      }
    }
    
    return filteredSurahs;
  }

  // Get ayah by surah and ayah number
  static Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    final surah = await getSurah(surahNumber);
    if (surah?.ayahs == null) return null;
    
    try {
      return surah!.ayahs!.firstWhere((ayah) => ayah.numberInSurah == ayahNumber);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Ayah>> getAyahsByPage(int pageNumber) async {
    final surahs = await getQuran();
    final ayahs = <Ayah>[];
    
    for (var surah in surahs) {
      if (surah.ayahs != null) {
        for (var ayah in surah.ayahs!) {
          if (ayah.page == pageNumber) {
            ayahs.add(ayah);
          }
        }
      }
    }
    
    return ayahs;
  }

  // Download Mushaf images
  static Future<void> downloadPage(int pageNumber, Function(double) onProgress) async {
    final directory = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${directory.path}/quran_pages');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }

    final filePath = '${quranDir.path}/page_$pageNumber.png';
    final file = File(filePath);

    if (await file.exists()) return;

    final url = 'https://github.com/m-reza/quran-images/raw/master/quran_images/$pageNumber.png';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      rethrow;
    }
  }
}

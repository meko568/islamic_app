import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/surah_model.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1/quran/quran-uthmani';
  static const String _cacheFileName = 'quran_cache.json';
  static const String _assetPath = 'assets/data/quran_data.json';

  // Fetch full Quran text with caching and asset fallback
  static Future<List<Surah>> getQuran() async {
    // 1. Check if cached data exists in local storage
    final cachedData = await _loadCachedData();
    if (cachedData != null) {
      return cachedData;
    }

    // 2. Try to load from bundled assets (Offline First)
    try {
      final String response = await rootBundle.loadString(_assetPath);
      final data = json.decode(response);
      final surahs = (data['data']['surahs'] as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Cache it for faster loading next time
      await _cacheData(surahs);
      return surahs;
    } catch (e) {
      // 3. Fallback to API if asset is missing or corrupted
      try {
        final response = await http.get(Uri.parse(_baseUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final surahs = (data['data']['surahs'] as List)
              .map((e) => Surah.fromJson(e as Map<String, dynamic>))
              .toList();

          await _cacheData(surahs);
          return surahs;
        }
      } catch (apiError) {
        throw Exception('Failed to load Quran from all sources');
      }
    }
    throw Exception('Failed to load Quran');
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
  static Future<bool> downloadPage(int pageNumber, Function(double) onProgress) async {
    final directory = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${directory.path}/quran_pages');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }

    final filePath = '${quranDir.path}/page_$pageNumber.png';
    final file = File(filePath);

    try {
      // If file already exists and is valid (> 30KB), skip
      if (await file.exists() && await file.length() > 30000) return true;
    } catch (_) {}

    final padded = pageNumber.toString().padLeft(3, '0');
    
    // Optimized sources with verified paths
    final sources = [
      // Source 1: Islam-DB (Verified to work for most pages in user logs)
      'https://quran.islam-db.com/public/data/pages/quranpages_1024/images/page$padded.png',
      // Source 2: GovarJabbar (Alternative PNG source)
      'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/png/$pageNumber.png',
      // Source 3: QuranHub (Using direct number)
      'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/Hafs/PNG/$pageNumber.png',
    ];

    for (var url in sources) {
      try {
        debugPrint('Downloading page $pageNumber from: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          },
        ).timeout(const Duration(seconds: 20));

        // Reduced minSize to 35KB because Page 1 (valid) was 42KB.
        // This will still block the 6KB and 14-byte error pages.
        const int minSize = 35000;

        if (response.statusCode == 200 && response.bodyBytes.length > minSize) {
          // Verify if it's actually an image by checking the first few bytes (PNG magic number)
          final bytes = response.bodyBytes;
          if (bytes.length > 8 && 
              bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
            
            await file.writeAsBytes(bytes, flush: true);
            
            if (await file.exists() && await file.length() > minSize) {
              debugPrint('✅ Page $pageNumber saved: ${await file.length()} bytes');
              return true;
            }
          } else {
            debugPrint('❌ Source $url returned non-PNG data for page $pageNumber');
          }
        } else {
          debugPrint('❌ Source failed ($url): Status ${response.statusCode}, Size ${response.bodyBytes.length}');
        }
      } catch (e) {
        debugPrint('⚠️ Connection error ($url): $e');
      }
    }
    
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}

    return false;
  }
}

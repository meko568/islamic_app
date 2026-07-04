import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/azkar_model.dart';

class AzkarService {
  static const String _muslimKitBaseUrl =
      'https://ahegazy.github.io/muslimKit/json';
  static const String _islamicAppBaseUrl = 'https://api.islamic.app/v1/dhikr';
  static const String _cachedDataKey = 'cached_azkar_data';

  // Category mappings - using muslimKit for original categories, islamic.app for additional ones
  static const Map<String, String> _categoryMappings = {
    // Original categories from muslimKit
    'azkar_sabah.json': 'Morning',
    'azkar_massa.json': 'Evening',
    'PostPrayer_azkar.json': 'After Salah',
    // Additional categories from islamic.app
    'before-sleep': 'Before Sleep',
    'waking-up': 'Waking Up',
    'prayer': 'Prayer',
    'mosque': 'Mosque',
    'travel': 'Travel',
    'food': 'Food and Drink',
    'home': 'Home',
    'anxiety': 'Anxiety and Distress',
    'protection': 'Protection',
    'forgiveness': 'Forgiveness',
    'hajj': 'Hajj and Umrah',
    // Additional specific categories
    '6': 'Bathroom - Entering',
    '7': 'Bathroom - Leaving',
    '2': 'Clothing - Wearing',
    '3': 'Clothing - New Garment',
    '4': 'Clothing - Seeing Someone Wear New',
    '5': 'Clothing - Before Undressing',
    '8': 'Ablution - Before',
    '9': 'Ablution - After',
    '41': 'Debt - Settling',
    '49': 'Sick - Visiting',
    '50': 'Sick - Excellence of Visiting',
    '51': 'Sick - When Renounced Hope',
    '77': 'Sneezing - Upon Sneezing',
    '78': 'Sneezing - Non-Muslim Praises',
    '91': 'Debt - When Settled',
    '98': 'Market - Entering',
    '114': 'Praise - When Praised',
  };

  // Check if data is cached
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cachedDataKey);
    } catch (e) {
      // If SharedPreferences is unavailable (eg. web plugin issue), treat as no cache
        debugPrint('Error checking cached data: $e');
      return false;
    }
  }

  // Fetch data from API
  static Future<List<AzkarCategory>> fetchAzkarData() async {
    try {
      final List<AzkarCategory> categories = [];

      // Fetch data from each category endpoint
      for (var categoryKey in _categoryMappings.keys) {
        try {
          String url;
          // Use muslimKit for .json files, islamic.app for others
          if (categoryKey.endsWith('.json')) {
            url = '$_muslimKitBaseUrl/$categoryKey';
          } else {
            url = '$_islamicAppBaseUrl/$categoryKey';
          }

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            final category = _parseCategoryData(jsonData, categoryKey);
            if (category != null) {
              categories.add(category);
            }
          }
        } catch (e) {
          // Continue with other categories if one fails
          debugPrint('Failed to fetch category $categoryKey: $e');
        }
      }

      // Cache the data
      await _cacheData(categories);

      return categories;
    } catch (e) {
      throw Exception('Error fetching azkar data: $e');
    }
  }

  // Load cached data
  static Future<List<AzkarCategory>> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedDataKey);

      if (cachedJson != null) {
        final jsonData = json.decode(cachedJson);
        if (jsonData is List) {
          return jsonData.map((item) {
            final categoryName = item['name'] as String;
            final isEveningAzkar = categoryName == 'Evening';
            final isMorningAzkar = categoryName == 'Morning';

            return AzkarCategory(
              name: item['name'],
              arabicName: item['arabicName'],
              items:
                  (item['items'] as List).map((itemData) {
                    var zekr = itemData['zekr'] as String;
                    var bless = itemData['bless'] as String;

                    // Apply corrections for morning and evening azkar
                    if (isEveningAzkar || isMorningAzkar) {
                      zekr = _correctAzkarText(zekr, isEvening: isEveningAzkar);
                      bless = _correctAzkarText(
                        bless,
                        isEvening: isEveningAzkar,
                      );
                    }

                    return AzkarItem(
                      zekr: zekr,
                      repeat: itemData['repeat'],
                      bless: '', // bless is actually the importance/virtue
                      source: itemData['source'],
                      importance: bless.isNotEmpty ? bless : null,
                    );
                  }).toList(),
            );
          }).toList();
        }
      }

      throw Exception('No cached data found');
    } catch (e) {
      throw Exception('Error loading cached data: $e');
    }
  }

  // Cache data to SharedPreferences
  static Future<void> _cacheData(List<AzkarCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData =
        categories
            .map(
              (cat) => {
                'name': cat.name,
                'arabicName': cat.arabicName,
                'items':
                    cat.items
                        .map(
                          (item) => {
                            'zekr': item.zekr,
                            'repeat': item.repeat,
                            'bless': item.bless,
                            'source': item.source,
                            'importance': item.importance,
                          },
                        )
                        .toList(),
              },
            )
            .toList();
    await prefs.setString(_cachedDataKey, json.encode(jsonData));
  }

  // Parse single category data - handles both muslimKit and islamic.app API formats
  static AzkarCategory? _parseCategoryData(dynamic jsonData, String category) {
    if (jsonData == null) return null;
    if (jsonData is Map<String, dynamic>) {
      // Check if it's muslimKit format (has 'title' and 'content')
      if (jsonData.containsKey('title') && jsonData.containsKey('content')) {
        return _parseMuslimKitData(jsonData, category);
      }
      // Check if it's islamic.app format (has 'data' with 'duas')
      else if (jsonData.containsKey('data')) {
        return _parseIslamicAppData(jsonData, category);
      }
    }
    return null;
  }

  // Correct azkar text - applies to both morning and evening
  static String _correctAzkarText(String text, {bool isEvening = false}) {
    String corrected = text;

    // Apply general corrections (both morning and evening)
    corrected = corrected
        .replaceAll(
          'الله لا إلـه إلا هو الحي القيوم لا تأخذه سنة ولا نوم له ما في السماوات وما في الأرض من ذا الذي يشفع عنده إلا بإذنه يعلم ما بين أيديهم وما خلفهم ولا يحيطون بشيء من علمه إلا بما شاء وسع كرسيه السماوات والأرض ولا يؤوده حفظهما وهو العلي العظيم',
          'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        )
        .replaceAll(
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى آلِ إِبْرَاهِيمَ،إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ  وَ آلِ إِبْرَاهِيمَ،إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ  وَ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
        );

    // Apply evening-specific corrections (day to night references)
    if (isEvening) {
      corrected = corrected
          .replaceAll('النُّـشُور', 'المصير')
          .replaceAll('هذا اليوم', 'هذه الليلة')
          .replaceAll('هـذا اليـوم', 'هذه اللـيلة')
          .replaceAll('هـذا الـيَوْم', 'هـذه الـلَيْلة')
          .replaceAll('هـذا اليوم', 'هذه الليلة')
          .replaceAll('هذا اليـوم', 'هذه اللـيلة')
          .replaceAll('يومه', 'ليلتها')
          .replaceAll('يـومه', 'لـيلتها')
          .replaceAll('بعده', 'بعدها')
          .replaceAll('بَعْـدَه', 'بَعْـدَها')
          .replaceAll('ما فـيهِ', 'ما فـيها')
          .replaceAll('ما فيه', 'ما فيها')
          .replaceAll('فتحه', 'فتحها')
          .replaceAll('فَـتْحَهُ', 'فَـتْحَها')
          .replaceAll('فـتحه', 'فـتحها')
          .replaceAll('نصره', 'نصرها')
          .replaceAll('نَصْـرَهُ', 'نَصْـرَها')
          .replaceAll('نـصره', 'نـصرها')
          .replaceAll('نوره', 'نورها')
          .replaceAll('نـورَهُ', 'نـورَها')
          .replaceAll('نـوره', 'نـورها')
          .replaceAll('بركته', 'بركتها')
          .replaceAll('بَـرَكَتَـهُ', 'بَـرَكَتَـها')
          .replaceAll('بـركته', 'بـركتها')
          .replaceAll('هداه', 'هداها')
          .replaceAll('هُـداهُ', 'هُـداها')
          .replaceAll('هـداه', 'هـداها');
    }

    return corrected;
  }

  // Parse muslimKit API format
  static AzkarCategory? _parseMuslimKitData(dynamic jsonData, String category) {
    final arabicName = jsonData['title']?.toString() ?? '';
    final categoryName = _categoryMappings[category] ?? 'Unknown';
    final itemsList = jsonData['content'];

    if (itemsList is! List) return null;

    final isEveningAzkar = category == 'azkar_massa.json';
    final isMorningAzkar = category == 'azkar_sabah.json';
    final items = <AzkarItem>[];
    for (var itemData in itemsList) {
      if (itemData is Map<String, dynamic>) {
        var zekr = itemData['zekr']?.toString() ?? '';
        var bless = itemData['bless']?.toString() ?? '';

        // Apply text corrections for morning and evening azkar
        if (isEveningAzkar || isMorningAzkar) {
          zekr = _correctAzkarText(zekr, isEvening: isEveningAzkar);
          bless = _correctAzkarText(bless, isEvening: isEveningAzkar);
        }

        items.add(
          AzkarItem(
            zekr: zekr,
            repeat: itemData['repeat'] is int ? itemData['repeat'] : 1,
            bless: '', // bless is actually the importance/virtue
            source: 'muslimKit',
            importance: bless.isNotEmpty ? bless : null,
          ),
        );
      }
    }

    return AzkarCategory(
      name: categoryName,
      arabicName: arabicName,
      items: items,
    );
  }

  // Parse islamic.app API format
  static AzkarCategory? _parseIslamicAppData(
    dynamic jsonData,
    String category,
  ) {
    final data = jsonData['data'];
    if (data is! Map<String, dynamic>) return null;

    final arabicName =
        data['category']?['ar']?.toString() ?? data['label']?.toString() ?? '';
    final categoryName =
        _categoryMappings[category] ??
        data['category']?['en']?.toString() ??
        'Unknown';
    final itemsList = data['duas'];

    if (itemsList is! List) return null;

    final isEveningAzkar = category == 'evening';
    final isMorningAzkar = category == 'morning';
    final items = <AzkarItem>[];
    for (var itemData in itemsList) {
      if (itemData is Map<String, dynamic>) {
        final arText = itemData['ar']?['text']?.toString() ?? '';
        final enText = itemData['en']?['text']?.toString() ?? '';

        // Combine Arabic and English text
        var zekr = arText.isNotEmpty ? arText : enText;
        var bless = enText;

        // Apply text corrections for morning and evening azkar
        if (isEveningAzkar || isMorningAzkar) {
          zekr = _correctAzkarText(zekr, isEvening: isEveningAzkar);
          bless = _correctAzkarText(bless, isEvening: isEveningAzkar);
        }

        items.add(
          AzkarItem(
            zekr: zekr,
            repeat: 1, // islamic.app API doesn't provide repeat count
            bless: bless, // Use English text as bless/translation
            source: 'Hisn al-Muslim',
            importance:
                itemData['ar']?['reference']?.toString() ??
                itemData['en']?['reference']?.toString(),
          ),
        );
      }
    }

    return AzkarCategory(
      name: categoryName,
      arabicName: arabicName,
      items: items,
    );
  }

  // Clear cached data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDataKey);
  }

  // Get all available category file names
  static List<String> getAllCategoryIds() {
    return _categoryMappings.keys.toList();
  }
}

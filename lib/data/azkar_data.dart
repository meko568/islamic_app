import '../models/azkar_model.dart';
import '../services/azkar_service.dart';

class AzkarData {
  static List<AzkarCategory>? _categories;

  // Get categories - loads from cache or returns empty list
  static Future<List<AzkarCategory>> getCategories() async {
    if (_categories != null) {
      return _categories!;
    }

    try {
      final hasCached = await AzkarService.hasCachedData();
      if (hasCached) {
        _categories = await AzkarService.loadCachedData();
      } else {
        // Return empty list if no data cached yet
        _categories = [];
      }
    } catch (e) {
      // Return empty list on error
      _categories = [];
    }

    return _categories!;
  }

  // Fetch data from API
  static Future<List<AzkarCategory>> fetchAndCacheData() async {
    try {
      _categories = await AzkarService.fetchAzkarData();
      return _categories!;
    } catch (e) {
      throw Exception('Failed to fetch azkar data: $e');
    }
  }

  // Check if data is loaded
  static bool isDataLoaded() {
    return _categories != null && _categories!.isNotEmpty;
  }

  // Clear cached data
  static Future<void> clearCache() async {
    await AzkarService.clearCache();
    _categories = null;
  }
}

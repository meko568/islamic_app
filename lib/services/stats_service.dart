import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const String _lifetimeTasbeehKey = 'lifetime_tasbeeh_count';

  static Future<void> incrementLifetimeTasbeeh({int by = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_lifetimeTasbeehKey) ?? 0;
    await prefs.setInt(_lifetimeTasbeehKey, current + by);
  }

  static Future<int> getLifetimeTasbeeh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lifetimeTasbeehKey) ?? 0;
  }
}

import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task_model.dart';
import 'prayer_service.dart';

/// Local (offline-first) persistence for the Daily Tracker.
/// A "tracker day" starts at Fajr, not at midnight: if it's currently
/// between midnight and Fajr, we're still counting yesterday's day.
class TrackerStorageService {
  static const String _recordPrefix = 'tracker_record_';
  static const String _customTasksKey = 'tracker_custom_tasks';
  static const String _lastKnownLatKey = 'tracker_last_lat';
  static const String _lastKnownLngKey = 'tracker_last_lng';

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  /// Fetches current position, falling back to the last known lat/lng
  /// cached in prefs (so tracker features keep working without asking
  /// for location every single time).
  static Future<({double lat, double lng})?> _getCachedLocation() async {
    try {
      final position = await PrayerService.getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      double? lat = position?.latitude;
      double? lng = position?.longitude;

      if (lat != null && lng != null) {
        await prefs.setDouble(_lastKnownLatKey, lat);
        await prefs.setDouble(_lastKnownLngKey, lng);
      } else {
        lat = prefs.getDouble(_lastKnownLatKey);
        lng = prefs.getDouble(_lastKnownLngKey);
      }
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    } catch (_) {}
    return null;
  }

  /// Returns today's PrayerTimes for the last known location, or null if
  /// location isn't available yet - used to lock prayer checkboxes until
  /// their time arrives.
  static Future<PrayerTimes?> getTodayPrayerTimes() async {
    final loc = await _getCachedLocation();
    if (loc == null) return null;
    final coordinates = Coordinates(loc.lat, loc.lng);
    final params = CalculationMethod.egyptian.getParameters();
    return PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );
  }

  /// Returns today's tracker-day date string, falling back to the plain
  /// calendar day if location isn't available.
  static Future<String> getCurrentTrackerDate() async {
    final now = DateTime.now();
    final loc = await _getCachedLocation();
    if (loc != null) {
      final coordinates = Coordinates(loc.lat, loc.lng);
      final params = CalculationMethod.egyptian.getParameters();
      final prayerTimes = PrayerTimes(
        coordinates,
        DateComponents.from(now),
        params,
      );
      final fajr = prayerTimes.timeForPrayer(Prayer.fajr);
      if (fajr != null && now.isBefore(fajr)) {
        return _fmt.format(now.subtract(const Duration(days: 1)));
      }
    }
    return _fmt.format(now);
  }

  static Future<DailyRecord> loadRecord(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_recordPrefix$date');
    if (raw == null) return DailyRecord(date: date);
    try {
      return DailyRecord.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return DailyRecord(date: date);
    }
  }

  static Future<void> saveRecord(DailyRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_recordPrefix${record.date}',
      jsonEncode(record.toJson()),
    );
  }

  /// Loads every stored record between [from] and [to] (inclusive),
  /// used by the tracker history view.
  static Future<List<DailyRecord>> loadHistory(
    DateTime from,
    DateTime to,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final records = <DailyRecord>[];
    for (
      var d = from;
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))
    ) {
      final dateStr = _fmt.format(d);
      final raw = prefs.getString('$_recordPrefix$dateStr');
      if (raw != null) {
        try {
          records.add(
            DailyRecord.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            ),
          );
        } catch (_) {}
      }
    }
    return records;
  }

  static Future<List<CustomTaskDef>> loadCustomTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customTasksKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CustomTaskDef.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomTasks(List<CustomTaskDef> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customTasksKey,
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
  }
}

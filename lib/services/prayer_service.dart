import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PrayerService {
  // Prayer names in Arabic
  static final Map<Prayer, String> _arabicPrayerNames = {
    Prayer.fajr: 'الفجر',
    Prayer.sunrise: 'الشروق',
    Prayer.dhuhr: 'الظهر',
    Prayer.asr: 'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha: 'العشاء',
  };

  static String getArabicPrayerName(Prayer prayer) {
    return _arabicPrayerNames[prayer] ?? prayer.name;
  }

  // Format time to 12hr format with Arabic AM/PM
  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  // Get today's date string for storage keys
  static String getTodayDateString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  // Get prayer checked state key
  static String getPrayerCheckedKey(Prayer prayer, String date) {
    return 'prayer_${prayer.name}_checked_$date';
  }

  // Get alert played key
  static String getAlertPlayedKey(
    Prayer currentPrayer,
    Prayer nextPrayer,
    String date,
  ) {
    return 'alert_${currentPrayer.name}_${nextPrayer.name}_played_$date';
  }

  // Check if prayer is checked for today
  static Future<bool> isPrayerChecked(Prayer prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    return prefs.getBool(getPrayerCheckedKey(prayer, date)) ?? false;
  }

  // Set prayer checked state
  static Future<void> setPrayerChecked(Prayer prayer, bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    await prefs.setBool(getPrayerCheckedKey(prayer, date), checked);
  }

  // Check if alert has been played for this prayer transition today
  static Future<bool> hasAlertPlayed(
    Prayer currentPrayer,
    Prayer nextPrayer,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    return prefs.getBool(getAlertPlayedKey(currentPrayer, nextPrayer, date)) ??
        false;
  }

  // Set alert played state
  static Future<void> setAlertPlayed(
    Prayer currentPrayer,
    Prayer nextPrayer,
    bool played,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    await prefs.setBool(
      getAlertPlayedKey(currentPrayer, nextPrayer, date),
      played,
    );
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, try last known position
        return await Geolocator.getLastKnownPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, try last known position
      return await Geolocator.getLastKnownPosition();
    }

    if (!serviceEnabled) {
      // Location services are not enabled but we have permission.
      // We can't get current position, so try last known.
      return await Geolocator.getLastKnownPosition();
    }

    try {
      // Try getting current position with a timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      // If fails (timeout or other), try last known position as a last resort
      return await Geolocator.getLastKnownPosition();
    }
  }

  // Calculate prayer times for given coordinates
  static PrayerTimes calculatePrayerTimes(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, date, params);
  }

  static Prayer getCurrentPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    Prayer currentPrayer = Prayer.isha;

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      if (prayerTime == null) continue;

      final prayerDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        prayerTime.hour,
        prayerTime.minute,
      );

      if (now.isAfter(prayerDateTime)) {
        currentPrayer = prayer;
      }
    }

    return currentPrayer;
  }

  // Get next prayer
  static Prayer? getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      if (prayerTime == null) continue;

      final prayerDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        prayerTime.hour,
        prayerTime.minute,
      );

      if (now.isBefore(prayerDateTime)) {
        return prayer;
      }
    }

    // If all prayers have passed, next is Fajr tomorrow
    return Prayer.fajr;
  }

  // Get time until next prayer in seconds
  static int getTimeUntilNextPrayer(PrayerTimes prayerTimes) {
    final nextPrayer = getNextPrayer(prayerTimes);
    if (nextPrayer == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prayerTime = prayerTimes.timeForPrayer(nextPrayer);
    if (prayerTime == null) return 0;

    DateTime prayerDateTime;

    if (nextPrayer == Prayer.fajr && now.hour > 12) {
      // Fajr is tomorrow
      final tomorrow = today.add(const Duration(days: 1));
      prayerDateTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        prayerTime.hour,
        prayerTime.minute,
      );
    } else {
      prayerDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        prayerTime.hour,
        prayerTime.minute,
      );
    }

    return prayerDateTime.difference(now).inSeconds;
  }

  // Format countdown as HH:MM:SS
  static String formatCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Check if alert should be triggered
  static bool shouldTriggerAlert(
    PrayerTimes prayerTimes,
    Prayer currentPrayer,
    Prayer? nextPrayer,
  ) {
    if (nextPrayer == null) return false;

    final timeUntilNext = getTimeUntilNextPrayer(prayerTimes);
    final tenMinutesInSeconds = 10 * 60;

    return timeUntilNext <= tenMinutesInSeconds && timeUntilNext > 0;
  }
}

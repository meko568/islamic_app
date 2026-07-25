import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

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

  static String getEnglishPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }

  /// Checks if the next prayer is approaching and the previous one wasn't prayed.
  /// Designed to run in the background via Workmanager.
  static Future<void> checkAndNotifyIfPrayerApproaching(String lang) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return;

      final prayerTimes = calculatePrayerTimes(
        position.latitude,
        position.longitude,
      );
      
      final secondsUntilNext = getTimeUntilNextPrayer(prayerTimes);
      
      // Since background tasks run every 15 mins, we check a 16-min window
      if (secondsUntilNext <= 0 || secondsUntilNext > 960) return;

      final lastPrayer = getCurrentPrayer(prayerTimes);
      if (lastPrayer == Prayer.sunrise) return;
      
      if (await isPrayerChecked(lastPrayer)) return;

      final nextPrayer = getNextPrayer(prayerTimes);
      if (nextPrayer == null) return;

      final prefs = await SharedPreferences.getInstance();
      final date = getTodayDateString();
      final notifiedKey = 'prayer_approach_notified_${lastPrayer.name}_${nextPrayer.name}_$date';
      if (prefs.getBool(notifiedKey) ?? false) return;
      await prefs.setBool(notifiedKey, true);

      final lastName = lang == 'ar'
              ? getArabicPrayerName(lastPrayer)
              : getEnglishPrayerName(lastPrayer);
      final nextName = lang == 'ar'
              ? getArabicPrayerName(nextPrayer)
              : getEnglishPrayerName(nextPrayer);

      const androidDetails = AndroidNotificationDetails(
        'prayer_reminder_channel_v2',
        'تذكير الصلاة',
        channelDescription: 'تنبيه عند اقتراب دخول وقت صلاة جديدة',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        showWhen: true,
      );
      const details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        9000 + nextPrayer.index,
        lang == 'ar' ? 'تذكير صلاة' : 'Prayer Reminder',
        lang == 'ar'
            ? 'لسه ما صليتش $lastName، ووقت $nextName قرّب يدخل'
            : "You haven't prayed $lastName yet, and $nextName is coming up soon",
        details,
        payload: 'prayer_reminder',
      );
    } catch (e) {
      // Best-effort only
    }
  }

  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  static String getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String getPrayerCheckedKey(Prayer prayer, String date) {
    return 'prayer_${prayer.name}_checked_$date';
  }

  static String getAlertPlayedKey(
    Prayer currentPrayer,
    Prayer nextPrayer,
    String date,
  ) {
    return 'alert_${currentPrayer.name}_${nextPrayer.name}_played_$date';
  }

  static Future<bool> isPrayerChecked(Prayer prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    return prefs.getBool(getPrayerCheckedKey(prayer, date)) ?? false;
  }

  static Future<void> setPrayerChecked(Prayer prayer, bool checked) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    await prefs.setBool(getPrayerCheckedKey(prayer, date), checked);
  }

  static Future<bool> hasAlertPlayed(
    Prayer currentPrayer,
    Prayer nextPrayer,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final date = getTodayDateString();
    return prefs.getBool(getAlertPlayedKey(currentPrayer, nextPrayer, date)) ??
        false;
  }

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

  static Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  static PrayerTimes calculatePrayerTimes(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, date, params);
  }

  static Prayer getCurrentPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

    Prayer currentPrayer = Prayer.isha;
    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      if (prayerTime == null) continue;
      final prayerDateTime = DateTime(today.year, today.month, today.day, prayerTime.hour, prayerTime.minute);
      if (now.isAfter(prayerDateTime)) {
        currentPrayer = prayer;
      }
    }
    return currentPrayer;
  }

  static Prayer? getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

    for (var prayer in prayers) {
      final prayerTime = prayerTimes.timeForPrayer(prayer);
      if (prayerTime == null) continue;
      final prayerDateTime = DateTime(today.year, today.month, today.day, prayerTime.hour, prayerTime.minute);
      if (now.isBefore(prayerDateTime)) {
        return prayer;
      }
    }
    return Prayer.fajr;
  }

  static int getTimeUntilNextPrayer(PrayerTimes prayerTimes) {
    final nextPrayer = getNextPrayer(prayerTimes);
    if (nextPrayer == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayerTime = prayerTimes.timeForPrayer(nextPrayer);
    if (prayerTime == null) return 0;

    DateTime prayerDateTime;
    if (nextPrayer == Prayer.fajr && now.hour > 12) {
      final tomorrow = today.add(const Duration(days: 1));
      prayerDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, prayerTime.hour, prayerTime.minute);
    } else {
      prayerDateTime = DateTime(today.year, today.month, today.day, prayerTime.hour, prayerTime.minute);
    }

    return prayerDateTime.difference(now).inSeconds;
  }

  static String formatCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static bool shouldTriggerAlert(
    PrayerTimes prayerTimes,
    Prayer currentPrayer,
    Prayer? nextPrayer,
  ) {
    if (nextPrayer == null) return false;
    final timeUntilNext = getTimeUntilNextPrayer(prayerTimes);
    // Trigger within last 10 minutes
    return timeUntilNext <= 600 && timeUntilNext > 0;
  }
}

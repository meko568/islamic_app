import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_task_model.dart';
import '../models/target_model.dart';

/// Best-effort Firestore sync. Local SharedPreferences storage is always the
/// source of truth for the running app - this service only mirrors it to the
/// cloud (when signed in and online) so data survives reinstalls/new devices.
/// All methods swallow errors: a failed sync must never break offline use.
class FirestoreSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _trackerDoc(String uid) =>
      _db.collection('users').doc(uid).collection('app_data').doc('tracker');

  DocumentReference<Map<String, dynamic>> _targetsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('app_data').doc('targets');

  Future<void> pushTrackerRecord(String uid, DailyRecord record) async {
    try {
      await _trackerDoc(
        uid,
      ).set({'records.${record.date}': record.toJson()}, SetOptions(merge: true));
    } catch (_) {
      // Offline or transient error - local copy already saved, safe to ignore.
    }
  }

  Future<void> pushCustomTasks(String uid, List<CustomTaskDef> tasks) async {
    try {
      await _trackerDoc(uid).set({
        'customTasks': tasks.map((e) => e.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns (records, customTasks) from the cloud, or nulls if unavailable.
  Future<
    ({Map<String, DailyRecord> records, List<CustomTaskDef> customTasks})?
  >
  pullTrackerData(String uid) async {
    try {
      final snap = await _trackerDoc(uid).get();
      final data = snap.data();
      if (data == null) return null;

      final recordsRaw = Map<String, dynamic>.from(
        data['records'] as Map? ?? {},
      );
      final records = recordsRaw.map(
        (date, json) => MapEntry(
          date,
          DailyRecord.fromJson(Map<String, dynamic>.from(json as Map)),
        ),
      );

      final customRaw = (data['customTasks'] as List? ?? []);
      final customTasks = customRaw
          .map((e) => CustomTaskDef.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return (records: records, customTasks: customTasks);
    } catch (_) {
      return null;
    }
  }

  Future<void> pushTargets(String uid, List<IslamicTarget> targets) async {
    try {
      await _targetsDoc(uid).set({
        'targets': targets.map((e) => e.toJson()).toList(),
      });
    } catch (_) {}
  }

  Future<List<IslamicTarget>?> pullTargets(String uid) async {
    try {
      final snap = await _targetsDoc(uid).get();
      final data = snap.data();
      if (data == null) return null;
      final raw = (data['targets'] as List? ?? []);
      return raw
          .map((e) => IslamicTarget.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

enum DailyTaskType { prayer, azkar, tasbeeh, quran, custom }

/// Definition of a task that can appear in the Daily Tracker.
class DailyTaskDef {
  final String id;
  final String titleAr;
  final String titleEn;
  final DailyTaskType type;
  final bool isPreset;

  const DailyTaskDef({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.type,
    this.isPreset = true,
  });

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;

  /// Built-in tasks every user starts with. Prayer ids match [PrayerService]
  /// naming so completion can be auto-detected from the Prayer Times screen.
  static const List<DailyTaskDef> presets = [
    DailyTaskDef(
      id: 'prayer_fajr',
      titleAr: 'صلاة الفجر',
      titleEn: 'Fajr Prayer',
      type: DailyTaskType.prayer,
    ),
    DailyTaskDef(
      id: 'prayer_dhuhr',
      titleAr: 'صلاة الظهر',
      titleEn: 'Dhuhr Prayer',
      type: DailyTaskType.prayer,
    ),
    DailyTaskDef(
      id: 'prayer_asr',
      titleAr: 'صلاة العصر',
      titleEn: 'Asr Prayer',
      type: DailyTaskType.prayer,
    ),
    DailyTaskDef(
      id: 'prayer_maghrib',
      titleAr: 'صلاة المغرب',
      titleEn: 'Maghrib Prayer',
      type: DailyTaskType.prayer,
    ),
    DailyTaskDef(
      id: 'prayer_isha',
      titleAr: 'صلاة العشاء',
      titleEn: 'Isha Prayer',
      type: DailyTaskType.prayer,
    ),
    DailyTaskDef(
      id: 'morning_azkar',
      titleAr: 'أذكار الصباح',
      titleEn: 'Morning Azkar',
      type: DailyTaskType.azkar,
    ),
    DailyTaskDef(
      id: 'evening_azkar',
      titleAr: 'أذكار المساء',
      titleEn: 'Evening Azkar',
      type: DailyTaskType.azkar,
    ),
    DailyTaskDef(
      id: 'daily_tasbeeh',
      titleAr: 'ورد التسبيح',
      titleEn: 'Daily Tasbeeh',
      type: DailyTaskType.tasbeeh,
    ),
    DailyTaskDef(
      id: 'quran_wird',
      titleAr: 'ورد القرآن',
      titleEn: 'Quran Portion',
      type: DailyTaskType.quran,
    ),
  ];
}

/// Completion state of a single task on a single tracker day.
class TaskCompletion {
  bool done;
  /// true when the check came automatically from another screen
  /// (e.g. Prayer Times), false when the user checked it manually here.
  bool auto;

  TaskCompletion({this.done = false, this.auto = false});

  Map<String, dynamic> toJson() => {'done': done, 'auto': auto};

  factory TaskCompletion.fromJson(Map<String, dynamic> j) => TaskCompletion(
    done: j['done'] as bool? ?? false,
    auto: j['auto'] as bool? ?? false,
  );
}

/// All completions for one tracker day (a "day" starts at Fajr, not midnight).
class DailyRecord {
  final String date; // yyyy-MM-dd
  final Map<String, TaskCompletion> tasks;

  DailyRecord({required this.date, Map<String, TaskCompletion>? tasks})
    : tasks = tasks ?? {};

  Map<String, dynamic> toJson() => {
    'date': date,
    'tasks': tasks.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory DailyRecord.fromJson(Map<String, dynamic> j) {
    final tasksJson = Map<String, dynamic>.from(j['tasks'] as Map? ?? {});
    return DailyRecord(
      date: j['date'] as String,
      tasks: tasksJson.map(
        (k, v) =>
            MapEntry(k, TaskCompletion.fromJson(Map<String, dynamic>.from(v))),
      ),
    );
  }
}

/// A user-defined task added on top of the presets.
class CustomTaskDef {
  final String id;
  final String title;

  CustomTaskDef({required this.id, required this.title});

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  factory CustomTaskDef.fromJson(Map<String, dynamic> j) =>
      CustomTaskDef(id: j['id'] as String, title: j['title'] as String);
}

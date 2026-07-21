enum TargetPeriod { daily, weekly, monthly }

class IslamicTarget {
  final String id;
  String title;
  final TargetPeriod period;
  int goal;
  int progress;
  String unit;
  /// Identifies which cycle (day/week/month) [progress] belongs to, so the
  /// provider can detect a new cycle started and reset progress to 0.
  String periodKey;
  final bool isPreset;
  /// Optional deep-link: 'tasbeeh' auto-increments this target whenever the
  /// user counts in the Tasbeeh screen; 'surah:<number>' opens that surah
  /// in the Quran screen when the target card is tapped.
  final String? linkType;

  IslamicTarget({
    required this.id,
    required this.title,
    required this.period,
    required this.goal,
    this.progress = 0,
    this.unit = '',
    required this.periodKey,
    this.isPreset = false,
    this.linkType,
  });

  bool get isDone => progress >= goal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'period': period.name,
    'goal': goal,
    'progress': progress,
    'unit': unit,
    'periodKey': periodKey,
    'isPreset': isPreset,
    'linkType': linkType,
  };

  factory IslamicTarget.fromJson(Map<String, dynamic> j) => IslamicTarget(
    id: j['id'] as String,
    title: j['title'] as String,
    period: TargetPeriod.values.firstWhere(
      (e) => e.name == j['period'],
      orElse: () => TargetPeriod.daily,
    ),
    goal: j['goal'] as int? ?? 1,
    progress: j['progress'] as int? ?? 0,
    unit: j['unit'] as String? ?? '',
    periodKey: j['periodKey'] as String? ?? '',
    isPreset: j['isPreset'] as bool? ?? false,
    linkType: j['linkType'] as String?,
  );

  /// Ready-made target suggestions shown when the user taps "add target".
  static List<Map<String, dynamic>> presetTemplates(String lang) {
    final ar = lang == 'ar';
    return [
      {
        'title': ar ? 'تسبيح 1000 مرة' : '1000 Tasbeeh',
        'period': TargetPeriod.daily,
        'goal': 1000,
        'unit': ar ? 'تسبيحة' : 'count',
        'linkType': 'tasbeeh',
      },
      {
        'title': ar ? 'قراءة سورة الكهف' : 'Read Surah Al-Kahf',
        'period': TargetPeriod.weekly,
        'goal': 1,
        'unit': ar ? 'مرة' : 'time',
        'linkType': 'surah:18',
      },
      {
        'title': ar ? 'قراءة سورة البقرة' : 'Read Surah Al-Baqarah',
        'period': TargetPeriod.weekly,
        'goal': 1,
        'unit': ar ? 'مرة' : 'time',
        'linkType': 'surah:2',
      },
      {
        'title': ar ? 'ختم القرآن الكريم' : 'Complete the whole Quran',
        'period': TargetPeriod.monthly,
        'goal': 1,
        'unit': ar ? 'مرة' : 'time',
        'linkType': 'surah:1',
      },
      {
        'title': ar ? 'صيام الاثنين والخميس' : 'Fast Monday & Thursday',
        'period': TargetPeriod.weekly,
        'goal': 2,
        'unit': ar ? 'يوم' : 'day',
      },
    ];
  }
}

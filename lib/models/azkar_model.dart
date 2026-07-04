class AzkarItem {
  final String zekr;
  final int repeat;
  final String bless;
  final String source;
  final String? importance;

  AzkarItem({
    required this.zekr,
    required this.repeat,
    required this.bless,
    required this.source,
    this.importance,
  });

  // For backward compatibility
  String get text => zekr;
  int get targetCount => repeat;
  String get reference => source;
}

class AzkarCategory {
  final String name;
  final String arabicName;
  final List<AzkarItem> items;

  AzkarCategory({
    required this.name,
    required this.arabicName,
    required this.items,
  });
}

import 'dart:convert';

class ReminderSettings {
  final bool enabled;
  final int intervalMinutes;
  final List<String> selectedTasbeehIds;
  final bool allowCloseAnytime;

  ReminderSettings({
    this.enabled = false,
    this.intervalMinutes = 60,
    this.selectedTasbeehIds = const [],
    this.allowCloseAnytime = false,
  });

  ReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    List<String>? selectedTasbeehIds,
    bool? allowCloseAnytime,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      selectedTasbeehIds: selectedTasbeehIds ?? this.selectedTasbeehIds,
      allowCloseAnytime: allowCloseAnytime ?? this.allowCloseAnytime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'intervalMinutes': intervalMinutes,
      'selectedTasbeehIds': selectedTasbeehIds,
      'allowCloseAnytime': allowCloseAnytime,
    };
  }

  factory ReminderSettings.fromJson(dynamic json) {
    final map =
        json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};

    final rawSelectedIds = map['selectedTasbeehIds'];
    List<String> selectedTasbeehIds = [];

    if (rawSelectedIds is List) {
      selectedTasbeehIds =
          rawSelectedIds.whereType<Object?>().map((e) => e.toString()).toList();
    } else if (rawSelectedIds is Iterable) {
      selectedTasbeehIds = rawSelectedIds.map((e) => e.toString()).toList();
    }

    return ReminderSettings(
      enabled: map['enabled'] as bool? ?? false,
      intervalMinutes: map['intervalMinutes'] as int? ?? 60,
      selectedTasbeehIds: selectedTasbeehIds,
      allowCloseAnytime: map['allowCloseAnytime'] as bool? ?? false,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory ReminderSettings.fromJsonString(String jsonString) {
    return ReminderSettings.fromJson(jsonDecode(jsonString));
  }
}

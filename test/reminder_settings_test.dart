import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/models/reminder_settings.dart';

void main() {
  test('ReminderSettings handles non-list stored values safely', () {
    final settings = ReminderSettings.fromJson({
      'enabled': false,
      'intervalMinutes': 60,
      'selectedTasbeehIds': 'not-a-list',
      'allowCloseAnytime': false,
    });

    expect(settings.selectedTasbeehIds, isEmpty);
  });
}

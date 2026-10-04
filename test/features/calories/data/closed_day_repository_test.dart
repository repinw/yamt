import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('keeps a closed day on the device until it is deleted', () async {
    final preferences = MemoryAppPreferences();
    final repository = ClosedDayRepository(preferences, 'user-1');
    expect(repository.readClosedDay(), isNull);

    await repository.saveClosedDay(DateTime(2026, 10, 5, 18, 30));
    expect(
      ClosedDayRepository(preferences, 'user-1').readClosedDay(),
      DateTime(2026, 10, 5),
    );

    await repository.deleteClosedDay();
    expect(ClosedDayRepository(preferences, 'user-1').readClosedDay(), isNull);
  });

  test('keeps the closed day of each user apart', () async {
    final preferences = MemoryAppPreferences();
    await ClosedDayRepository(
      preferences,
      'user-1',
    ).saveClosedDay(DateTime(2026, 10, 5));

    expect(ClosedDayRepository(preferences, 'user-2').readClosedDay(), isNull);
    expect(ClosedDayRepository(preferences, null).readClosedDay(), isNull);
  });

  test('does not save while signed out', () async {
    final repository = ClosedDayRepository(MemoryAppPreferences(), null);

    await expectLater(
      repository.saveClosedDay(DateTime(2026, 10, 5)),
      throwsStateError,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  test('previousDiaryVisibleDay moves one day left inside window', () {
    final resolved = previousDiaryVisibleDay(
      DateTime(2026, 3, 20),
      anchorDay: DateTime(2026, 3, 25),
    );

    expect(resolved, DateTime(2026, 3, 19));
  });

  test('previousDiaryVisibleDay clamps to earliest visible day', () {
    final resolved = previousDiaryVisibleDay(
      DateTime(2026, 3, 19),
      anchorDay: DateTime(2026, 3, 25),
    );

    expect(resolved, DateTime(2026, 3, 19));
  });

  test('nextDiaryVisibleDay moves one day right inside window', () {
    final resolved = nextDiaryVisibleDay(
      DateTime(2026, 3, 24),
      anchorDay: DateTime(2026, 3, 25),
    );

    expect(resolved, DateTime(2026, 3, 25));
  });

  test('nextDiaryVisibleDay clamps to latest visible day', () {
    final resolved = nextDiaryVisibleDay(
      DateTime(2026, 3, 25),
      anchorDay: DateTime(2026, 3, 25),
    );

    expect(resolved, DateTime(2026, 3, 25));
  });
}

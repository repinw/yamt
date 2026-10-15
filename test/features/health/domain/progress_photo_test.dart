import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

ProgressPhoto _photo(String id, DateTime day, [ProgressPhotoPose? pose]) =>
    ProgressPhoto(id: id, day: day, pose: pose ?? ProgressPhotoPose.front);

void main() {
  final since = DateTime(2026, 9);
  final today = DateTime(2026, 10, 15);

  test('picks the first, the one nearest halfway, and today', () {
    final milestones = progressPhotoMilestones(
      [
        _photo('before-goal', DateTime(2026, 8, 20)),
        _photo('first', DateTime(2026, 9, 2)),
        _photo('early', DateTime(2026, 9, 10)),
        _photo('middle', DateTime(2026, 9, 22)),
        _photo('late', DateTime(2026, 10, 8)),
        _photo('today', today),
        _photo('side', DateTime(2026, 9, 23), ProgressPhotoPose.side),
      ],
      pose: ProgressPhotoPose.front,
      since: since,
      today: today,
    );

    expect(milestones.first?.id, 'first');
    expect(milestones.middle?.id, 'middle');
    expect(milestones.today?.id, 'today');
  });

  test('never shows one photo twice', () {
    final onlyToday = progressPhotoMilestones(
      [_photo('today', today)],
      pose: ProgressPhotoPose.front,
      since: since,
      today: today,
    );
    final onlyFirst = progressPhotoMilestones(
      [_photo('first', DateTime(2026, 9, 3))],
      pose: ProgressPhotoPose.front,
      since: since,
      today: today,
    );

    expect((onlyToday.first, onlyToday.middle), (null, null));
    expect(onlyToday.today?.id, 'today');
    expect(onlyFirst.first?.id, 'first');
    expect((onlyFirst.middle, onlyFirst.today), (null, null));
  });

  test('accepts a photo weight from 30 to 300 kg', () {
    expect(isValidProgressPhotoWeightKg(29.9), isFalse);
    expect(isValidProgressPhotoWeightKg(30), isTrue);
    expect(isValidProgressPhotoWeightKg(300), isTrue);
    expect(isValidProgressPhotoWeightKg(300.1), isFalse);
  });
}

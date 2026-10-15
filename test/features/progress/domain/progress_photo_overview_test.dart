import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';

ProgressPhoto _photo(
  String id,
  DateTime day, {
  ProgressPhotoPose pose = ProgressPhotoPose.front,
  double? weightKg,
}) => ProgressPhoto(id: id, day: day, pose: pose, weightKg: weightKg);

void main() {
  final front1 = _photo('a', DateTime(2026, 8, 20));
  final front2 = _photo('b', DateTime(2026, 9, 10), weightKg: 80);
  final side2 = _photo(
    'c',
    DateTime(2026, 9, 10),
    pose: ProgressPhotoPose.side,
  );
  final front3 = _photo('d', DateTime(2026, 9, 25));
  final overview = ProgressPhotoOverview(
    photos: [front1, front2, side2, front3],
    goalStarts: [
      (number: 1, day: DateTime(2026, 9)),
      (number: 2, day: DateTime(2026, 9, 20)),
    ],
    dayWeightsKg: {DateTime(2026, 9, 10): 81.5, DateTime(2026, 9, 25): 79},
  );

  test('groups the days by goal, newest goal and day first', () {
    final groups = overview.groups;

    expect(groups.map((group) => group.goal?.number), [2, 1, null]);
    expect(groups[0].days.single.poses.values, [front3]);
    expect(groups[1].days.single.day, DateTime(2026, 9, 10));
    expect(groups[1].days.single.poses, {
      ProgressPhotoPose.front: front2,
      ProgressPhotoPose.side: side2,
    });
    expect(groups[2].days.single.poses.values, [front1]);
  });

  test('a goal starting on the photo day owns the photo', () {
    final onStart = _photo('e', DateTime(2026, 9, 20));
    final groups = ProgressPhotoOverview(
      photos: [onStart],
      goalStarts: [(number: 2, day: DateTime(2026, 9, 20))],
      dayWeightsKg: const {},
    ).groups;

    expect(groups.single.goal?.number, 2);
  });

  test('has no groups without photos', () {
    expect(
      ProgressPhotoOverview(
        photos: const [],
        goalStarts: const [],
        dayWeightsKg: const {},
      ).groups,
      isEmpty,
    );
  });

  test('ofPose keeps the photos of one pose, oldest first', () {
    expect(overview.ofPose(ProgressPhotoPose.front), [front1, front2, front3]);
    expect(overview.ofPose(ProgressPhotoPose.side), [side2]);
    expect(overview.ofPose(ProgressPhotoPose.back), isEmpty);
  });

  test('weightKg prefers the typed weight over the day trend', () {
    expect(overview.weightKg(front2), 80);
    expect(overview.weightKg(side2), 81.5);
    expect(overview.weightKg(front3), 79);
    expect(overview.weightKg(front1), isNull);
  });

  test('beforeAfter pairs the first and the newest photo of a pose', () {
    final front = overview.beforeAfter(ProgressPhotoPose.front);
    expect(front.before, front1);
    expect(front.after, front3);
    expect(front.beforeKg, isNull);
    expect(front.afterKg, 79);
    expect(front.changeKg, isNull);
    expect(front.weeks, 5);

    final side = overview.beforeAfter(ProgressPhotoPose.side);
    expect(side.before, side2);
    expect(side.after, isNull);
    expect(side.weeks, isNull);
  });

  test('beforeAfter counts whole weeks across a clock change', () {
    final pair = ProgressPhotoOverview(
      photos: [
        _photo('x', DateTime(2026, 3, 22), weightKg: 82),
        _photo('y', DateTime(2026, 3, 29), weightKg: 81.5),
      ],
      goalStarts: const [],
      dayWeightsKg: const {},
    ).beforeAfter(ProgressPhotoPose.front);

    expect(pair.weeks, 1);
    expect(pair.changeKg, -0.5);
  });
}

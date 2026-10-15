import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/presentation/progress_photo_compare_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';

import '../../../helpers/fake_progress_photo_repository.dart';
import '../../../helpers/progress_photo_harness.dart';

Future<void> _pump(WidgetTester tester, {String? pose, String? scope}) {
  return pumpProgressPhotoHarness(
    tester,
    home: ProgressPhotoComparePage(poseName: pose, scopeName: scope),
    photos: FakeProgressPhotoRepository(photos: progressPhotoExamples()),
  );
}

List<String> _frameIds(WidgetTester tester) => [
  for (final frame in tester.widgetList<ProgressPhotoFrame>(
    find.byType(ProgressPhotoFrame),
  ))
    frame.photoId,
];

ChoiceChip _chip(WidgetTester tester, ProgressPhotoPose pose) =>
    tester.widget<ChoiceChip>(find.byKey(ProgressPhotoPoseChips.poseKey(pose)));

void main() {
  testWidgets('compares the first and the newest photo of the pose', (
    tester,
  ) async {
    await _pump(tester, pose: 'front');

    // The after photo is the bottom layer, the before photo sits on top.
    expect(_frameIds(tester), ['new', 'old']);
    expect(_chip(tester, ProgressPhotoPose.front).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the goal scope starts at the goal start', (tester) async {
    await _pump(tester, pose: 'front', scope: 'goal');

    expect(_frameIds(tester), ['new', 'mid']);
  });

  testWidgets('opens with the pose of the query', (tester) async {
    await _pump(tester, pose: 'side');

    expect(_chip(tester, ProgressPhotoPose.side).selected, isTrue);
    expect(_frameIds(tester), ['side', 'side']);
  });

  testWidgets('an unknown pose falls back to front', (tester) async {
    await _pump(tester, pose: 'sideways');

    expect(_chip(tester, ProgressPhotoPose.front).selected, isTrue);
  });

  testWidgets('a pose without photos shows a note', (tester) async {
    await _pump(tester, pose: 'back');

    expect(find.byType(ProgressPhotoFrame), findsNothing);
    expect(find.byKey(ProgressPhotoComparePage.sliderKey), findsNothing);
  });

  testWidgets('the picker changes the before side', (tester) async {
    await _pump(tester, pose: 'front');

    await tester.tap(find.byType(DropdownButton<ProgressPhoto>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('10. Sept. 2026').last);
    await tester.pumpAndSettle();

    expect(_frameIds(tester), ['new', 'mid']);
  });

  testWidgets('the slider moves the border', (tester) async {
    await _pump(tester, pose: 'front');
    final slider = find.byKey(ProgressPhotoComparePage.sliderKey);

    expect(tester.widget<Slider>(slider).value, 0.5);
    await tester.drag(slider, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(tester.widget<Slider>(slider).value, greaterThan(0.5));
  });
}

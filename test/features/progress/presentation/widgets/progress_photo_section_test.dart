import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_section.dart';

import '../../../../helpers/fake_progress_photo_repository.dart';
import '../../../../helpers/progress_photo_harness.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeProgressPhotoRepository photos,
  ProgressScope scope = ProgressScope.all,
}) async {
  await pumpProgressPhotoHarness(
    tester,
    home: ProgressPhotoSection(scope: scope),
    photos: photos,
    stubRoutes: [
      AppRoutes.homeProgressPhotos,
      AppRoutes.homeProgressPhotoCompare,
    ],
  );
}

void main() {
  testWidgets('shows the empty state with a button to add a photo', (
    tester,
  ) async {
    await _pump(tester, photos: FakeProgressPhotoRepository());

    expect(find.byKey(ProgressPhotoSection.addKey), findsOneWidget);
    expect(find.byKey(ProgressPhotoSection.allKey), findsNothing);
    expect(find.byKey(ProgressPhotoSection.compareKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the empty goal scope still links to all photos', (tester) async {
    await _pump(
      tester,
      scope: ProgressScope.goal,
      photos: FakeProgressPhotoRepository(),
    );

    expect(find.byKey(ProgressPhotoSection.addKey), findsOneWidget);
    expect(find.byKey(ProgressPhotoSection.allKey), findsOneWidget);
    expect(find.byKey(ProgressPhotoSection.compareKey), findsNothing);
  });

  testWidgets('shows the first photo as before and the newest as after', (
    tester,
  ) async {
    await _pump(
      tester,
      photos: FakeProgressPhotoRepository(photos: progressPhotoExamples()),
    );

    expect(find.byKey(ProgressPhotoSection.addKey), findsNothing);
    expect(find.textContaining('86,0 kg'), findsOneWidget);
    expect(find.textContaining('82,0 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the goal scope starts at the goal start', (tester) async {
    await _pump(
      tester,
      scope: ProgressScope.goal,
      photos: FakeProgressPhotoRepository(photos: progressPhotoExamples()),
    );

    expect(find.textContaining('10. Sept. 2026 ·'), findsOneWidget);
    expect(find.textContaining('86,0 kg'), findsNothing);
  });

  testWidgets('a pose with one photo leaves the after frame empty', (
    tester,
  ) async {
    await _pump(
      tester,
      photos: FakeProgressPhotoRepository(photos: progressPhotoExamples()),
    );

    await tester.tap(
      find.byKey(ProgressPhotoPoseChips.poseKey(ProgressPhotoPose.side)),
    );
    await tester.pumpAndSettle();

    expect(find.text('–'), findsWidgets);
    expect(find.textContaining('20. Sept. 2026'), findsOneWidget);
  });

  testWidgets('the buttons open all photos and the comparison of the pose', (
    tester,
  ) async {
    final router = await pumpProgressPhotoHarness(
      tester,
      home: const ProgressPhotoSection(scope: ProgressScope.all),
      photos: FakeProgressPhotoRepository(photos: progressPhotoExamples()),
      stubRoutes: [
        AppRoutes.homeProgressPhotos,
        AppRoutes.homeProgressPhotoCompare,
      ],
    );

    await tester.tap(find.byKey(ProgressPhotoSection.allKey));
    await tester.pumpAndSettle();
    expect(find.text(AppRoutes.homeProgressPhotos), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ProgressPhotoPoseChips.poseKey(ProgressPhotoPose.side)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressPhotoSection.compareKey));
    await tester.pumpAndSettle();
    expect(
      find.text(
        AppRoutes.homeProgressPhotoComparePath(pose: 'side', scope: 'all'),
      ),
      findsOneWidget,
    );
  });
}

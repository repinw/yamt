import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/presentation/progress_photo_edit_flow.dart';
import 'package:yamt/features/progress/presentation/progress_photo_viewer_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_move_sheet.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_pose_chips.dart';

import '../../../helpers/fake_progress_photo_repository.dart';
import '../../../helpers/progress_photo_harness.dart';

const _openKey = ValueKey<String>('open-viewer');

/// The viewer sits on top of a home page, so it can pop.
Future<FakeProgressPhotoRepository> _pump(
  WidgetTester tester,
  String photoId,
) async {
  final photos = FakeProgressPhotoRepository(photos: progressPhotoExamples());
  await pumpProgressPhotoHarness(
    tester,
    photos: photos,
    routes: [
      GoRoute(
        path: '/viewer/:id',
        builder: (context, state) =>
            ProgressPhotoViewerPage(photoId: state.pathParameters['id']!),
      ),
    ],
    home: Builder(
      builder: (context) => TextButton(
        key: _openKey,
        onPressed: () => unawaited(context.push('/viewer/$photoId')),
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  return photos;
}

Future<void> _moveTo(WidgetTester tester, ProgressPhotoPose pose) async {
  await tester.tap(find.byKey(ProgressPhotoViewerPage.moveKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProgressPhotoPoseChips.poseKey(pose)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProgressPhotoMoveSheet.moveKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the photo', (tester) async {
    await _pump(tester, 'mid');

    expect(find.byType(ProgressPhotoFrame), findsOneWidget);
    expect(find.byKey(ProgressPhotoViewerPage.deleteKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves the photo to another pose', (tester) async {
    final photos = await _pump(tester, 'mid');

    await _moveTo(tester, ProgressPhotoPose.back);

    final mid = photos.photos.singleWhere((photo) => photo.id == 'mid');
    expect(mid.pose, ProgressPhotoPose.back);
    expect(photos.photos, hasLength(4));
    expect(find.byKey(ProgressPhotoViewerPage.moveKey), findsOneWidget);
  });

  testWidgets('the move button waits for a change', (tester) async {
    await _pump(tester, 'mid');

    await tester.tap(find.byKey(ProgressPhotoViewerPage.moveKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.byKey(ProgressPhotoMoveSheet.moveKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a move onto a taken slot asks and replaces on confirm', (
    tester,
  ) async {
    final photos = await _pump(tester, 'new');

    await _moveTo(tester, ProgressPhotoPose.side);
    expect(find.byKey(progressPhotoConfirmKey), findsOneWidget);
    await tester.tap(find.byKey(progressPhotoConfirmKey));
    await tester.pumpAndSettle();

    expect(photos.photos.map((photo) => photo.id), ['old', 'mid', 'new']);
    expect(
      photos.photos.singleWhere((photo) => photo.id == 'new').pose,
      ProgressPhotoPose.side,
    );
  });

  testWidgets('cancelling the replace dialog keeps both photos', (
    tester,
  ) async {
    final photos = await _pump(tester, 'new');

    await _moveTo(tester, ProgressPhotoPose.side);
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(photos.photos, hasLength(4));
    expect(
      photos.photos.singleWhere((photo) => photo.id == 'new').pose,
      ProgressPhotoPose.front,
    );
  });

  testWidgets('a failed move shows a snack bar', (tester) async {
    final photos = await _pump(tester, 'mid');
    photos.moveError = Exception('offline');

    await _moveTo(tester, ProgressPhotoPose.back);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      photos.photos.singleWhere((photo) => photo.id == 'mid').pose,
      ProgressPhotoPose.front,
    );
  });

  testWidgets('delete confirms and closes the viewer', (tester) async {
    final photos = await _pump(tester, 'mid');

    await tester.tap(find.byKey(ProgressPhotoViewerPage.deleteKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(progressPhotoConfirmKey));
    await tester.pumpAndSettle();

    expect(photos.photos.map((photo) => photo.id), ['old', 'new', 'side']);
    expect(find.byType(ProgressPhotoViewerPage), findsNothing);
    expect(find.byKey(_openKey), findsOneWidget);
  });

  testWidgets('a failed delete keeps the viewer open', (tester) async {
    final photos = await _pump(tester, 'mid');
    photos.deleteError = Exception('offline');

    await tester.tap(find.byKey(ProgressPhotoViewerPage.deleteKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(progressPhotoConfirmKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProgressPhotoViewerPage), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('an unknown photo shows the missing note', (tester) async {
    await _pump(tester, 'gone');

    expect(find.byType(ProgressPhotoFrame), findsNothing);
    expect(find.byKey(ProgressPhotoViewerPage.deleteKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replace opens the capture sheet locked to the photo', (
    tester,
  ) async {
    await _pump(tester, 'side');

    await tester.tap(find.byKey(ProgressPhotoViewerPage.replaceKey));
    await tester.pumpAndSettle();

    final sheet = tester.widget<ProgressPhotoCaptureSheet>(
      find.byType(ProgressPhotoCaptureSheet),
    );
    expect(sheet.replacing?.id, 'side');
    final dayButton = tester.widget<ButtonStyleButton>(
      find.byKey(ProgressPhotoCaptureSheet.dayKey),
    );
    expect(dayButton.onPressed, isNull);
    final frontChip = tester.widget<ChoiceChip>(
      find.byKey(ProgressPhotoCaptureSheet.poseKey(ProgressPhotoPose.front)),
    );
    expect(frontChip.onSelected, isNull);
  });
}

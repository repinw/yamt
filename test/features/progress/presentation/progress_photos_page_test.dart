import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/progress/presentation/progress_photo_edit_flow.dart';
import 'package:yamt/features/progress/presentation/progress_photos_page.dart';

import '../../../helpers/fake_progress_photo_repository.dart';
import '../../../helpers/progress_photo_harness.dart';

Future<FakeProgressPhotoRepository> _pump(WidgetTester tester) async {
  final photos = FakeProgressPhotoRepository(photos: progressPhotoExamples());
  await pumpProgressPhotoHarness(
    tester,
    home: const ProgressPhotosPage(),
    photos: photos,
    stubRoutes: [AppRoutes.homeProgressPhotoViewer],
  );
  return photos;
}

Future<void> _deleteMid(WidgetTester tester) async {
  await tester.longPress(find.byKey(ProgressPhotosPage.photoKey('mid')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(progressPhotoConfirmKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a thumbnail per photo, grouped by goal', (tester) async {
    await _pump(tester);

    for (final id in ['old', 'mid', 'new', 'side']) {
      expect(find.byKey(ProgressPhotosPage.photoKey(id)), findsOneWidget);
    }
    expect(find.text('VOR DEM ERSTEN ZIEL'), findsOneWidget);
    // The goal group comes first, the days before the goals last.
    expect(
      tester.getTopLeft(find.byKey(ProgressPhotosPage.photoKey('new'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(ProgressPhotosPage.photoKey('old'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap opens the viewer of the photo', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(ProgressPhotosPage.photoKey('mid')));
    await tester.pumpAndSettle();

    expect(
      find.text(AppRoutes.homeProgressPhotoViewerPath('mid')),
      findsOneWidget,
    );
  });

  testWidgets('a long press and a confirm delete the photo', (tester) async {
    final photos = await _pump(tester);

    await _deleteMid(tester);

    expect(photos.photos.map((photo) => photo.id), ['old', 'new', 'side']);
    expect(find.byKey(ProgressPhotosPage.photoKey('mid')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cancelling the dialog keeps the photo', (tester) async {
    final photos = await _pump(tester);

    await tester.longPress(find.byKey(ProgressPhotosPage.photoKey('mid')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(photos.photos, hasLength(4));
    expect(find.byKey(progressPhotoConfirmKey), findsNothing);
  });

  testWidgets('a failed delete keeps the photo and shows a snackbar', (
    tester,
  ) async {
    final photos = await _pump(tester);
    photos.deleteError = Exception('offline');

    await _deleteMid(tester);

    expect(photos.photos, hasLength(4));
    expect(find.byKey(ProgressPhotosPage.photoKey('mid')), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('shows a note without photos', (tester) async {
    await pumpProgressPhotoHarness(
      tester,
      home: const ProgressPhotosPage(),
      photos: FakeProgressPhotoRepository(),
    );

    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

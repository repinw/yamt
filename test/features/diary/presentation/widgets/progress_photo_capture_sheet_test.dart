import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_progress_photo_repository.dart';

final _today = DateTime(2026, 10, 15);

Future<Object? Function()> _pumpSheet(
  WidgetTester tester,
  FakeProgressPhotoRepository repository,
) async {
  Object? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ProgressPhotoCaptureSheet(today: _today),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  return () => result;
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late FakeProgressPhotoRepository repository;

  setUp(() {
    repository = FakeProgressPhotoRepository(
      pickedImage: Uint8List.fromList(<int>[1, 2, 3]),
    );
    addTearDown(repository.dispose);
  });

  testWidgets('the camera saves the photo with the pose and closes', (
    tester,
  ) async {
    final result = await _pumpSheet(tester, repository);
    await _open(tester);

    await tester.tap(
      find.byKey(ProgressPhotoCaptureSheet.poseKey(ProgressPhotoPose.back)),
    );
    await tester.enterText(
      find.byKey(ProgressPhotoCaptureSheet.weightKey),
      '78,9',
    );
    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.cameraKey));
    await tester.pumpAndSettle();

    expect(repository.pickedSources, [ImageSource.camera]);
    final photo = repository.photos.single;
    expect(photo.pose, ProgressPhotoPose.back);
    expect(photo.day, _today);
    expect(photo.weightKg, 78.9);
    expect(find.byType(ProgressPhotoCaptureSheet), findsNothing);
    expect(result(), isTrue);
  });

  testWidgets('a weight that is no number stops the save', (tester) async {
    await _pumpSheet(tester, repository);
    await _open(tester);

    await tester.enterText(
      find.byKey(ProgressPhotoCaptureSheet.weightKey),
      'abc',
    );
    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.galleryKey));
    await tester.pumpAndSettle();

    expect(repository.pickedSources, isEmpty);
    expect(find.text('Enter a weight between 30 and 300 kg.'), findsOneWidget);
  });

  testWidgets('a weight above 300 kg stops the save', (tester) async {
    await _pumpSheet(tester, repository);
    await _open(tester);

    await tester.enterText(
      find.byKey(ProgressPhotoCaptureSheet.weightKey),
      '789',
    );
    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.galleryKey));
    await tester.pumpAndSettle();

    expect(repository.pickedSources, isEmpty);
  });

  testWidgets('says that a photo of the same day and pose is replaced', (
    tester,
  ) async {
    final stored = FakeProgressPhotoRepository(
      photos: [
        ProgressPhoto(id: 'p1', day: _today, pose: ProgressPhotoPose.front),
      ],
    );
    addTearDown(stored.dispose);
    await _pumpSheet(tester, stored);
    await _open(tester);

    expect(find.textContaining('A new one replaces it.'), findsOneWidget);

    await tester.tap(
      find.byKey(ProgressPhotoCaptureSheet.poseKey(ProgressPhotoPose.side)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('A new one replaces it.'), findsNothing);
  });

  testWidgets('a failed save keeps the sheet open with a message', (
    tester,
  ) async {
    repository.saveError = Exception('offline');
    await _pumpSheet(tester, repository);
    await _open(tester);

    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.cameraKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProgressPhotoCaptureSheet), findsOneWidget);
    expect(find.text('Could not save the photo.'), findsOneWidget);
  });
}

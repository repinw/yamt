import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/diary/presentation/controllers/progress_photo_capture_controller.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

import '../../../../helpers/fake_progress_photo_repository.dart';

void main() {
  late FakeProgressPhotoRepository repository;
  late ProviderContainer container;
  final states = <AsyncValue<void>>[];

  setUp(() {
    repository = FakeProgressPhotoRepository(
      pickedImage: Uint8List.fromList(<int>[1, 2, 3]),
    );
    container = ProviderContainer(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    states.clear();
    container.listen(
      progressPhotoCaptureControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  Future<bool> capture() {
    return container
        .read(progressPhotoCaptureControllerProvider.notifier)
        .capture(
          source: ImageSource.camera,
          day: DateTime(2025, 3, 2),
          pose: ProgressPhotoPose.side,
          weightKg: 91.5,
        );
  }

  test('saves the picked image with the day, pose, and weight', () async {
    expect(await capture(), isTrue);

    expect(repository.pickedSources, [ImageSource.camera]);
    expect(repository.photos.single.day, DateTime(2025, 3, 2));
    expect(repository.photos.single.pose, ProgressPhotoPose.side);
    expect(repository.photos.single.weightKg, 91.5);
    expect(states.map((state) => state.isLoading), [false, true, false]);
    expect(states.last.hasError, isFalse);
  });

  test('a cancelled pick saves nothing and reports no error', () async {
    repository.pickedImage = null;

    expect(await capture(), isFalse);

    expect(repository.photos, isEmpty);
    expect(states.last.hasError, isFalse);
  });

  test('a failed save shows as an error', () async {
    repository.saveError = Exception('offline');

    expect(await capture(), isFalse);

    expect(states.last.hasError, isTrue);
  });
}

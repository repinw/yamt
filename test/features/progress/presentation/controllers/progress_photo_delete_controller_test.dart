import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_photo_delete_controller.dart';

import '../../../../helpers/fake_progress_photo_repository.dart';

void main() {
  late FakeProgressPhotoRepository repository;
  late ProviderContainer container;
  final states = <AsyncValue<void>>[];

  setUp(() {
    repository = FakeProgressPhotoRepository(
      photos: [
        ProgressPhoto(
          id: 'p1',
          day: DateTime(2026, 9),
          pose: ProgressPhotoPose.front,
        ),
      ],
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
      progressPhotoDeleteControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  test('deletes the photo', () async {
    final deleted = await container
        .read(progressPhotoDeleteControllerProvider.notifier)
        .delete('p1');

    expect(deleted, isTrue);
    expect(repository.photos, isEmpty);
    expect(states.map((state) => state.isLoading), [false, true, false]);
    expect(states.last.hasError, isFalse);
  });

  test('reports a failed delete and keeps the photo', () async {
    repository.deleteError = Exception('offline');

    final deleted = await container
        .read(progressPhotoDeleteControllerProvider.notifier)
        .delete('p1');

    expect(deleted, isFalse);
    expect(repository.photos, hasLength(1));
    expect(states.last.hasError, isTrue);
  });
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

part 'progress_photo_edit_controller.g.dart';

/// Deletes progress photos and moves them to another day or pose.
@riverpod
class ProgressPhotoEditController extends _$ProgressPhotoEditController {
  @override
  FutureOr<void> build() {}

  /// Deletes the photo [photoId]. Returns `false` when it failed; the state
  /// then holds the error.
  Future<bool> delete(String photoId) {
    return _run(
      () => ref.read(progressPhotoRepositoryProvider).deletePhoto(photoId),
    );
  }

  /// Moves the photo [photoId] to [day] and [pose]. Returns `false` when it
  /// failed; the state then holds the error.
  Future<bool> move(
    String photoId, {
    required DateTime day,
    required ProgressPhotoPose pose,
  }) {
    return _run(
      () => ref
          .read(progressPhotoRepositoryProvider)
          .movePhoto(photoId, day: day, pose: pose),
    );
  }

  Future<bool> _run(Future<void> Function() edit) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(edit);
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}

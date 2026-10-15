import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';

part 'progress_photo_delete_controller.g.dart';

/// Deletes progress photos.
@riverpod
class ProgressPhotoDeleteController extends _$ProgressPhotoDeleteController {
  @override
  FutureOr<void> build() {}

  /// Deletes the photo [photoId]. Returns `false` when it failed; the state
  /// then holds the error.
  Future<bool> delete(String photoId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(progressPhotoRepositoryProvider).deletePhoto(photoId),
    );
    if (!ref.mounted) {
      return !result.hasError;
    }
    state = result;
    return !result.hasError;
  }
}

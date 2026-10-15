import 'dart:developer' show log;

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

part 'progress_photo_capture_controller.g.dart';

/// Takes or picks a progress photo and saves it.
@riverpod
class ProgressPhotoCaptureController extends _$ProgressPhotoCaptureController {
  @override
  FutureOr<void> build() {}

  /// Lets the user take a photo or pick one from [source] and saves it as
  /// the [pose] photo of [day], with the typed [weightKg].
  ///
  /// Returns `true` once saved. Returns `false` when the user cancels or the
  /// save fails; the state then holds the error.
  Future<bool> capture({
    required ImageSource source,
    required DateTime day,
    required ProgressPhotoPose pose,
    double? weightKg,
  }) async {
    // The upload finishes even when the sheet closes meanwhile.
    final link = ref.keepAlive();
    try {
      state = const AsyncLoading();
      var saved = false;
      final result = await AsyncValue.guard(() async {
        final repository = ref.read(progressPhotoRepositoryProvider);
        final image = await repository.pickPhoto(source);
        if (image == null) {
          return;
        }
        await repository.savePhoto(
          day: day,
          pose: pose,
          imageBytes: image,
          weightKg: weightKg,
        );
        saved = true;
      });
      if (result case AsyncError(:final error, :final stackTrace)) {
        log(
          'Saving a progress photo failed.',
          name: 'ProgressPhotoCaptureController',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (!ref.mounted) {
        return saved;
      }
      state = result;
      return saved;
    } finally {
      link.close();
    }
  }
}

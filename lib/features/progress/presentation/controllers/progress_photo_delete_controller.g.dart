// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_delete_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deletes progress photos.

@ProviderFor(ProgressPhotoDeleteController)
final progressPhotoDeleteControllerProvider =
    ProgressPhotoDeleteControllerProvider._();

/// Deletes progress photos.
final class ProgressPhotoDeleteControllerProvider
    extends $AsyncNotifierProvider<ProgressPhotoDeleteController, void> {
  /// Deletes progress photos.
  ProgressPhotoDeleteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotoDeleteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoDeleteControllerHash();

  @$internal
  @override
  ProgressPhotoDeleteController create() => ProgressPhotoDeleteController();
}

String _$progressPhotoDeleteControllerHash() =>
    r'43a2ecdc38c0eae9dc63dea7eadda92f0f2ccca6';

/// Deletes progress photos.

abstract class _$ProgressPhotoDeleteController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

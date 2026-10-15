// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deletes progress photos and moves them to another day or pose.

@ProviderFor(ProgressPhotoEditController)
final progressPhotoEditControllerProvider =
    ProgressPhotoEditControllerProvider._();

/// Deletes progress photos and moves them to another day or pose.
final class ProgressPhotoEditControllerProvider
    extends $AsyncNotifierProvider<ProgressPhotoEditController, void> {
  /// Deletes progress photos and moves them to another day or pose.
  ProgressPhotoEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotoEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoEditControllerHash();

  @$internal
  @override
  ProgressPhotoEditController create() => ProgressPhotoEditController();
}

String _$progressPhotoEditControllerHash() =>
    r'707b1219fde776da3283cc97975ffbad4835ed68';

/// Deletes progress photos and moves them to another day or pose.

abstract class _$ProgressPhotoEditController extends $AsyncNotifier<void> {
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

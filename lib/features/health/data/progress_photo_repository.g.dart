// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Progress photo repository of the signed-in user.

@ProviderFor(progressPhotoRepository)
final progressPhotoRepositoryProvider = ProgressPhotoRepositoryProvider._();

/// Progress photo repository of the signed-in user.

final class ProgressPhotoRepositoryProvider
    extends
        $FunctionalProvider<
          ProgressPhotoRepository,
          ProgressPhotoRepository,
          ProgressPhotoRepository
        >
    with $Provider<ProgressPhotoRepository> {
  /// Progress photo repository of the signed-in user.
  ProgressPhotoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressPhotoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressPhotoRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgressPhotoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgressPhotoRepository create(Ref ref) {
    return progressPhotoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressPhotoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressPhotoRepository>(value),
    );
  }
}

String _$progressPhotoRepositoryHash() =>
    r'8cff8493cf1f690e6394fc3caf9e3e61203e73c8';
